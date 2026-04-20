import SwiftUI

struct MenuBarView: View {
    @Environment(PanelViewModel.self) var panelViewModel
    @Environment(SettingsViewModel.self) var settingsViewModel
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Group {
            WindowOpenerView()

            Button("打开优化面板") {
                AppDelegate.shared?.getPanelWindowService()?.toggleVisibility()
            }

            Button("测试面板（示例文本）") {
                AppDelegate.shared?.testPanel()
            }

            Divider()

            Text(statusText)

            Button("偏好设置...") {
                AppDelegate.shared?.openSettings()
            }

            Divider()

            // HotKey library doesn't require accessibility permission
            if settingsViewModel.hotkeyEnabled {
                Button("✓ 全局快捷键已启用") {
                    settingsViewModel.hotkeyEnabled.toggle()
                }
            } else {
                Text("⚠ 快捷键未注册")
                Button("重新注册快捷键") {
                    AppDelegate.shared?.retryHotkeyRegistration()
                }
            }

            Divider()

            Button("退出 WordWhiz") {
                NSApp.terminate(nil)
            }
        }
    }

    private var statusText: String {
        switch panelViewModel.streamingStatus {
        case .idle: return "● 服务已就绪"
        case .streaming: return "● 生成中..."
        case .error: return "● 服务异常"
        default: return "● 服务已就绪"
        }
    }
}

extension Notification.Name {
    static let openSettingsTab = Notification.Name("openSettingsTab")
    static let openOnboardingWindow = Notification.Name("openOnboardingWindow")
    static let openSettingsWindow = Notification.Name("openSettingsWindow")
}
