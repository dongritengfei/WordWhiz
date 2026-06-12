import Foundation

/// Kimi (Moonshot) provider — OpenAI-compatible.
final class KimiProvider: OpenAIProvider {
    init(apiKey: String, modelName: String = "moonshot-v1-8k") {
        super.init(
            apiKey: apiKey,
            baseURLURL: URL(string: "https://api.moonshot.cn/v1")!,
            modelName: modelName
        )
    }
}
