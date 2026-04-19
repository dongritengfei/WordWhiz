import SwiftUI

@Observable
@MainActor
final class OnboardingViewModel {
    var currentStep: Int = 0
    var isAccessibilityGranted: Bool = false

    let totalSteps = 3

    private var accessibilityPollTimer: Timer?

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

    func checkAccessibility() {
        isAccessibilityGranted = AccessibilityChecker.isTrusted
    }

    func startAccessibilityPolling() {
        checkAccessibility()
        accessibilityPollTimer?.invalidate()
        accessibilityPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                let granted = AccessibilityChecker.isTrusted
                self?.isAccessibilityGranted = granted
                if granted {
                    self?.stopAccessibilityPolling()
                }
            }
        }
    }

    func stopAccessibilityPolling() {
        accessibilityPollTimer?.invalidate()
        accessibilityPollTimer = nil
    }

    func requestAccessibility() {
        AccessibilityChecker.requestPermission()
        startAccessibilityPolling()
    }

    func openAccessibilityPreferences() {
        AccessibilityChecker.openAccessibilityPreferences()
    }

    func completeOnboarding() {
        stopAccessibilityPolling()
        UserDefaults.standard.set(true, forKey: Constants.hasCompletedOnboardingKey)
        // Close the onboarding window
        NSApp.windows.first { $0.title.contains("Onboarding") || $0.identifier?.rawValue == "onboarding" }?.close()
    }
}
