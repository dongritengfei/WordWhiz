import Foundation

enum Constants {
    // Panel dimensions
    static let panelWidth: CGFloat = 660
    static let panelHeight: CGFloat = 660
    static let panelCornerRadius: CGFloat = 12

    // Animation
    static let slideAnimationDuration: TimeInterval = 0.3
    static let slideAnimationOffset: CGFloat = 60

    // Network
    static let requestTimeout: TimeInterval = 30
    static let maxTokens = 4096

    // Streaming
    /// Flush buffered tokens to the UI every N tokens to avoid O(n²) string concatenation
    static let streamingFlushInterval = 16

    // UI
    static let headerHeight: CGFloat = 44
    static let sourceMaxLines: Int = 3
    static let sourceMaxHeight: CGFloat = 80

    // Keychain
    static let keychainServiceIdentifier = "com.wordwhiz.app"

    // UserDefaults keys
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let hotkeyEnabledKey = "hotkeyEnabled"
    static let hotkeyConfigKey = "hotkeyConfig"
    static let launchAtLoginKey = "launchAtLogin"
    static let showDockIconKey = "showDockIcon"
    static let autoCopyKey = "autoCopy"
    static let keepHistoryKey = "keepHistory"
    static let panelPositionKey = "panelPosition"
    static let llmProviderKey = "llmProvider"
    static let apiBaseURLKey = "apiBaseURL"
    static let modelNameKey = "modelName"
    static let panelFrameKey = "panelFrame"
    static let panelPinnedFrameKey = "panelPinnedFrame"

    /// Per-provider Base URL key (URL/model are stored separately for each provider)
    static func apiBaseURLKey(provider: String) -> String { "\(apiBaseURLKey).\(provider)" }
    /// Per-provider model name key
    static func modelNameKey(provider: String) -> String { "\(modelNameKey).\(provider)" }

    // Default prompt templates (single source for first-launch seeding)
    static let defaultPrompts: [(name: String, template: String, sortOrder: Int)] = [
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
}
