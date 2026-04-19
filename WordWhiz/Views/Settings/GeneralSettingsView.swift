import SwiftUI

struct GeneralSettingsView: View {
    @Environment(SettingsViewModel.self) var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 0) {
            Text("通用设置")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(BrandColors.textPrimary)
                .padding(.bottom, 20)

            SettingsRow(title: "开机自启动", description: "登录时自动启动 WordWhiz") {
                Toggle("", isOn: $viewModel.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            SettingsRow(title: "显示 Dock 图标", description: "在 Dock 中显示应用图标") {
                Toggle("", isOn: $viewModel.showDockIcon)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            SettingsRow(title: "优化后自动复制", description: "优化完成后自动将结果复制到剪贴板") {
                Toggle("", isOn: $viewModel.autoCopy)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            SettingsRow(title: "保留优化历史", description: "保存每次优化的原文和结果") {
                Toggle("", isOn: $viewModel.keepHistory)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            SettingsRow(title: "面板位置", description: "优化面板的默认弹出位置") {
                Picker("", selection: $viewModel.panelPosition) {
                    ForEach(PanelPosition.allCases, id: \.self) { pos in
                        Text(pos.displayName).tag(pos)
                    }
                }
                .frame(width: 140)
            }
        }
        .padding(24)
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: Content

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
            content
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().background(BrandColors.border)
        }
    }
}
