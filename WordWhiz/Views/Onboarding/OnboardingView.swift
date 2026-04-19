import SwiftUI

struct OnboardingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Environment(SettingsViewModel.self) var settingsVM

    var body: some View {
        VStack(spacing: 0) {
            // Step content
            TabView(selection: Binding(
                get: { viewModel.currentStep },
                set: { viewModel.currentStep = $0 }
            )) {
                WelcomeStepView()
                    .tag(0)

                AccessibilityStepView()
                    .tag(1)

                APIConfigStepView()
                    .tag(2)
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut, value: viewModel.currentStep)

            // Navigation
            HStack {
                if viewModel.currentStep > 0 {
                    Button("上一步") {
                        viewModel.previousStep()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }

                Spacer()

                // Step indicators
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                        Circle()
                            .fill(step == viewModel.currentStep ? BrandColors.accent : BrandColors.border)
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    Button("下一步") {
                        viewModel.nextStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandColors.accent)
                    .controlSize(.regular)
                } else {
                    Button("开始使用") {
                        viewModel.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandColors.accent)
                    .controlSize(.regular)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(BrandColors.bgSecondary)
        }
        .background(BrandColors.bgPanel)
    }
}
