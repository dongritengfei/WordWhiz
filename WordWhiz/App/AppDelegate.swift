import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    let panelViewModel = PanelViewModel()
    let settingsViewModel = SettingsViewModel()
    let onboardingViewModel = OnboardingViewModel()

    private(set) var hotkeyService: HotkeyService?
    private var panelWindowService: PanelWindowService?

    /// Whether accessibility permission has been granted (observable for menu bar UI)
    var accessibilityGranted: Bool = false

    /// Flag to indicate onboarding should be shown on startup
    var needsOnboarding: Bool = false

    let modelContainer: ModelContainer

    override init() {
        do {
            modelContainer = try ModelContainer(for: OptimizationRecord.self, CustomPrompt.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force dark appearance globally so system controls (TextField placeholders, Pickers, Toggles)
        // use dark-mode colors that are visible against our custom dark backgrounds
        NSApp.appearance = NSAppearance(named: .darkAqua)

        NSApp.setActivationPolicy(.accessory)
        NotificationService.shared.requestPermission()

        // Clear stale hotkey config from previous versions with incompatible format
        if UserDefaults.standard.data(forKey: Constants.hotkeyConfigKey) != nil {
            UserDefaults.standard.removeObject(forKey: Constants.hotkeyConfigKey)
        }


        hotkeyService = HotkeyService()
        panelWindowService = PanelWindowService(
            panelViewModel: panelViewModel,
            settingsViewModel: settingsViewModel
        )

        let modelContext = ModelContext(modelContainer)
        panelViewModel.modelContext = modelContext
        panelViewModel.loadCustomPrompts()

        // Observe hotkey trigger
        NotificationCenter.default.addObserver(
            forName: .hotkeyTriggered,
            object: nil, queue: .main
        ) { [weak self] notification in
            NSLog("[WordWhiz] .hotkeyTriggered notification received")
            let capturedText = notification.userInfo?["capturedText"] as? String
            self?.handleHotkeyPressed(frontmostAppPID: nil, capturedText: capturedText)
        }

        // When accessibility permission is granted, update state
        hotkeyService?.onPermissionChanged = { [weak self] granted in
            self?.accessibilityGranted = granted
        }

        // Register hotkey if enabled
        accessibilityGranted = HotkeyService.isAccessibilityGranted()
        if settingsViewModel.hotkeyEnabled {
            hotkeyService?.register()
        }

        // Observe hotkey enabled/disabled changes
        NotificationCenter.default.addObserver(
            forName: Notification.Name("hotkeyEnabledChanged"),
            object: nil, queue: .main
        ) { [weak self] _ in
            if self?.settingsViewModel.hotkeyEnabled == true {
                self?.hotkeyService?.register()
            } else {
                self?.hotkeyService?.unregister()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .openSettingsTab,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.openSettings()
        }

        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.hasCompletedOnboardingKey)
        if !hasCompletedOnboarding {
            needsOnboarding = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openOnboarding()
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Re-check accessibility when app becomes active (user may have just granted permission)
        let nowGranted = HotkeyService.isAccessibilityGranted()
        if nowGranted != accessibilityGranted {
            accessibilityGranted = nowGranted
            if nowGranted && settingsViewModel.hotkeyEnabled && !(hotkeyService?.isEnabled() ?? false) {
                hotkeyService?.register()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func handleHotkeyPressed(frontmostAppPID: pid_t?, capturedText: String?) {
        // 不记录实际文本内容，只记录长度，保护用户隐私
        let textLength = capturedText?.count ?? 0
        NSLog("[WordWhiz] handleHotkeyPressed called with capturedText length: \(textLength)")
        
        // Use capturedText from clipboard, or show error if empty
        guard let text = capturedText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            panelWindowService?.show(sourceText: "（剪贴板中没有文本内容，请先复制需要优化的文本）")
            return
        }
        
        panelWindowService?.show(sourceText: text)
    }

    func testPanel() {
        panelWindowService?.show(sourceText: "这是一段测试文本，用于验证 WordWhiz 的优化功能是否正常工作。")
    }

    func openOnboarding() {
        // First try to find an existing onboarding window
        if let window = NSApp.windows.first(where: { $0.title.contains("Onboarding") }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create the onboarding window directly via AppKit
        let onboardingView = OnboardingView()
            .environment(onboardingViewModel)
            .environment(settingsViewModel)
            .preferredColorScheme(.dark)

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Onboarding"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.setContentSize(NSSize(width: 520, height: 520))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openSettings() {
        let settingsWindows = NSApp.windows.filter {
            $0.title.contains("Settings") || $0.title.contains("偏好") || $0.title.contains("WordWhiz")
        }
        if let window = settingsWindows.first(where: { !$0.title.contains("Onboarding") && $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            NotificationCenter.default.post(name: .openSettingsWindow, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func getPanelWindowService() -> PanelWindowService? {
        return panelWindowService
    }

    func updateHotkey(_ config: HotkeyConfig) {
        hotkeyService?.register(with: config)
    }

    func getHotkeyDisplay() -> String {
        return hotkeyService?.currentHotkeyDisplay() ?? HotkeyConfig.defaultConfig.displayString
    }

    func debugHotkeyStatus() -> String {
        return hotkeyService?.debugStatus() ?? "hotkeyService is nil!"
    }

    /// Open System Settings Accessibility pane
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Retry hotkey registration (called from menu bar after user grants permission)
    func retryHotkeyRegistration() {
        settingsViewModel.hotkeyEnabled = true
        hotkeyService?.register()
    }
}
