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
                    NotificationsToggleView()
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                    }
                }
                
                // Account Section
                Section(header: Text("Account")) {
                    PressAndHoldActionButton(
                        label: "Sign Out",
                        baseColor: Color.brown.opacity(0.3),
                        fillColor: Color.brown,
                        holdDuration: 2.0
                    ) {
                        authManager.signOut()
                        dismiss()
                    }
                    
                    PressAndHoldActionButton(
                        label: "Delete Account",
                        baseColor: Color.red.opacity(0.3),
                        fillColor: Color.red,
                        holdDuration: 2.0
                    ) {
                        Task {
                            // 1) Perform the delete
                            try await userManager.deleteUser()
                            authManager.signOut()
                            
                            dismiss()
                        }
                    }
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

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title3)
                    .bold()

                Text("""
We value your privacy. During the beta, Bean Book temporarily stores:
• Your basic profile info (if you sign in)
• Log data (crashes, performance metrics)

All data is used exclusively for improving Bean Book. Once the beta ends, your personal data will be removed from our test environments.

If you have any questions or concerns, please email us at:
beanbookapp@gmail.com
""")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title3)
                    .bold()

                Text("""
Welcome to Bean Book! By using this app, you agree to the following:

1. **User Content**  
   You’re responsible for the photos or notes you upload. Please ensure you have the right to share any third-party content.

2. **Beta Disclaimer**  
   This is a beta version of Bean Book. Features may change or break. Your data may be reset at any time during testing.

3. **Liability**  
   Bean Book is provided “as is” without any warranties. We do not assume liability for any damages arising from your use of the app.

4. **Updates**  
   We may update these Terms at any time. Continued use indicates your acceptance of the new Terms.

If you have questions or concerns, please reach out: beanbookapp@gmail.com
""")
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI
import UserNotifications

struct NotificationsToggleView: View {
    @State private var notificationsEnabled = false
    
    var body: some View {
        Toggle("Enable Daily Coffee Reminders", isOn: $notificationsEnabled)
            .onChange(of: notificationsEnabled) {
                if notificationsEnabled {
                    // User toggled notifications ON
                    checkOrRequestNotificationPermissions {
                        // If permission is granted, schedule the daily reminder
                        NotificationManager.shared.scheduleDailyCoffeeReminder()
                    }
                } else {
                    // User toggled notifications OFF
                    UNUserNotificationCenter.current()
                        .removePendingNotificationRequests(withIdentifiers: ["daily_coffee_reminder"])
                }
            }
            .onAppear {
                // Check if the "daily_coffee_reminder" is currently scheduled
                // so we can set the toggle's initial state correctly.
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    DispatchQueue.main.async {
                        self.notificationsEnabled = requests.contains { $0.identifier == "daily_coffee_reminder" }
                    }
                }
            }
    }
    
    private func checkOrRequestNotificationPermissions(grantedAction: @escaping () -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // Request permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Request authorization error: \(error.localizedDescription)")
                            self.notificationsEnabled = false
                            return
                        }
                        self.notificationsEnabled = granted
                        if granted {
                            grantedAction()
                        }
                    }
                }
            case .denied:
                // Direct user to Settings
                DispatchQueue.main.async {
                    self.notificationsEnabled = false
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            case .authorized, .provisional, .ephemeral:
                // Already granted
                DispatchQueue.main.async {
                    grantedAction()
                }
            @unknown default:
                break
            }
        }
    }
}
 
