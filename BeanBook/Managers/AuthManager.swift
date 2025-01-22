//
//  AuthManager.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//


import SwiftUI
import FirebaseAuth

@Observable
class AuthManager {
    
    // The current Firebase user (nil if not logged in)
    var user: User?
    
    // For showing loading UI
    var isLoading: Bool = false
    
    // For displaying any auth errors in the UI
    var errorMessage: String?
    
    init() {
        // Listen for real-time Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            self?.user = user
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            // If successful, user will be updated automatically via addStateDidChangeListener
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            // Same as signIn, user property will auto-update
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            // user becomes nil automatically
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
