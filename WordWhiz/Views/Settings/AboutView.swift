import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon
            Text("Ww")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(BrandColors.accent)
                .cornerRadius(16)

            Text("WordWhiz")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(BrandColors.textPrimary)
                .padding(.top, 16)

            Text("Version 1.0.0 (Build 1)")
                .font(.system(size: 13))
                .foregroundColor(BrandColors.textMuted)
                .padding(.top, 4)

            Text("WordWhiz 是一款 macOS 文案优化工具，通过全局快捷键一键调用 LLM 大语言模型，让你的文字表达更精准、更专业。")
                .font(.system(size: 13))
                .foregroundColor(BrandColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 20)
                .frame(maxWidth: 300)

            Button("检查更新") {
                // Future: Sparkle or manual update check
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding(.top, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}
