import SwiftUI

struct ShortcutSettingsView: View {
    @Environment(SettingsViewModel.self) var settingsViewModel

    @State private var selectedHotkeyIndex: Int = 0

    /// Preset hotkey options — using Carbon-based HotkeyConfig
    private let hotkeyPresets: [(name: String, config: HotkeyConfig)] = [
        ("⌃Z (Ctrl+Z)", .defaultConfig),
        ("⌃⇧Z (Ctrl+Shift+Z)", .ctrlShiftZ),
        ("⌃⌥Z (Ctrl+Option+Z)", .ctrlOptionZ),
        ("⌃Space (Ctrl+Space)", .ctrlSpace),
        ("⌃⇧Space (Ctrl+Shift+Space)", .ctrlShiftSpace),
        ("⌃⌥O (Ctrl+Option+O)", .ctrlOptionO),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("快捷键设置")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(BrandColors.textPrimary)
                .padding(.bottom, 20)

            // Global hotkey selector
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("触发优化")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BrandColors.textPrimary)
                    Text("选中文本后触发文案优化的全局快捷键")
                        .font(.system(size: 11))
                        .foregroundColor(BrandColors.textMuted)
                }
                Spacer()

                Picker("", selection: $selectedHotkeyIndex) {
                    ForEach(0..<hotkeyPresets.count, id: \.self) { index in
                        Text(hotkeyPresets[index].name).tag(index)
                    }
                }
                .frame(width: 200)
                .onChange(of: selectedHotkeyIndex) { _, newIndex in
                    applyHotkeyPreset(newIndex)
                }
            }
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Divider().background(BrandColors.border)
            }

            // Panel shortcuts (info only)
            ShortcutRow(title: "复制结果", description: "将优化结果复制到剪贴板", shortcut: "⌘⇧C")
            ShortcutRow(title: "切换指令", description: "在优化指令之间快速切换", shortcut: "⌘1-9")
            ShortcutRow(title: "重新生成", description: "对当前原文重新进行优化", shortcut: "⌘R")
            ShortcutRow(title: "关闭面板", description: "隐藏优化面板", shortcut: "Esc")
            ShortcutRow(title: "打开设置", description: "打开偏好设置窗口", shortcut: "⌘⇧,")
        }
        .padding(24)
        .onAppear {
            // Find matching preset index
            let currentDisplay = AppDelegate.shared?.getHotkeyDisplay() ?? HotkeyConfig.defaultConfig.displayString
            selectedHotkeyIndex = hotkeyPresets.firstIndex(where: { $0.config.displayString == currentDisplay }) ?? 0
        }
    }

    private func applyHotkeyPreset(_ index: Int) {
        let config = hotkeyPresets[index].config
        AppDelegate.shared?.updateHotkey(config)
    }
}

struct ShortcutRow: View {
    let title: String
    let description: String
    let shortcut: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrandColors.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(BrandColors.textMuted)
            }
            Spacer()

            Text(shortcut)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(BrandColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(BrandColors.bgTertiary)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(BrandColors.border, lineWidth: 1)
                )
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().background(BrandColors.border)
        }
    }
}
