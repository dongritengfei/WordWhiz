import SwiftUI
import SwiftData

@Observable
@MainActor
final class CustomPromptViewModel {
    var prompts: [CustomPrompt] = []
    var isEditing: Bool = false
    var editingPrompt: CustomPrompt?

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        initializeDefaultPromptsIfNeeded()
        fetchPrompts()
    }

    /// Initialize default prompts on first launch
    private func initializeDefaultPromptsIfNeeded() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<CustomPrompt>()
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return
        }

        // Create default prompts
        let defaults: [(name: String, template: String, sortOrder: Int)] = [
            (
                "✨ 润色",
                "你是一位专业的中文文案编辑。请对用户提供的文本进行润色优化，修正语法错误、改善措辞表达、提升文字质量，但保持原文核心意思不变。输出仅包含优化后的文本，不需要解释修改原因。\n\n需处理的文本：{{text}}",
                0
            ),
            (
                "🌍 翻译",
                "你是一位专业的翻译专家。请自动检测源语言：如果原文是中文则翻译为英文，如果原文是英文则翻译为中文。输出仅包含翻译后的文本，不需要解释。\n\n需处理的文本：{{text}}",
                1
            ),
            (
                "📋 摘要",
                "你是一位内容摘要专家。请将以下长文本压缩为核心要点，保留关键信息，输出简洁精炼的摘要。输出仅包含摘要文本。\n\n需处理的文本：{{text}}",
                2
            ),
            (
                "📝 扩写",
                "你是一位文案扩写专家。请在保持原意的基础上，丰富细节、增加论据、扩展表述，使内容更加充实完整。输出仅包含扩写后的文本。\n\n需处理的文本：{{text}}",
                3
            ),
            (
                "👔 正式化",
                "你是一位商务写作专家。请将以下文本转换为正式、规范的书面语，适用于商务邮件、官方文件等场景。保持原意不变，语气正式专业。输出仅包含转换后的文本。\n\n需处理的文本：{{text}}",
                4
            ),
            (
                "💬 口语化",
                "你是一位社交媒体文案专家。请将以下文本转换为自然、亲切的口语风格，适用于社交媒体、日常沟通等场景。保持原意不变，语气轻松活泼。输出仅包含转换后的文本。\n\n需处理的文本：{{text}}",
                5
            )
        ]

        for item in defaults {
            let prompt = CustomPrompt(
                name: item.name,
                promptTemplate: item.template,
                sortOrder: item.sortOrder
            )
            modelContext.insert(prompt)
        }

        try? modelContext.save()
    }

    func fetchPrompts() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<CustomPrompt>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        do {
            prompts = try modelContext.fetch(descriptor)
        } catch {
            prompts = []
        }
    }

    func addPrompt(name: String, template: String) {
        guard let modelContext else { return }
        let prompt = CustomPrompt(
            name: name,
            promptTemplate: template,
            sortOrder: prompts.count
        )
        modelContext.insert(prompt)
        try? modelContext.save()
        fetchPrompts()
    }

    func updatePrompt(_ prompt: CustomPrompt, name: String, template: String) {
        prompt.name = name
        prompt.promptTemplate = template
        prompt.updatedAt = Date()
        try? modelContext?.save()
        fetchPrompts()
    }

    func deletePrompt(_ prompt: CustomPrompt) {
        modelContext?.delete(prompt)
        try? modelContext?.save()
        reorderPrompts()
        fetchPrompts()
    }

    /// Move a prompt to a new position (for drag-and-drop reordering)
    func movePrompt(from source: IndexSet, to destination: Int) {
        var sortedPrompts = prompts
        sortedPrompts.move(fromOffsets: source, toOffset: destination)

        for (index, prompt) in sortedPrompts.enumerated() {
            prompt.sortOrder = index
        }

        try? modelContext?.save()
        prompts = sortedPrompts
    }

    /// Reset all prompts to default (delete all and recreate defaults)
    func resetToDefaults() {
        guard let modelContext else { return }

        // Delete all existing prompts
        let descriptor = FetchDescriptor<CustomPrompt>()
        if let existing = try? modelContext.fetch(descriptor) {
            for prompt in existing {
                modelContext.delete(prompt)
            }
        }

        // Re-initialize defaults
        initializeDefaultPromptsIfNeeded()
        fetchPrompts()
    }

    private func reorderPrompts() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<CustomPrompt>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        if let allPrompts = try? modelContext.fetch(descriptor) {
            for (index, prompt) in allPrompts.enumerated() {
                prompt.sortOrder = index
            }
            try? modelContext.save()
        }
    }
}
