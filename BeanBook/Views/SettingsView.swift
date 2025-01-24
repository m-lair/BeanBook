//
//  SettingsView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/23/25.
//


//
//  SettingsView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(UserManager.self) var userManager
    @Environment(AuthManager.self) var authManager
    @Environment(\.dismiss) var dismiss
    
    @State private var userProfile = UserProfile(displayName: "", email: "", bio: "", favorites: [])
    @State private var isEditingProfile = false
    @State private var notificationsEnabled = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section(header: Text("Profile")) {
                    HStack {
                        Text("Display Name")
                        Spacer()
                        Text(userProfile.displayName ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(userProfile.email)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Edit Profile") {
                        isEditingProfile = true
                    }
                }
                
                // Settings Section
                Section(header: Text("Settings")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                    }
                }
                
                // Account Section
                Section(header: Text("Account")) {
                    Button("Sign Out") {
                        Task {
                            authManager.signOut()
                            dismiss()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    if let profile = userManager.currentUserProfile {
                        userProfile = profile
                    }
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                UserProfileEditView(
                    isFirstTimeSetup: false,
                    onFinish: {
                        isEditingProfile = false
                        Task {
                            await userManager.fetchUserProfile()
                            
                        }
                    })
            }
        }
    }
}

// Placeholder Views
struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("Terms of Service")
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
    }
}
