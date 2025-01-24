//
//  BeanBookApp.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct BeanBookApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // We’ll create our AuthManager here:
    @State private var userManager: UserManager? = nil
    @State private var brewManager: CoffeeBrewManager? = nil
    @State private var authManager: AuthManager? = nil
    
    var body: some Scene {
        WindowGroup {
            // If authManager exists, show the ContentView with environment injection
            if let authManager, let brewManager, let userManager {
                ContentView()
                    .environment(authManager)
                    .environment(brewManager)
                    .environment(userManager)
            } else {
                // Otherwise, show a quick loading or splash
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
