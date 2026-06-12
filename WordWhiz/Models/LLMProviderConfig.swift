import Foundation

enum LLMProviderConfig: String, CaseIterable, Codable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case deepSeek = "deepseek"
    case qwen = "qwen"
    case gemini = "gemini"
    case kimi = "kimi"
    case glm = "glm"
    case minimax = "minimax"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI (GPT-4o)"
        case .anthropic: return "Anthropic (Claude)"
        case .deepSeek: return "DeepSeek"
        case .qwen: return "通义千问 (Qwen)"
        case .gemini: return "Google Gemini"
        case .kimi: return "Kimi (月之暗面)"
        case .glm: return "智谱 GLM"
        case .minimax: return "MiniMax"
        case .custom: return "自定义 (OpenAI 兼容)"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .qwen: return "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .kimi: return "https://api.moonshot.cn/v1"
        case .glm: return "https://open.bigmodel.cn/api/paas/v4"
        case .minimax: return "https://api.minimax.chat/v1"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o"
        case .anthropic: return "claude-sonnet-4-20250514"
        case .deepSeek: return "deepseek-chat"
        case .qwen: return "qwen-plus"
        case .gemini: return "gemini-2.0-flash"
        case .kimi: return "moonshot-v1-8k"
        case .glm: return "glm-4-flash"
        case .minimax: return "MiniMax-Text-01"
        case .custom: return ""
        }
    }

    /// 是否使用 OpenAI 兼容协议（true = 复用 OpenAIProvider）
    var isOpenAICompatible: Bool {
        switch self {
        case .anthropic: return false
        default: return true
        }
    }
}
