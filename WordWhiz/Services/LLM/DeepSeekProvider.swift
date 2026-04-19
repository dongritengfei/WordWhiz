import Foundation

/// DeepSeek provider — OpenAI-compatible with specific defaults.
final class DeepSeekProvider: OpenAIProvider {
    init(apiKey: String, modelName: String = "deepseek-chat") {
        super.init(
            apiKey: apiKey,
            baseURLURL: URL(string: "https://api.deepseek.com/v1")!,
            modelName: modelName
        )
    }
}
