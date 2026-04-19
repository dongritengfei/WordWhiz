import SwiftUI

/// Invisible helper view that bridges NotificationCenter requests to SwiftUI's openWindow action.
struct WindowOpenerView: View {
    @Environment(\.openWindow) var openWindow

    var body: some View {
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: .openOnboardingWindow)) { _ in
                openWindow(id: "onboarding")
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSettingsWindow)) { _ in
                openWindow(id: "settings")
            }
    }
}
