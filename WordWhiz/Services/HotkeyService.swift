import AppKit
import HotKey

/// Notification posted when the hotkey is triggered
extension Notification.Name {
    static let hotkeyTriggered = Notification.Name("hotkeyTriggered")
    static let hotkeyConfigChanged = Notification.Name("hotkeyConfigChanged")
}

/// Represents a keyboard shortcut that can be stored in UserDefaults
struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt16           // Virtual key code (same as CGEvent.keyCode / NSEvent.keyCode)
    var modifierFlags: UInt       // NSEvent.ModifierFlags.rawValue
    var displayString: String     // Human-readable string like "⌃Z"

    /// The NSEvent modifier flags for this config
    var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    /// Convert to HotKey's Key enum
    var hotKeyKey: Key? {
        Key(carbonKeyCode: UInt32(keyCode))
    }

    static let defaultConfig = HotkeyConfig(
        keyCode: 6,  // kVK_ANSI_Z
        modifierFlags: NSEvent.ModifierFlags.control.rawValue,
        displayString: "⌃Z"
    )

    static let ctrlShiftZ = HotkeyConfig(
        keyCode: 6,
        modifierFlags: NSEvent.ModifierFlags([.control, .shift]).rawValue,
        displayString: "⌃⇧Z"
    )

    static let ctrlOptionZ = HotkeyConfig(
        keyCode: 6,
        modifierFlags: NSEvent.ModifierFlags([.control, .option]).rawValue,
        displayString: "⌃⌥Z"
    )

    static let ctrlSpace = HotkeyConfig(
        keyCode: 49,  // kVK_Space
        modifierFlags: NSEvent.ModifierFlags.control.rawValue,
        displayString: "⌃Space"
    )

    static let ctrlShiftSpace = HotkeyConfig(
        keyCode: 49,
        modifierFlags: NSEvent.ModifierFlags([.control, .shift]).rawValue,
        displayString: "⌃⇧Space"
    )

    static let ctrlOptionO = HotkeyConfig(
        keyCode: 31,  // kVK_ANSI_O
        modifierFlags: NSEvent.ModifierFlags([.control, .option]).rawValue,
        displayString: "⌃⌥O"
    )

    static let allPresets: [HotkeyConfig] = [.defaultConfig, .ctrlShiftZ, .ctrlOptionZ, .ctrlSpace, .ctrlShiftSpace, .ctrlOptionO]
}

final class HotkeyService {
    private var hotKey: HotKey?
    private var currentConfig: HotkeyConfig?

    /// Called when accessibility permission status changes
    var onPermissionChanged: ((Bool) -> Void)?

    func register() {
        currentConfig = loadConfig()
        NSLog("[WordWhiz] Registering HotKey: \(currentConfig?.displayString ?? "unknown")")
        attemptRegisterHotKey()
    }

    func register(with config: HotkeyConfig) {
        saveConfig(config)
        currentConfig = loadConfig()
        attemptRegisterHotKey()
        NotificationCenter.default.post(name: .hotkeyConfigChanged, object: nil)
    }

    func unregister() {
        hotKey = nil
        NSLog("[WordWhiz] HotKey unregistered")
    }

    func isEnabled() -> Bool {
        return hotKey != nil
    }

    func currentHotkeyDisplay() -> String {
        return currentConfig?.displayString ?? HotkeyConfig.defaultConfig.displayString
    }

    /// HotKey doesn't require Accessibility permission
    static func isAccessibilityGranted() -> Bool {
        return true
    }

    // MARK: - HotKey Registration

    private func attemptRegisterHotKey() {
        unregister()

        guard let config = currentConfig,
              let key = config.hotKeyKey else {
            NSLog("[WordWhiz] No hotkey config set or invalid key")
            return
        }

        NSLog("[WordWhiz] Registering HotKey: key=\(key), modifiers=\(config.modifierFlags)")

        hotKey = HotKey(key: key, modifiers: config.modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            NSLog("[WordWhiz] HotKey pressed!")

            // Simply read clipboard content
            let textToPass = ClipboardService.shared.read()

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .hotkeyTriggered,
                    object: nil,
                    userInfo: ["capturedText": textToPass as Any]
                )
            }
        }

        if hotKey != nil {
            NSLog("[WordWhiz] HotKey registered successfully")
            DispatchQueue.main.async {
                self.onPermissionChanged?(true)
            }
        } else {
            NSLog("[WordWhiz] HotKey registration failed")
        }
    }

    // MARK: - Persistence

    private func loadConfig() -> HotkeyConfig {
        guard let data = UserDefaults.standard.data(forKey: Constants.hotkeyConfigKey),
              let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) else {
            return .defaultConfig
        }
        return config
    }

    private func saveConfig(_ config: HotkeyConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Constants.hotkeyConfigKey)
        }
    }

    // MARK: - Debug

    func debugStatus() -> String {
        var lines: [String] = []
        lines.append("enabled: \(isEnabled())")
        lines.append("hotKey: \(hotKey != nil ? "registered" : "nil")")
        if let config = currentConfig {
            lines.append("config: keyCode=\(config.keyCode), mods=\(config.modifierFlags), display=\(config.displayString)")
        } else {
            lines.append("config: nil")
        }
        return lines.joined(separator: "\n")
    }
}
