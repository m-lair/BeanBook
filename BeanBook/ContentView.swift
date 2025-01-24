//
//  ContentView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) var authManager
    
    // Control flows
    @State private var shouldShowOnboarding = false
    @State private var shouldShowProfileSetup = false
    
    var body: some View {
        Group {
            if let user = authManager.user {
                if shouldShowOnboarding {
                    // Show the Onboarding Screen
                    OnboardingView {
                        // Once the user completes onboarding, present the profile setup
                        shouldShowProfileSetup = true
                    }
                    // Present profile setup as a sheet
                    .sheet(isPresented: $shouldShowProfileSetup, onDismiss: {
                        // After dismissing, mark onboarding as seen
                        markOnboardingAsSeen(for: user.uid)
                    }) {
                        UserProfileEditView(isFirstTimeSetup: true) {
                            // Dismiss the sheet
                            shouldShowProfileSetup = false
                        }
                    }
                } else {
                    // Already completed onboarding -> show main app features
                    MainTabView()
                }
            } else {
                // If user not logged in, show a login screen
                LoginView()
            }
        }
        // Observe changes to authManager.user
        .onChange(of: authManager.user) {
            guard let user = authManager.user else {
                // If user is nil, no onboarding needed
                shouldShowOnboarding = false
                shouldShowProfileSetup = false
                return
            }
            
            let key = "hasSeenOnboarding-\(user.uid)"
            let hasSeenOnboarding = UserDefaults.standard.bool(forKey: key)
            
            if !hasSeenOnboarding {
                // The user hasn't seen onboarding yet
                shouldShowOnboarding = true
            } else {
                // They have seen onboarding, so skip directly to main app
                shouldShowOnboarding = false
            }
        }
    }
    
    private func markOnboardingAsSeen(for uid: String) {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding-\(uid)")
        shouldShowOnboarding = false
    }
}
