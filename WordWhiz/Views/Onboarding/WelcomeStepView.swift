import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Ww")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(BrandColors.accent)
                .cornerRadius(20)

            Text("欢迎使用 WordWhiz")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(BrandColors.textPrimary)

            Text("一款 macOS 全局文案优化工具")
                .font(.system(size: 16))
                .foregroundColor(BrandColors.textSecondary)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "text.cursor", text: "在任意应用中选中文本")
                FeatureRow(icon: "keyboard", text: "按 ⌃Z 一键触发优化")
                FeatureRow(icon: "sparkles", text: "LLM 实时流式生成结果")
                FeatureRow(icon: "doc.on.doc", text: "一键复制，即时使用")
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(40)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(BrandColors.accent)
                .font(.system(size: 16))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(BrandColors.textSecondary)

            Spacer()
        }
    }
}
