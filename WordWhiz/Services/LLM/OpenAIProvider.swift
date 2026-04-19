import Foundation

/// OpenAI-compatible chat completions provider with SSE streaming.
/// Also used as the base for DeepSeek, Qwen, and custom OpenAI-compatible providers.
class OpenAIProvider: LLMProviderProtocol, @unchecked Sendable {
    let apiKey: String
    let baseURL: URL
    let modelName: String

    /// Public failable init for user-provided URLs that may be invalid
    init?(apiKey: String, baseURL: String, modelName: String) {
        self.apiKey = apiKey
        guard let url = URL(string: baseURL), !baseURL.isEmpty else { return nil }
        self.baseURL = url
        self.modelName = modelName
    }

    /// Internal non-failable init for subclasses with known-good URLs
    init(apiKey: String, baseURLURL: URL, modelName: String) {
        self.apiKey = apiKey
        self.baseURL = baseURLURL
        self.modelName = modelName
    }

    func streamOptimize(
        systemPrompt: String,
        userPrompt: String
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.timeoutInterval = Constants.requestTimeout

                    let body: [String: Any] = [
                        "model": modelName,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userPrompt]
                        ],
                        "stream": true,
                        "temperature": 0.7,
                        "max_tokens": 2000
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: LLMError.invalidResponse)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        // Try to read error body
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        continuation.finish(throwing: LLMError.httpError(httpResponse.statusCode, errorBody))
                        return
                    }

                    for try await line in bytes.lines {
                        // Check for cancellation
                        guard !Task.isCancelled else {
                            break
                        }

                        if SSEParser.isStreamEnd(line) {
                            break
                        }

                        guard let dataString = SSEParser.parseDataLine(line) else {
                            continue
                        }

                        // Parse JSON to extract content delta
                        if let data = dataString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let delta = firstChoice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            continuation.yield(content)
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func testConnection() async throws -> Bool {
        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": modelName,
            "messages": [["role": "user", "content": "Hi"]],
            "max_tokens": 5
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        return (200...299).contains(httpResponse.statusCode)
    }
}

enum LLMError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case invalidProvider
    case apiKeyMissing
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let body):
            return "HTTP Error \(code): \(body.prefix(200))"
        case .invalidProvider:
            return "Invalid LLM provider configuration"
        case .apiKeyMissing:
            return "API Key is not configured"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}
