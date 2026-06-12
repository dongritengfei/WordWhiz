import Foundation

/// Google Gemini provider — uses the OpenAI-compatible endpoint.
final class GeminiProvider: OpenAIProvider {
    init(apiKey: String, modelName: String = "gemini-2.0-flash") {
        super.init(
            apiKey: apiKey,
            baseURLURL: URL(string: "https://generativelanguage.googleapis.com/v1beta/openai")!,
            modelName: modelName
        )
    }
}
