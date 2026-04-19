import Foundation
import AppKit

/// Service for reading from and writing to the system clipboard
final class ClipboardService: @unchecked Sendable {
    static let shared = ClipboardService()

    private let pasteboard = NSPasteboard.general

    private init() {}

    /// Read current clipboard text content
    func read() -> String? {
        return pasteboard.string(forType: .string)
    }

    /// Write text to clipboard
    @discardableResult
    func write(_ text: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
