//
//  UserProfileEditView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI
import PhotosUI

struct UserProfileEditView: View {
    /// If we’re in first-time setup, we might have a different flow
    let isFirstTimeSetup: Bool
    /// Closure to call when the user finishes
    let onFinish: () -> Void
    
    @Environment(UserManager.self) var userManager
    @Environment(\.dismiss) var dismiss
    
    // Local states for user-entered profile info
    @State private var displayName: String = ""
    @State private var bio: String = ""
    
    // We also store the original data to detect changes
    @State private var originalDisplayName: String = ""
    @State private var originalBio: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // A subtle coffee-inspired background
                LinearGradient(colors: [.brown.opacity(0.25), .black],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Form {
                        Section("Profile Details") {
                            TextField("Display Name", text: $displayName)
                            
                            TextField("Bio", text: $bio, axis: .vertical)
                                .lineLimit(3)
                                .textInputAutocapitalization(.none)
                                .autocorrectionDisabled(true)
                        }
                    }
                    .formStyle(.grouped)
                    .frame(maxHeight: 150)
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        if !isFirstTimeSetup {
                            // If user is not in first-time setup, show a Cancel button
                            Button(role: .cancel) {
                                dismiss()
                            } label: {
                                Text("Cancel")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button("Save") {
                            Task {
                                // Determine if anything actually changed
                                if hasProfileChanged() {
                                    // If so, build an updated profile
                                    if var updatedProfile = userManager.currentUserProfile {
                                        
                                        // Apply new values
                                        updatedProfile.displayName = displayName
                                        updatedProfile.bio = bio
                                        
                                        // Call your userManager method to update Firestore
                                        await userManager.createOrUpdateUser(profile: updatedProfile)
                                    }
                                }
                                
                                // After saving or skipping (no changes),
                                // handle first-time or regular flow
                                if isFirstTimeSetup {
                                    onFinish()
                                } else {
                                    dismiss()
                                }
                            }
                        }
                        .padding(.bottom)
                        .buttonStyle(.borderedProminent)
                        .tint(.brown)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 16)
            }
            .navigationTitle(isFirstTimeSetup ? "Set Up Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            // Load existing profile data into our local states
            .task {
                await loadExistingProfile()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads the existing user profile (if any) into our local states
    private func loadExistingProfile() async {
        // Make sure we have a user profile to load
        await userManager.fetchUserProfile()  // In case it wasn't fetched yet
        
        if let existingProfile = userManager.currentUserProfile {
            // Store originals for comparison
            originalDisplayName = existingProfile.displayName ?? ""
            originalBio         = existingProfile.bio ?? ""
            
            // Fill text fields
            displayName = originalDisplayName
            bio         = originalBio
        }
    }
    
    /// Checks if user changed displayName or bio
    private func hasProfileChanged() -> Bool {
        // We compare the new states with the originals
        return (displayName != originalDisplayName || bio != originalBio)
    }
}
