import Foundation
import AppKit

/// Result of clipboard capture attempt
struct ClipboardCaptureResult {
    let text: String?
    let logs: [String]
}

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

    /// Capture text from the target app by activating it, simulating Cmd+C, and reading clipboard.
    /// Returns detailed logs for debugging.
    func captureFromFrontmostAppDetailed(targetApp: NSRunningApplication?) -> ClipboardCaptureResult {
        var logs: [String] = []

        guard let targetApp = targetApp else {
            return ClipboardCaptureResult(text: nil, logs: ["Target app is nil"])
        }

        logs.append("Starting capture for: \(targetApp.localizedName ?? "unknown") (pid: \(targetApp.processIdentifier))")

        // Save current clipboard content
        let originalContent = pasteboard.string(forType: .string)
        let originalChangeCount = pasteboard.changeCount
        logs.append("Original clipboard: changeCount=\(originalChangeCount), content='\(originalContent?.prefix(30) ?? "nil")'")

        // NOTE: Do NOT clear clipboard - some apps may fail to copy if clipboard is empty
        logs.append("Skipping clipboard clear (keeping original content)")

        // Activate the target app so Cmd+C goes to it
        let activated = targetApp.activate(options: [.activateIgnoringOtherApps])
        logs.append("activate() returned: \(activated)")

        // Increased delay to ensure target app is fully activated
        Thread.sleep(forTimeInterval: 0.2)
        logs.append("Activation delay (200ms) completed")

        // Verify target app is actually frontmost now
        let currentFrontmost = NSWorkspace.shared.frontmostApplication
        logs.append("Current frontmost: \(currentFrontmost?.localizedName ?? "unknown")")

        // Method 1: Try CGEvent simulation with both event tap levels
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        logs.append("Posting Cmd+C via CGEvent (cgSessionEventTap + cghidEventTap)...")
        keyDown?.post(tap: .cgSessionEventTap)
        Thread.sleep(forTimeInterval: 0.02)
        keyUp?.post(tap: .cgSessionEventTap)
        Thread.sleep(forTimeInterval: 0.02)
        keyDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.02)
        keyUp?.post(tap: .cghidEventTap)

        // Poll for clipboard update
        var newContent: String? = nil
        let maxAttempts = 30
        var clipboardChanged = false

        for i in 0..<maxAttempts {
            Thread.sleep(forTimeInterval: 0.05)
            let changeCount = pasteboard.changeCount
            if changeCount != originalChangeCount {
                clipboardChanged = true
                
                // Check all available pasteboard types
                let types = pasteboard.types?.map { $0.rawValue } ?? []
                logs.append("Clipboard changed at poll #\(i+1), types: \(types.joined(separator: ", "))")
                
                // Try to get string content
                newContent = pasteboard.string(forType: .string)
                
                // If .string is nil, try other common text types
                if newContent == nil {
                    newContent = pasteboard.string(forType: .init(rawValue: "public.utf8-plain-text"))
                }
                if newContent == nil {
                    newContent = pasteboard.string(forType: .init(rawValue: "public.utf16-plain-text"))
                }
                if newContent == nil {
                    newContent = pasteboard.string(forType: .init(rawValue: "NSStringPboardType"))
                }
                
                logs.append("String content: '\(newContent?.prefix(50) ?? "nil")'")
                break
            }
        }
        
        if !clipboardChanged {
            logs.append("CGEvent failed, trying AppleScript...")
            
            // Method 2: Try AppleScript to simulate Cmd+C via System Events
            let appleScript = """
            tell application "System Events"
                keystroke "c" using command down
            end tell
            """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let output = scriptObject.executeAndReturnError(&error)
                if let error = error {
                    logs.append("AppleScript error: \(error)")
                } else {
                    logs.append("AppleScript executed successfully")
                }
            }
            
            // Poll again for clipboard update
            for i in 0..<maxAttempts {
                Thread.sleep(forTimeInterval: 0.05)
                let changeCount = pasteboard.changeCount
                if changeCount != originalChangeCount {
                    clipboardChanged = true
                    
                    let types = pasteboard.types?.map { $0.rawValue } ?? []
                    logs.append("Clipboard changed after AppleScript at poll #\(i+1), types: \(types.joined(separator: ", "))")
                    
                    newContent = pasteboard.string(forType: .string)
                    if newContent == nil {
                        newContent = pasteboard.string(forType: .init(rawValue: "public.utf8-plain-text"))
                    }
                    if newContent == nil {
                        newContent = pasteboard.string(forType: .init(rawValue: "public.utf16-plain-text"))
                    }
                    if newContent == nil {
                        newContent = pasteboard.string(forType: .init(rawValue: "NSStringPboardType"))
                    }
                    
                    logs.append("String content: '\(newContent?.prefix(50) ?? "nil")'")
                    break
                }
            }
            
            if !clipboardChanged {
                logs.append("AppleScript also failed")
            }
        }

        // Restore original clipboard content
        if let original = originalContent {
            pasteboard.clearContents()
            pasteboard.setString(original, forType: .string)
            logs.append("Original clipboard restored")
        }

        let finalText = newContent?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : newContent
        return ClipboardCaptureResult(text: finalText, logs: logs)
    }

    /// Simple version returning just text (for backward compatibility)
    func captureFromFrontmostApp(targetApp: NSRunningApplication?) -> String? {
        let result = captureFromFrontmostAppDetailed(targetApp: targetApp)
        return result.text
    }

    /// Simulate Cmd+C, read the new clipboard content, and restore the original content.
    /// This is used as a fallback when Accessibility API fails to get selected text.
    /// Runs asynchronously to avoid blocking the main thread.
    func simulateCopyAndRead() async -> String? {
        // Save current clipboard content
        let originalContent = await MainActor.run { pasteboard.string(forType: .string) }
        let originalChangeCount = await MainActor.run { pasteboard.changeCount }

        // Clear clipboard so we can detect new content
        await MainActor.run { pasteboard.clearContents() }

        // Simulate Cmd+C on main thread
        await MainActor.run {
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }

        // Poll for clipboard update (up to 500ms total)
        var newContent: String? = nil
        let maxAttempts = 10
        for _ in 0..<maxAttempts {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            let changeCount = await MainActor.run { pasteboard.changeCount }
            if changeCount != originalChangeCount {
                newContent = await MainActor.run { pasteboard.string(forType: .string) }
                break
            }
        }

        // Restore original clipboard content
        if let original = originalContent {
            await MainActor.run {
                pasteboard.clearContents()
                pasteboard.setString(original, forType: .string)
            }
        }

        return newContent
    }
}
