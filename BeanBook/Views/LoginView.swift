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
    @State private var confirmPassword = ""
    
    @State private var isSignUp = false
    
    /// Local validation error (independent of Firebase Auth errors)
    @State private var localErrorMessage: String?
    
    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [.brown.opacity(0.25), .black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Bean Book")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                // Optional icon, e.g. coffee cup for style
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .foregroundColor(.brown.opacity(0.8))
                    .padding(.bottom, 16)
                
                // MARK: - Input Card
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .shadow(color: .brown.opacity(0.4), radius: 4, x: 0, y: 4)
                        .opacity(0.6)
                        .frame(maxHeight: 300)
                    
                    VStack(spacing: 16) {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        // Email Field
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color(.secondarySystemBackground).opacity(0.8))
                            .cornerRadius(8)
                        
                        // Password Field
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground).opacity(0.8))
                            .cornerRadius(8)
                        
                        // Confirm Password (only when signing up)
                        if isSignUp {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .padding()
                                .background(Color(.secondarySystemBackground).opacity(0.8))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .padding(.horizontal, 16)
                
                // MARK: - Local Validation Error
                if let localErrorMessage {
                    Text(localErrorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // MARK: - Firebase Auth Error
                if let authError = authManager.errorMessage {
                    Text(authError)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // MARK: - Loading Indicator or Button
                if authManager.isLoading {
                    ProgressView()
                } else {
                    Button(isSignUp ? "Create Account" : "Login") {
                        Task {
                            // Clear local & auth errors
                            localErrorMessage = nil
                            authManager.errorMessage = nil
                            
                            // Basic Validation
                            if isSignUp {
                                // If validation fails, show localError and return
                                guard validateSignUpFields() else { return }
                            }
                            
                            // Start loading
                            authManager.isLoading = true
                            
                            do {
                                if isSignUp {
                                    // 1) Sign up a brand new user
                                    await authManager.signUp(email: email, password: password)
                                    
                                    // 2) Create initial user profile in Firestore
                                    let profile = UserProfile(email: email)
                                    await userManager.createOrUpdateUser(profile: profile)
                                    
                                } else {
                                    // 1) Sign in an existing user
                                    await authManager.signIn(email: email, password: password)
                                    
                                    // 2) Fetch the user’s existing profile from Firestore
                                    await userManager.fetchUserProfile()
                                }
                                
                                let userDefaults = UserDefaults.standard
                                if let pendingToken = userDefaults.string(forKey: "pendingFCMToken") {
                                    await userManager.storeFCMTokenIfAuthenticated(token: pendingToken)
                                    userDefaults.removeObject(forKey: "pendingFCMToken")
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
                    .tint(.brown)
                    .padding(.horizontal, 16)
                }
                
                // MARK: - Toggle Sign Up / Sign In
                Button(isSignUp ?
                       "Already have an account? Sign In" :
                       "Don't have an account? Sign Up") {
                    withAnimation {
                        isSignUp.toggle()
                    }
                }
                .font(.footnote)
                .foregroundColor(.primary)
                .padding(.top, 10)
            }
            .padding()
        }
    }
}

private extension LoginView {
    /// Simple method to validate sign-up fields.
    /// Returns true if fields are valid, false if not.
    @discardableResult
    func validateSignUpFields() -> Bool {
        // Basic rules: must not be empty, must be valid email, password must match confirm
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            localErrorMessage = "Please enter an email address."
            return false
        }
        
        if !isValidEmail(email) {
            localErrorMessage = "Please enter a valid email address."
            return false
        }
        
        if password.count < 6 {
            localErrorMessage = "Password must be at least 6 characters."
            return false
        }
        
        if password != confirmPassword {
            localErrorMessage = "Passwords do not match."
            return false
        }
        
        return true
    }
    
    /// Very basic email format check
    func isValidEmail(_ email: String) -> Bool {
        // This is a simple regex check for illustration. Feel free to expand.
        let emailRegex = #"^\S+@\S+\.\S+$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
