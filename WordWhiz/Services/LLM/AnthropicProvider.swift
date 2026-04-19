import Foundation

/// Anthropic Messages API provider with SSE streaming.
/// Uses a different request/response format than OpenAI.
final class AnthropicProvider: LLMProviderProtocol, @unchecked Sendable {
    let apiKey: String
    let modelName: String
    let baseURL: URL

    init(apiKey: String, modelName: String = "claude-sonnet-4-20250514") {
        self.apiKey = apiKey
        self.modelName = modelName
        self.baseURL = URL(string: "https://api.anthropic.com")!
    }

    func streamOptimize(
        systemPrompt: String,
        userPrompt: String
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: baseURL.appendingPathComponent("v1/messages"))
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.timeoutInterval = Constants.requestTimeout

                    let body: [String: Any] = [
                        "model": modelName,
                        "max_tokens": 2000,
                        "system": systemPrompt,
                        "messages": [
                            ["role": "user", "content": userPrompt]
                        ],
                        "stream": true
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: LLMError.invalidResponse)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        continuation.finish(throwing: LLMError.httpError(httpResponse.statusCode, errorBody))
                        return
                    }

                    var currentEventType: String? = nil

                    for try await line in bytes.lines {
                        // Check for cancellation
                        guard !Task.isCancelled else {
                            break
                        }

                        let trimmed = line.trimmingCharacters(in: .whitespaces)

                        // Parse event type
                        if let eventType = SSEParser.parseEventType(trimmed) {
                            currentEventType = eventType

                            // Check for stream end
                            if eventType == "message_stop" {
                                break
                            }
                            continue
                        }

                        // Skip empty lines and comments
                        if trimmed.isEmpty || trimmed.hasPrefix(":") {
                            continue
                        }

                        // Parse data line
                        guard let dataString = SSEParser.parseDataLine(trimmed) else {
                            continue
                        }

                        // Extract content from content_block_delta events
                        if currentEventType == "content_block_delta",
                           let data = dataString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let delta = json["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
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
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/messages"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": modelName,
            "max_tokens": 5,
            "messages": [["role": "user", "content": "Hi"]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        return (200...299).contains(httpResponse.statusCode)
    }
}
