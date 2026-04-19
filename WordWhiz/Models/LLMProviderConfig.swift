import Foundation

enum LLMProviderConfig: String, CaseIterable, Codable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case deepSeek = "deepseek"
    case qwen = "qwen"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI (GPT-4o)"
        case .anthropic: return "Anthropic (Claude)"
        case .deepSeek: return "DeepSeek"
        case .qwen: return "通义千问"
        case .custom: return "自定义 (OpenAI 兼容)"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .qwen: return "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o"
        case .anthropic: return "claude-sonnet-4-20250514"
        case .deepSeek: return "deepseek-chat"
        case .qwen: return "qwen-plus"
        case .custom: return ""
        }
    }
}
