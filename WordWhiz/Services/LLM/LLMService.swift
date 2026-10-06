import Foundation

/// LLM Service facade that manages provider creation and streaming optimization.
@MainActor
final class LLMService {
    static let shared = LLMService()

    private init() {}

    func createProvider(config: LLMProviderConfig, apiKey: String, baseURL: String?, modelName: String?) throws -> LLMProviderProtocol {
        guard !apiKey.isEmpty else { throw LLMError.apiKeyMissing }

        let resolvedModel = (modelName?.isEmpty == false) ? modelName! : config.defaultModel
        let resolvedURL   = (baseURL?.isEmpty == false) ? baseURL! : config.defaultBaseURL

        // Exhaustive switch: adding a new provider case forces a compile error here.
        switch config {
        case .anthropic:
            return AnthropicProvider(
                apiKey: apiKey,
                modelName: resolvedModel
            )
        case .openAI, .deepSeek, .qwen, .gemini, .kimi, .glm, .minimax, .custom:
            // All OpenAI-compatible providers share OpenAIProvider; base URL and
            // default model come from LLMProviderConfig.
            guard !resolvedURL.isEmpty,
                  let provider = OpenAIProvider(
                      apiKey: apiKey,
                      baseURL: resolvedURL,
                      modelName: resolvedModel.isEmpty ? "default" : resolvedModel
                  )
            else {
                throw LLMError.invalidBaseURL(resolvedURL)
            }
            return provider
        }
    }

    func stream(
        provider: LLMProviderProtocol,
        systemPrompt: String,
        userPrompt: String
    ) -> AsyncThrowingStream<String, Error> {
        return provider.streamOptimize(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }
}
