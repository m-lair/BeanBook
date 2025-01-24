//
//  LoginView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Environment(AuthManager.self) var authManager
    @Environment(UserManager.self) var userManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Sign Up" : "Sign In")
                .font(.largeTitle)
            
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            // Display any auth error
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Loading indicator
            if authManager.isLoading {
                ProgressView()
            } else {
                Button(isSignUp ? "Create Account" : "Login") {
                    Task {
                        // Start loading
                        authManager.isLoading = true
                        authManager.errorMessage = nil
                        
                        do {
                            if isSignUp {
                                // 1) Sign up a brand new user
                                await authManager.signUp(email: email, password: password)
                                
                                let profile = UserProfile(email: email)
                                await userManager.createOrUpdateUser(profile: profile)
    
                            } else {
                                // 1) Sign in an existing user
                                await authManager.signIn(email: email, password: password)
                                
                                // 2) Fetch the user’s existing profile from Firestore
                                //    (If there's no doc, you could create a minimal one here instead)
                                await userManager.fetchUserProfile()
                            }
                        } catch {
                            // Show error in UI
                            authManager.errorMessage = error.localizedDescription
                        }
                        
                        // Stop loading
                        authManager.isLoading = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Toggle sign up / sign in
            Button(isSignUp ?
                   "Already have an account? Sign In" :
                   "Don't have an account? Sign Up") {
                isSignUp.toggle()
            }
            .font(.footnote)
            .padding(.top, 10)
        }
        .padding()
    }
}
