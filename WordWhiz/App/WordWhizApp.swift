import SwiftUI
import SwiftData

@main
struct WordWhizApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            MenuBarView()
                .environment(appDelegate.panelViewModel)
                .environment(appDelegate.settingsViewModel)
        } label: {
            Text("Ww")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color(hex: "5B7FFF"))
                .cornerRadius(4)
        }
        .menuBarExtraStyle(.menu)

        WindowGroup("Onboarding", id: "onboarding") {
            OnboardingView()
                .environment(appDelegate.onboardingViewModel)
                .environment(appDelegate.settingsViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 420)

        WindowGroup("Settings", id: "settings") {
            SettingsWindowView()
                .environment(appDelegate.settingsViewModel)
                .modelContainer(appDelegate.modelContainer)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 640, height: 520)
    }
}
