import SwiftUI

struct APIConfigStepView: View {
    @Environment(OnboardingViewModel.self) var onboardingVM
    @Environment(SettingsViewModel.self) var settingsVM

    var body: some View {
        @Bindable var settingsVM = settingsVM

        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(BrandColors.accent)

            Text("配置 API")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(BrandColors.textPrimary)

            Text("选择 LLM 服务商并配置 API Key")
                .font(.system(size: 14))
                .foregroundColor(BrandColors.textSecondary)

            VStack(alignment: .leading, spacing: 12) {
                // Provider
                HStack {
                    Text("服务商")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BrandColors.textPrimary)
                        .frame(width: 60, alignment: .leading)

                    Picker("", selection: $settingsVM.llmProvider) {
                        ForEach(LLMProviderConfig.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .onChange(of: settingsVM.llmProvider) {
                        settingsVM.loadAPIKeyForCurrentProvider()
                    }
                }

                // API Key
                HStack {
                    Text("API Key")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BrandColors.textPrimary)
                        .frame(width: 60, alignment: .leading)

                    SecureField("输入 API Key", text: $settingsVM.apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(BrandColors.textPrimary)
                        .padding(8)
                        .background(BrandColors.bgSecondary)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(BrandColors.border, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)

            // Test connection
            HStack(spacing: 12) {
                Button("测试连接") {
                    settingsVM.testConnection()
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandColors.accent)
                .controlSize(.small)
                .disabled(settingsVM.apiKey.isEmpty)

                if let result = settingsVM.connectionTestResult {
                    switch result {
                    case .success:
                        Label("连接成功", systemImage: "checkmark.circle.fill")
                            .foregroundColor(BrandColors.green)
                            .font(.system(size: 13))
                    case .failure(let msg):
                        Label(msg, systemImage: "xmark.circle.fill")
                            .foregroundColor(BrandColors.red)
                            .font(.system(size: 12))
                    }
                }
            }

            Button("跳过，稍后配置") {
                onboardingVM.completeOnboarding()
            }
            .buttonStyle(.plain)
            .foregroundColor(BrandColors.textMuted)
            .font(.system(size: 12))

            Spacer()
        }
        .padding(40)
    }
}
