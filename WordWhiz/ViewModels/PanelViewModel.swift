import SwiftUI
import SwiftData

enum StreamingStatus: Equatable {
    case idle
    case streaming
    case complete
    case stopped
    case error(String)

    var isStreaming: Bool {
        if case .streaming = self { return true }
        return false
    }

    var label: String {
        switch self {
        case .idle: return ""
        case .streaming: return "● 生成中..."
        case .complete: return "✓ 生成完成"
        case .stopped: return "⏸ 已停止"
        case .error(let msg): return "⚠ \(msg)"
        }
    }

    var labelColor: Color {
        switch self {
        case .idle: return .clear
        case .streaming: return BrandColors.accent
        case .complete: return BrandColors.green
        case .stopped: return BrandColors.orange
        case .error: return BrandColors.red
        }
    }
}

@Observable
@MainActor
final class PanelViewModel {
    // Source text
    var sourceText: String = ""

    // Result text
    var resultText: String = ""

    // Selected prompt
    var selectedPrompt: CustomPrompt?

    // Available prompts (from SwiftData)
    var customPrompts: [CustomPrompt] = []

    // Streaming state
    var streamingStatus: StreamingStatus = .idle

    // UI state
    var isShowingDiff: Bool = false
    var isSourceCollapsed: Bool = false
    var isPinned: Bool = false
    var showCopiedFeedback: Bool = false
    var hotkeyDisplay: String = HotkeyConfig.defaultConfig.displayString

    // ModelContext for SwiftData (set by AppDelegate)
    var modelContext: ModelContext?

    // Hotkey observer (nonisolated to allow deinit access)
    nonisolated(unsafe) private var hotkeyObserver: NSObjectProtocol?

    // Character count
    var resultCharacterCount: Int {
        resultText.count
    }

    // History record count
    var historyRecordCount: Int {
        guard let modelContext else { return 0 }
        let descriptor = FetchDescriptor<OptimizationRecord>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // Task management
    private var streamingTask: Task<Void, Never>?

    init() {
        hotkeyDisplay = AppDelegate.shared?.getHotkeyDisplay() ?? HotkeyConfig.defaultConfig.displayString
        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .hotkeyConfigChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hotkeyDisplay = AppDelegate.shared?.getHotkeyDisplay() ?? HotkeyConfig.defaultConfig.displayString
        }
    }

    deinit {
        if let hotkeyObserver {
            NotificationCenter.default.removeObserver(hotkeyObserver)
        }
    }

    // MARK: - Actions

    func optimize() {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Cancel any existing streaming
        stopStreaming()

        // Reset state
        resultText = ""
        streamingStatus = .streaming
        isShowingDiff = false

        streamingTask = Task {
            do {
                guard let provider = createCurrentProvider() else {
                    streamingStatus = .error("请先配置 API Key")
                    return
                }

                let (systemPrompt, userPrompt) = promptsForCurrentSelection(sourceText: text)

                let stream = LLMService.shared.stream(
                    provider: provider,
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt
                )

                for try await token in stream {
                    guard !Task.isCancelled else { break }
                    resultText += token
                }

                if !Task.isCancelled {
                    streamingStatus = .complete
                    // Save to history
                    saveRecord()
                    // Auto-copy if setting enabled
                    if UserDefaults.standard.bool(forKey: Constants.autoCopyKey) {
                        ClipboardService.shared.write(resultText)
                    }
                }
            } catch is CancellationError {
                streamingStatus = .stopped
            } catch {
                streamingStatus = .error(error.localizedDescription)
            }
        }
    }

    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        if case .streaming = streamingStatus {
            streamingStatus = .stopped
        }
    }

    func regenerate() {
        optimize()
    }

    func switchToPrompt(_ prompt: CustomPrompt) {
        selectedPrompt = prompt

        // Stop current streaming if any
        if streamingStatus.isStreaming {
            stopStreaming()
        }

        if !sourceText.isEmpty {
            optimize()
        }
    }

    func copyResult() {
        guard !resultText.isEmpty else { return }

        ClipboardService.shared.write(resultText)

        showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showCopiedFeedback = false
        }
    }

    func loadCustomPrompts() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<CustomPrompt>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        do {
            customPrompts = try modelContext.fetch(descriptor)
            // Select first prompt by default if none selected
            if selectedPrompt == nil && !customPrompts.isEmpty {
                selectedPrompt = customPrompts.first
            }
        } catch {
            customPrompts = []
        }
    }

    // MARK: - Private

    private func saveRecord() {
        guard let modelContext else { return }
        guard !sourceText.isEmpty, !resultText.isEmpty else { return }

        let record = OptimizationRecord(
            sourceText: sourceText,
            resultText: resultText,
            promptName: selectedPrompt?.name,
            characterCount: resultText.count
        )
        modelContext.insert(record)

        // Clean up old records, keep only the most recent 50
        cleanupOldRecords(keeping: 50)

        try? modelContext.save()
    }

    private func cleanupOldRecords(keeping maxRecords: Int) {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<OptimizationRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let allRecords = try? modelContext.fetch(descriptor) else { return }

        // If we have more than maxRecords, delete the oldest ones
        if allRecords.count > maxRecords {
            let recordsToDelete = allRecords.suffix(from: maxRecords)
            for record in recordsToDelete {
                modelContext.delete(record)
            }
        }
    }

    private func createCurrentProvider() -> LLMProviderProtocol? {
        let providerRawValue = UserDefaults.standard.string(forKey: Constants.llmProviderKey) ?? LLMProviderConfig.qwen.rawValue
        let config = LLMProviderConfig(rawValue: providerRawValue) ?? .qwen

        let apiKeyKey = "apikey.\(config.rawValue)"
        guard let apiKey = KeychainService.shared.loadOrNil(key: apiKeyKey), !apiKey.isEmpty else {
            return nil
        }

        let baseURL = UserDefaults.standard.string(forKey: Constants.apiBaseURLKey)
        let modelName = UserDefaults.standard.string(forKey: Constants.modelNameKey)

        return LLMService.shared.createProvider(
            config: config,
            apiKey: apiKey,
            baseURL: baseURL,
            modelName: modelName
        )
    }

    private func promptsForCurrentSelection(sourceText: String) -> (String, String) {
        // If a specific prompt is selected
        if let prompt = selectedPrompt {
            // Extract system prompt from the stored template
            // The format is: systemPrompt\n\n用户输入：userPrompt
            let components = prompt.promptTemplate.components(separatedBy: "\n\n用户输入：")
            if components.count == 2 {
                let systemPrompt = components[0]
                let userTemplate = components[1]
                let userPrompt = userTemplate.replacingOccurrences(of: "{{text}}", with: sourceText)
                return (systemPrompt, userPrompt)
            }

            // Fallback: use entire template as user prompt
            let systemPrompt = "你是一位专业的文案助手。请按照以下指令处理文本，输出仅包含处理后的文本。"
            let userPrompt = prompt.promptTemplate.replacingOccurrences(of: "{{text}}", with: sourceText)
            return (systemPrompt, userPrompt)
        }

        // Fallback: use a default prompt
        return (
            "你是一位专业的文案编辑。请对用户提供的文本进行润色优化，修正语法错误、改善措辞表达、提升文字质量，但保持原文核心意思不变。输出仅包含优化后的文本，不需要解释修改原因。",
            sourceText
        )
    }
}
