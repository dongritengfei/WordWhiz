import Foundation

/// Qwen (通义千问) provider — OpenAI-compatible with specific defaults.
final class QwenProvider: OpenAIProvider {
    init(apiKey: String, modelName: String = "qwen-plus") {
        super.init(
            apiKey: apiKey,
            baseURLURL: URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1")!,
            modelName: modelName
        )
    }
}
