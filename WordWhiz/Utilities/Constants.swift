import Foundation

enum Constants {
    // Panel dimensions
    static let panelWidth: CGFloat = 400
    static let panelHeight: CGFloat = 560
    static let panelCornerRadius: CGFloat = 12

    // Animation
    static let slideAnimationDuration: TimeInterval = 0.3
    static let slideAnimationOffset: CGFloat = 60

    // Network
    static let requestTimeout: TimeInterval = 30

    // UI
    static let headerHeight: CGFloat = 44
    static let sourceMaxLines: Int = 3
    static let sourceMaxHeight: CGFloat = 80

    // Keychain
    static let keychainServiceIdentifier = "com.wordwhiz.app"

    // UserDefaults keys
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let hotkeyEnabledKey = "hotkeyEnabled"
    static let hotkeyConfigKey = "hotkeyConfig"
    static let launchAtLoginKey = "launchAtLogin"
    static let showDockIconKey = "showDockIcon"
    static let autoCopyKey = "autoCopy"
    static let keepHistoryKey = "keepHistory"
    static let panelPositionKey = "panelPosition"
    static let llmProviderKey = "llmProvider"
    static let apiBaseURLKey = "apiBaseURL"
    static let modelNameKey = "modelName"
    static let panelFrameKey = "panelFrame"
    static let panelPinnedFrameKey = "panelPinnedFrame"
}
