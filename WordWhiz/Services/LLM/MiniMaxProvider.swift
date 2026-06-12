import Foundation

/// MiniMax provider — OpenAI-compatible.
final class MiniMaxProvider: OpenAIProvider {
    init(apiKey: String, modelName: String = "MiniMax-Text-01") {
        super.init(
            apiKey: apiKey,
            baseURLURL: URL(string: "https://api.minimax.chat/v1")!,
            modelName: modelName
        )
    }
}
