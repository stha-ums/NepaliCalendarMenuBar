//
//  OnboardingManager.swift
//  NepaliDaateMenuBar
//
//  Manages first-time onboarding flow
//

import Foundation
import Combine

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        }
    }
    
    @Published var currentStep: Int = 0 {
        didSet {
            TelemetryManager.shared.track("onboarding.step_changed", with: [
                "step": "\(currentStep + 1)",
                "total": "\(totalSteps)"
            ])
        }
    }
    let totalSteps = 6
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        TelemetryManager.shared.track("onboarding.completed")
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = 0
        TelemetryManager.shared.track("onboarding.reset")
    }
    
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
}

