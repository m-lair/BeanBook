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
    @State private var brewManager: CoffeeBrewManager? = nil
    @State private var authManager: AuthManager? = nil
    
    var body: some Scene {
        WindowGroup {
            // If authManager exists, show the ContentView with environment injection
            if let authManager, let brewManager {
                ContentView()
                    .environment(authManager)
                    .environment(brewManager)
            } else {
                // Otherwise, show a quick loading or splash
                Text("Loading…")
                    .onAppear {
                        authManager = AuthManager()
                        brewManager = CoffeeBrewManager()
                    }
            }
        }
    }
}
