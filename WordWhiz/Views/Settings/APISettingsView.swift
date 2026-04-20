import SwiftUI

struct APISettingsView: View {
    @Environment(SettingsViewModel.self) var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 0) {
            Text("模型配置")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(BrandColors.textPrimary)
                .padding(.bottom, 20)

            // Provider picker
            VStack(alignment: .leading, spacing: 6) {
                Text("LLM 服务商")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrandColors.textPrimary)

                Picker("", selection: $viewModel.llmProvider) {
                    ForEach(LLMProviderConfig.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .onChange(of: viewModel.llmProvider) {
                    viewModel.loadAPIKeyForCurrentProvider()
                    viewModel.updateDefaultBaseURLAndModel()
                }
            }
            .padding(.bottom, 16)

            // API Key
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrandColors.textPrimary)
                Text("你的 API 密钥，存储在本地 Keychain 中，安全加密")
                    .font(.system(size: 11))
                    .foregroundColor(BrandColors.textMuted)

                StyledSecureField(text: $viewModel.apiKey, placeholder: "")
                    .padding(8)
                    .background(BrandColors.bgSecondary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(BrandColors.border, lineWidth: 1)
                    )
            }
            .padding(.bottom, 16)

            // Base URL
            VStack(alignment: .leading, spacing: 6) {
                Text("API Base URL")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrandColors.textPrimary)
                Text("自定义 API 端点（留空使用默认地址）")
                    .font(.system(size: 11))
                    .foregroundColor(BrandColors.textMuted)

                StyledTextField(text: $viewModel.apiBaseURL, placeholder: viewModel.llmProvider.defaultBaseURL)
                    .padding(8)
                    .background(BrandColors.bgSecondary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(BrandColors.border, lineWidth: 1)
                    )
            }
            .padding(.bottom, 16)

            // Model name
            VStack(alignment: .leading, spacing: 6) {
                Text("模型名称")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrandColors.textPrimary)

                StyledTextField(text: $viewModel.modelName, placeholder: viewModel.llmProvider.defaultModel)
                    .padding(8)
                    .background(BrandColors.bgSecondary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(BrandColors.border, lineWidth: 1)
                    )
            }
            .padding(.bottom, 20)

            // Test connection
            HStack {
                Button {
                    viewModel.testConnection()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isTestingConnection {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(viewModel.isTestingConnection ? "测试中..." : "测试连接")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandColors.accent)
                .controlSize(.small)
                .disabled(viewModel.apiKey.isEmpty || viewModel.isTestingConnection)

                if let result = viewModel.connectionTestResult {
                    switch result {
                    case .success:
                        Label("连接成功", systemImage: "checkmark.circle.fill")
                            .foregroundColor(BrandColors.green)
                            .font(.system(size: 13))
                    case .failure(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .foregroundColor(BrandColors.red)
                            .font(.system(size: 12))
                    }
                }
            }
        }
        .padding(24)
        .onAppear {
            viewModel.loadAPIKeyForCurrentProvider()
        }
    }
}
