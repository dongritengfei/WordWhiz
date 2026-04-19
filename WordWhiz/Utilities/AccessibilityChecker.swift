import Foundation
import AppKit
import ApplicationServices

enum AccessibilityChecker {
    /// Check if the app has Accessibility permission without showing a prompt
    static var isTrusted: Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = NSDictionary(object: NSNumber(value: false), forKey: key)
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Check and prompt for Accessibility permission
    @discardableResult
    static func requestPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = NSDictionary(object: NSNumber(value: true), forKey: key)
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Open System Settings to the Accessibility pane
    static func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
