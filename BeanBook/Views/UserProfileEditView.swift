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
    
    @Environment(UserManager.self) private var userManager
    @Environment(\.dismiss) private var dismiss
    
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
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // A subtle coffee-inspired background
                LinearGradient(
                    colors: [.brown.opacity(0.25), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    // 1) Profile Details Form
                    ProfileDetailsForm(
                        displayName: $displayName,
                        bio: $bio
                    )
                    .frame(maxHeight: 150)
                    
                    // 2) Stock Avatar Picker
                    StockAvatarPicker(
                        stockImages: stockImages,
                        selectedStockURL: $selectedStockURL
                    )
                    
                    Spacer()
                    
                    // 3) Action Buttons
                    ActionButtons(
                        isFirstTimeSetup: isFirstTimeSetup,
                        onCancel: { dismiss() },
                        onSave: { saveProfileChanges() }
                    )
                }
                .padding(.top, 40)
                .padding(.horizontal, 16)
            }
            .navigationTitle(isFirstTimeSetup ? "Set Up Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            // Load existing profile data and stock images
            .task {
                // 1) Load user profile info
                await loadExistingProfile()
                // 2) Fetch stock avatar URLs from Firebase Storage
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
    
    /// Saves the user’s changes to Firestore
    private func saveProfileChanges() {
        Task {
            guard var updatedProfile = userManager.currentUserProfile else { return }
            
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
            
            // After saving, either finish setup or dismiss
            if isFirstTimeSetup {
                onFinish()
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Subview #1: Profile Details Form
/// A small form for editing displayName and bio.
fileprivate struct ProfileDetailsForm: View {
    @Binding var displayName: String
    @Binding var bio: String
    
    var body: some View {
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
        .cornerRadius(20)
    }
}

// MARK: - Subview #2: Stock Avatar Picker
/// A full-width TabView with page style, letting the user swipe horizontally
/// between large circular avatar options. Highlights the selected image.
fileprivate struct StockAvatarPicker: View {
    let stockImages: [URL]
    @Binding var selectedStockURL: URL?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Choose Avatar")
                .font(.headline)
            
            TabView(selection: $selectedStockURL) {
                ForEach(stockImages, id: \.self) { url in
                    ZStack {
                        // Circular image
                        ZStack {
                            // Replace with your own CachedAsyncImage or keep AsyncImage
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        (selectedStockURL == url) ? Color.brown : Color.clear,
                                        lineWidth: 5
                                    )
                            )
                        }
                        .onTapGesture {
                            selectedStockURL = url
                        }
                        
                        // Checkmark overlay if selected
                        if selectedStockURL == url {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.green)
                                        .padding([.top, .trailing], 6)
                                }
                                Spacer()
                            }
                        }
                    }
                    .tag(url)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // or .never
            .frame(height: 250)
        }
    }
}

// MARK: - Subview #3: Action Buttons
/// Display "Save" and optional "Cancel" (if not first-time setup).
fileprivate struct ActionButtons: View {
    let isFirstTimeSetup: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Cancel Button (if not first-time setup)
            if !isFirstTimeSetup {
                Button(role: .cancel) {
                    onCancel()
                } label: {
                    Text("Cancel")
                }
                .padding(.bottom)
                .buttonStyle(.bordered)
            }
            
            // Save Button
            Button("Save") {
                onSave()
            }
            .padding(.bottom)
            .buttonStyle(.borderedProminent)
            .tint(.brown)
        }
    }
}
