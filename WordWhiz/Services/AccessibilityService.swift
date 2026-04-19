import Foundation
import AppKit
import ApplicationServices

/// Result of text capture attempt
struct CaptureResult {
    let text: String?
    let appName: String
    let pid: pid_t
    let focusedElementRole: String
    let selectedTextError: String
    let valueError: String
    let availableAttributes: [String]

    var debugDescription: String {
        var desc = """
        来源应用: \(appName)
        PID: \(pid)
        元素角色: \(focusedElementRole)
        选中文本错误: \(selectedTextError)
        Value错误: \(valueError)
        """
        if let text = text {
            desc += "\n获取文本: \(text.prefix(100))"
            desc += "\n文本长度: \(text.count) 字符"
        } else {
            desc += "\n获取文本: nil"
            desc += "\n文本长度: 0 字符"
        }
        desc += "\n可用属性: \(availableAttributes.joined(separator: ", "))"
        return desc
    }
}

final class AccessibilityService {

    /// Static method to capture selected text from a specific app (by PID).
    /// Returns detailed debug info.
    static func captureSelectedTextDetailed(fromPID: pid_t) -> CaptureResult {
        guard let targetApp = NSRunningApplication(processIdentifier: fromPID) else {
            return CaptureResult(
                text: nil, appName: "unknown", pid: fromPID,
                focusedElementRole: "N/A", selectedTextError: "App not found",
                valueError: "N/A", availableAttributes: []
            )
        }

        let appName = targetApp.localizedName ?? "unknown"
        NSLog("[WordWhiz] Capturing text from: \(appName) (pid=\(fromPID))")
        let axApp = AXUIElementCreateApplication(fromPID)

        // Get the focused UI element
        var focusedElement: AnyObject?
        let focusError = AXUIElementCopyAttributeValue(
            axApp,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        if focusError != .success {
            NSLog("[WordWhiz] Failed to get focused element: \(focusError)")
            return CaptureResult(
                text: nil, appName: appName, pid: fromPID,
                focusedElementRole: "N/A", selectedTextError: "focusError=\(focusError)",
                valueError: "N/A", availableAttributes: []
            )
        }

        let element = focusedElement as! AXUIElement

        // Get element role
        var roleValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        let role = roleValue as? String ?? "unknown"

        // Get available attributes
        var attributes: CFArray?
        AXUIElementCopyAttributeNames(element, &attributes)
        let availableAttrs = (attributes as? [String]) ?? []

        // Try to get selected text from the focused element
        var selectedText: AnyObject?
        let textError = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        if textError == .success, let text = selectedText as? String, !text.isEmpty {
            NSLog("[WordWhiz] Got selected text via AXSelectedTextAttribute")
            return CaptureResult(
                text: text, appName: appName, pid: fromPID,
                focusedElementRole: role, selectedTextError: "success",
                valueError: "N/A", availableAttributes: availableAttrs
            )
        }

        // Fallback: try getting the value of the focused element (entire text field)
        var value: AnyObject?
        let valueError = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &value
        )

        if valueError == .success, let text = value as? String, !text.isEmpty {
            NSLog("[WordWhiz] Got text via AXValueAttribute")
            return CaptureResult(
                text: text, appName: appName, pid: fromPID,
                focusedElementRole: role, selectedTextError: String(describing: textError),
                valueError: "success", availableAttributes: availableAttrs
            )
        }

        NSLog("[WordWhiz] Failed: selectedText error=\(textError), value error=\(valueError)")
        return CaptureResult(
            text: nil, appName: appName, pid: fromPID,
            focusedElementRole: role, selectedTextError: String(describing: textError),
            valueError: String(describing: valueError), availableAttributes: availableAttrs
        )
    }

    /// Static method to capture selected text (simple version for production).
    /// First tries Accessibility API, falls back to Cmd+C simulation if needed.
    static func captureSelectedText(fromPID: pid_t) -> String? {
        let result = captureSelectedTextDetailed(fromPID: fromPID)
        if let text = result.text {
            return text
        }

        // Accessibility API failed - fallback to Cmd+C simulation
        NSLog("[WordWhiz] Accessibility API failed, falling back to Cmd+C simulation")
        guard let targetApp = NSRunningApplication(processIdentifier: fromPID) else {
            return nil
        }
        return ClipboardService.shared.captureFromFrontmostApp(targetApp: targetApp)
    }

    /// Instance method for async capture with clipboard fallback.
    func captureSelectedText(fromPID: pid_t? = nil) async -> String? {
        if let pid = fromPID, pid > 0 {
            if let text = Self.captureSelectedText(fromPID: pid) {
                return text
            }
        }
        // Fallback: Simulate Cmd+C and read clipboard
        return await captureViaClipboard()
    }

    // MARK: - Fallback: Clipboard

    private func captureViaClipboard() async -> String? {
        return await ClipboardService.shared.simulateCopyAndRead()
    }
}
