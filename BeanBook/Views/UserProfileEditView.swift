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
    
    // MARK: - Local States for Profile Fields
    @State private var displayName: String = ""
    @State private var bio: String = ""
    
    // Original values (to detect changes)
    @State private var originalDisplayName: String = ""
    @State private var originalBio: String = ""
    @State private var originalPhotoURL: String = ""
    
    // MARK: - Stock Images
    @State private var stockImages: [URL] = []
    @State private var selectedStockURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // A subtle coffee-inspired background
                LinearGradient(colors: [.brown.opacity(0.25), .black],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    // MARK: - Profile Details Form
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
                    
                    // MARK: - Stock Images Section
                    Text("Choose Avatar")
                        .font(.headline)


                    // A TabView for full-width swiping. We bind `selection` to selectedStockURL
                    // so tapping an image will also update the selection automatically.
                    TabView(selection: $selectedStockURL) {
                        ForEach(stockImages, id: \.self) { url in
                            ZStack {
                                if let selected = selectedStockURL, selected == url {
                                    // If this is the currently selected image, add a highlight border
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.brown, lineWidth: 4)
                                    )
                                } else {
                                    // Not selected => no brown border
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                }
                            }
                            // Tag this page with the url
                            .tag(url)
                            // If you also want to allow direct taps to select
                            .onTapGesture {
                                selectedStockURL = url
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))  // or .always if you want dots
                    .frame(height: 200) // Sufficient to show the 150px circle plus spacing

                    
                    Spacer()
                    
                    // MARK: - Buttons
                    HStack(spacing: 16) {
                        // Cancel Button (if not first-time setup)
                        if !isFirstTimeSetup {
                            Button(role: .cancel) {
                                dismiss()
                            } label: {
                                Text("Cancel")
                            }
                            .padding(.bottom)
                            .buttonStyle(.bordered)
                        }
                        
                        // Save Button
                        Button("Save") {
                            Task {
                                if var updatedProfile = userManager.currentUserProfile {
                                    
                                    // Only update displayName/bio if changed
                                    if hasProfileChanged() {
                                        updatedProfile.displayName = displayName
                                        updatedProfile.bio = bio
                                    }
                                    
                                    // If user selected a new stock avatar
                                    if let chosenURL = selectedStockURL,
                                       chosenURL.absoluteString != originalPhotoURL {
                                        updatedProfile.photoURL = chosenURL.absoluteString
                                    }
                                    
                                    // Write changes to Firestore
                                    await userManager.createOrUpdateUser(profile: updatedProfile)
                                }
                                
                                // After saving, either finish setup or dismiss
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
            // Load existing profile data and stock images
            .task {
                await loadExistingProfile()
                // Fetch stock avatar URLs from Firebase Storage
                stockImages = await userManager.fetchStockProfilePictureURLs()
                
                // If current photoURL is one of the stock images, highlight it
                if let currentURL = URL(string: originalPhotoURL),
                   stockImages.contains(currentURL) {
                    selectedStockURL = currentURL
                }
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
            originalPhotoURL    = existingProfile.photoURL ?? ""
            
            // Fill text fields
            displayName = originalDisplayName
            bio         = originalBio
        }
    }
    
    /// Checks if user changed displayName or bio
    private func hasProfileChanged() -> Bool {
        return (displayName != originalDisplayName || bio != originalBio)
    }
}
