import SwiftUI

struct AccessibilityStepView: View {
    @Environment(OnboardingViewModel.self) var viewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: viewModel.isAccessibilityGranted ? "checkmark.shield.fill" : "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(viewModel.isAccessibilityGranted ? BrandColors.green : BrandColors.accent)

            Text("授权辅助功能")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(BrandColors.textPrimary)

            Text("WordWhiz 需要辅助功能权限来读取您在其他应用中选中的文本，以及注册全局快捷键。")
                .font(.system(size: 14))
                .foregroundColor(BrandColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 360)

            if viewModel.isAccessibilityGranted {
                Label("已授权", systemImage: "checkmark.circle.fill")
                    .foregroundColor(BrandColors.green)
                    .font(.system(size: 16, weight: .medium))
            } else {
                VStack(spacing: 12) {
                    Button("授权辅助功能") {
                        viewModel.requestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandColors.accent)
                    .controlSize(.regular)

                    Button("打开系统设置") {
                        viewModel.openAccessibilityPreferences()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Text("授权后需重启 WordWhiz 才能生效")
                        .font(.system(size: 11))
                        .foregroundColor(BrandColors.textMuted)
                }
            }

            Spacer()
        }
        .padding(40)
        .onAppear {
            viewModel.startAccessibilityPolling()
        }
        .onDisappear {
            viewModel.stopAccessibilityPolling()
        }
    }
}
