import Foundation

/// Generic SSE line parser that processes raw byte streams into structured events.
struct SSEParser {
    /// Parse a single SSE line and extract the data field content.
    /// Returns nil for comments, empty lines, and event-type-only lines.
    static func parseDataLine(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Skip empty lines and comments
        if trimmed.isEmpty || trimmed.hasPrefix(":") {
            return nil
        }

        // Extract data field
        if trimmed.hasPrefix("data:") {
            let dataContent = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)

            // Check for stream termination
            if dataContent == "[DONE]" {
                return nil // Signal completion handled by caller
            }

            return dataContent
        }

        return nil
    }

    /// Check if a line signals stream completion
    static func isStreamEnd(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed == "data: [DONE]" || trimmed == "data:[DONE]"
    }

    /// Parse event type from an SSE line
    static func parseEventType(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("event:") {
            return String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}
