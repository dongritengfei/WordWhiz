import SwiftUI

@Observable
@MainActor
final class OnboardingViewModel {
    var currentStep: Int = 0

    let totalSteps = 2

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Constants.hasCompletedOnboardingKey)
        // Close the onboarding window
        NSApp.windows.first { $0.title.contains("Onboarding") || $0.identifier?.rawValue == "onboarding" }?.close()
    }
}
