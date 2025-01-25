//
//  BeanBookApp.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @Environment(UserManager.self) private var userManager
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        // 1) Configure Firebase
        FirebaseApp.configure()
        
        // 2) Request Notification Permission
        configureUserNotifications()
        
        // 3) For push: set up the messaging delegate
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // MARK: - Request User Notification Permissions
    private func configureUserNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
            if granted {
                DispatchQueue.main.async {
                    NotificationManager.shared.scheduleDailyCoffeeReminder()
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("User declined notification permissions.")
            }
        }
    }
    
    // MARK: - APNs Token Handling
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to Firebase
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error)")
    }
}

// MARK: - Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        // 1) If the user is logged in, store it immediately.
        if Auth.auth().currentUser?.uid != nil {
            Task {
                print("calling storeFCMTokenIfAuthenticated")
                await userManager.storeFCMTokenIfAuthenticated(token: fcmToken)
            }
        } else {
            // 2) If no user is logged in yet, store it for later in UserDefaults (optional).
            UserDefaults.standard.set(fcmToken, forKey: "pendingFCMToken")
        }
    }
}

@main
struct BeanBookApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var userManager: UserManager? = nil
    @State private var brewManager: CoffeeBrewManager? = nil
    @State private var authManager: AuthManager? = nil
    
    var body: some Scene {
        WindowGroup {
            if let authManager, let brewManager, let userManager {
                ContentView()
                    .environment(authManager)
                    .environment(brewManager)
                    .environment(userManager)
    
            } else {
                Text("Loading…")
                    .onAppear {
                        authManager = AuthManager()
                        brewManager = CoffeeBrewManager()
                        userManager = UserManager()
                    }
            }
        }
    }
}
