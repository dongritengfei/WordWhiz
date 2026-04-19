import Foundation

/// LLM Service facade that manages provider creation and streaming optimization.
@MainActor
final class LLMService {
    static let shared = LLMService()

    private var currentTask: Task<Void, Never>?

    private init() {}

    func createProvider(config: LLMProviderConfig, apiKey: String, baseURL: String?, modelName: String?) -> LLMProviderProtocol? {
        guard !apiKey.isEmpty else { return nil }

        switch config {
        case .openAI:
            return OpenAIProvider(
                apiKey: apiKey,
                baseURL: baseURL ?? config.defaultBaseURL,
                modelName: modelName ?? config.defaultModel
            )
        case .anthropic:
            return AnthropicProvider(
                apiKey: apiKey,
                modelName: modelName ?? config.defaultModel
            )
        case .deepSeek:
            return DeepSeekProvider(
                apiKey: apiKey,
                modelName: modelName ?? config.defaultModel
            )
        case .qwen:
            return QwenProvider(
                apiKey: apiKey,
                modelName: modelName ?? config.defaultModel
            )
        case .custom:
            guard let baseURL, !baseURL.isEmpty else { return nil }
            return OpenAIProvider(
                apiKey: apiKey,
                baseURL: baseURL,
                modelName: modelName ?? "default"
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

    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
}
