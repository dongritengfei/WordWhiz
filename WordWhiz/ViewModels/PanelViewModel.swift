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

        streamingTask = Task {
            do {
                let provider = try createCurrentProvider()

                let (systemPrompt, userPrompt) = promptsForCurrentSelection(sourceText: text)

                let stream = LLMService.shared.stream(
                    provider: provider,
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt
                )

                // Accumulate tokens in a pending buffer and append to resultText
                // periodically — repeated full-string joins would be O(n²)
                var pending = ""
                var tokensSinceFlush = 0
                for try await token in stream {
                    guard !Task.isCancelled else { break }
                    pending += token
                    tokensSinceFlush += 1
                    if tokensSinceFlush >= Constants.streamingFlushInterval {
                        resultText += pending
                        pending = ""
                        tokensSinceFlush = 0
                    }
                }
                resultText += pending

                if !Task.isCancelled {
                    streamingStatus = .complete
                    // Save to history
                    saveRecord()
                    // Auto-copy if setting enabled (default matches SettingsViewModel: true)
                    if UserDefaults.standard.object(forKey: Constants.autoCopyKey) as? Bool ?? true {
                        ClipboardService.shared.write(resultText)
                    }
                }
            } catch is CancellationError {
                streamingStatus = .stopped
            } catch LLMError.apiKeyMissing {
                streamingStatus = .error("请先配置 API Key")
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
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self?.showCopiedFeedback = false
        }
    }

    func loadCustomPrompts() {
        guard let modelContext else { return }

        // Seed default prompts on first launch (count avoids fetching all rows)
        let checkDescriptor = FetchDescriptor<CustomPrompt>()
        if (try? modelContext.fetchCount(checkDescriptor)) == 0 {
            seedDefaultPrompts(into: modelContext)
        }

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

    private func seedDefaultPrompts(into modelContext: ModelContext) {
        for item in Constants.defaultPrompts {
            let prompt = CustomPrompt(
                name: item.name,
                promptTemplate: item.template,
                sortOrder: item.sortOrder
            )
            modelContext.insert(prompt)
        }

        try? modelContext.save()
    }

    // MARK: - Private

    private func saveRecord() {
        guard let modelContext else { return }
        guard !sourceText.isEmpty, !resultText.isEmpty else { return }
        // Respect the "保留优化历史" setting (default matches SettingsViewModel: true)
        guard UserDefaults.standard.object(forKey: Constants.keepHistoryKey) as? Bool ?? true else { return }

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

        // Count first — skip fetching entirely in the common (no-overflow) case
        let total = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard total > maxRecords else { return }

        // Fetch only the records older than the newest maxRecords
        var deleteDescriptor = descriptor
        deleteDescriptor.fetchOffset = maxRecords
        deleteDescriptor.fetchLimit = total - maxRecords
        guard let recordsToDelete = try? modelContext.fetch(deleteDescriptor) else { return }
        for record in recordsToDelete {
            modelContext.delete(record)
        }
    }

    private func createCurrentProvider() throws -> LLMProviderProtocol {
        let providerRawValue = UserDefaults.standard.string(forKey: Constants.llmProviderKey) ?? LLMProviderConfig.qwen.rawValue
        let config = LLMProviderConfig(rawValue: providerRawValue) ?? .qwen

        let apiKeyKey = "apikey.\(config.rawValue)"
        guard let apiKey = KeychainService.shared.loadOrNil(key: apiKeyKey), !apiKey.isEmpty else {
            throw LLMError.apiKeyMissing
        }

        let baseURL = UserDefaults.standard.string(forKey: Constants.apiBaseURLKey(provider: config.rawValue))
        let modelName = UserDefaults.standard.string(forKey: Constants.modelNameKey(provider: config.rawValue))

        return try LLMService.shared.createProvider(
            config: config,
            apiKey: apiKey,
            baseURL: baseURL,
            modelName: modelName
        )
    }

    private func promptsForCurrentSelection(sourceText: String) -> (String, String) {
        // Use the selected prompt, or fall back to the first default template
        // (single source of truth: Constants.defaultPrompts)
        let template = selectedPrompt?.promptTemplate ?? Constants.defaultPrompts[0].template
        return Self.parse(template: template, sourceText: sourceText)
    }

    private static func parse(template: String, sourceText: String) -> (String, String) {
        // Extract system prompt from the stored template
        // The format is: systemPrompt\n\n需处理的文本：userPrompt
        let components = template.components(separatedBy: "\n\n需处理的文本：")
        if components.count == 2 {
            let systemPrompt = components[0]
            let userTemplate = components[1]
            let userPrompt = userTemplate.replacingOccurrences(of: "{{text}}", with: sourceText)
            return (systemPrompt, userPrompt)
        }

        // Fallback: use entire template as user prompt
        let systemPrompt = "你是一位专业的文案助手。请按照以下指令处理文本，输出仅包含处理后的文本。"
        let userPrompt = template.replacingOccurrences(of: "{{text}}", with: sourceText)
        return (systemPrompt, userPrompt)
    }
}
