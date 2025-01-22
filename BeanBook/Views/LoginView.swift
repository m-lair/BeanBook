//
//  LoginView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) var authManager
    
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
            }
            
            // Loading indicator
            if authManager.isLoading {
                ProgressView()
            } else {
                Button(isSignUp ? "Create Account" : "Login") {
                    Task {
                        if isSignUp {
                            await authManager.signUp(email: email, password: password)
                        } else {
                            await authManager.signIn(email: email, password: password)
                        }
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

#Preview {
    // For previews, create a local manager
    LoginView()
        .environment(AuthManager())
}
