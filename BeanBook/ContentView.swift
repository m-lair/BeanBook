//
//  ContentView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) var authManager
        
    var body: some View {
        if let _ = authManager.user {
            // User is logged in – show main features
            MainTabView()
        } else {
            // User is not logged in – show the login screen
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
