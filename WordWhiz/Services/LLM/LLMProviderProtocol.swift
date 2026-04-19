import Foundation

protocol LLMProviderProtocol {
    func streamOptimize(
        systemPrompt: String,
        userPrompt: String
    ) -> AsyncThrowingStream<String, Error>

    func testConnection() async throws -> Bool
}
