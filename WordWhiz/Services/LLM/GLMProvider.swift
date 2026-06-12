import Foundation

/// 智谱 GLM provider — OpenAI-compatible.
final class GLMProvider: OpenAIProvider {
    init(apiKey: String, modelName: String = "glm-4-flash") {
        super.init(
            apiKey: apiKey,
            baseURLURL: URL(string: "https://open.bigmodel.cn/api/paas/v4")!,
            modelName: modelName
        )
    }
}
