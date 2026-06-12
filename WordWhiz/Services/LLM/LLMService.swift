import Foundation

/// LLM Service facade that manages provider creation and streaming optimization.
@MainActor
final class LLMService {
    static let shared = LLMService()

    private init() {}

    func createProvider(config: LLMProviderConfig, apiKey: String, baseURL: String?, modelName: String?) -> LLMProviderProtocol? {
        guard !apiKey.isEmpty else { return nil }

        let resolvedModel = (modelName?.isEmpty == false) ? modelName! : config.defaultModel
        let resolvedURL   = (baseURL?.isEmpty == false) ? baseURL! : config.defaultBaseURL

        switch config {
        case .anthropic:
            return AnthropicProvider(
                apiKey: apiKey,
                modelName: resolvedModel
            )
        case .custom:
            guard !resolvedURL.isEmpty else { return nil }
            return OpenAIProvider(
                apiKey: apiKey,
                baseURL: resolvedURL,
                modelName: resolvedModel.isEmpty ? "default" : resolvedModel
            )
        case .deepSeek:
            return DeepSeekProvider(apiKey: apiKey, modelName: resolvedModel)
        case .qwen:
            return QwenProvider(apiKey: apiKey, modelName: resolvedModel)
        case .gemini:
            return GeminiProvider(apiKey: apiKey, modelName: resolvedModel)
        case .kimi:
            return KimiProvider(apiKey: apiKey, modelName: resolvedModel)
        case .glm:
            return GLMProvider(apiKey: apiKey, modelName: resolvedModel)
        case .minimax:
            return MiniMaxProvider(apiKey: apiKey, modelName: resolvedModel)
        default:
            // openAI and any future OpenAI-compatible providers
            return OpenAIProvider(
                apiKey: apiKey,
                baseURL: resolvedURL,
                modelName: resolvedModel
            )
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
