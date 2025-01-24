//
//  ProfileView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//
import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) var authManager
    @Environment(CoffeeBrewManager.self) var brewManager
    @Environment(UserManager.self) var userManager
    
    @State private var showNewBrew = false
    @State private var showEditProfile = false
    
    // We'll keep a local copy of the user's favorite brews
    @State private var favoriteBrews: [CoffeeBrew] = []
    
    var profile: UserProfile? {
        userManager.currentUserProfile
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient for a coffee-inspired look
                LinearGradient(
                    gradient: Gradient(colors: [.brown.opacity(0.25), .black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // MARK: - Top User Info Section
                    if let profile {
                        // Show user avatar & name
                        userHeaderView(profile: profile)
                    } else {
                        // Fallback if no profile data
                        Text("No profile data")
                            .foregroundStyle(.secondary)
                    }
                    
                    // MARK: - My Brews
                    Text("My Brews")
                        .font(.title2)
                        .bold()
                        .padding(.top, 8)
                    
                    listContainer(brews: brewManager.userBrews)
                    
                    // MARK: - Favorites
                    Text("My Favorites")
                        .font(.title2)
                        .bold()
                        .padding(.top, 16)
                    
                    listContainer(brews: favoriteBrews)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Label("", systemImage: "gearshape")
                    }
                }
            }
            // 1) Sheet for adding a new brew
            .sheet(isPresented: $showNewBrew) {
                NewBrewView()
            }
            // 2) Sheet for editing the profile
            .sheet(isPresented: $showEditProfile) {
                UserProfileEditView(isFirstTimeSetup: false) {
                    showEditProfile = false
                }
            }
            .task {
                guard let user = authManager.user else { return }
                // Fetch the user's brews
                await brewManager.fetchUserBrews(for: user.uid)
                // Fetch the user profile
                await userManager.fetchUserProfile()
                
                // After we know the user's favorites, fetch the brew objects
                if let favorites = userManager.currentUserProfile?.favorites {
                    favoriteBrews = await brewManager.fetchFavoriteBrews(for: favorites)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// A view showing the user's photo, display name, and an 'Edit Profile' button.
    @ViewBuilder
    private func userHeaderView(profile: UserProfile) -> some View {
        VStack(spacing: 12) {
            // Show user avatar if there's a photoURL
            if let photoStr = profile.photoURL,
               let photoURL = URL(string: photoStr) {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Text("No Image")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.brown, lineWidth: 2)
                )
                .shadow(radius: 4)
            } else {
                // No photo
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle().stroke(Color.brown, lineWidth: 2)
                    )
                    .overlay(
                        Text("No Image")
                            .foregroundStyle(.secondary)
                    )
            }
            
            Text(profile.displayName ?? "Unknown User")
                .font(.title3)
                .bold()
            
            Button("Edit Profile") {
                showEditProfile = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown)
        }
        .padding(.bottom, 8)
    }
    
    /// A container that shows a given brew list in a card, so the gradient can appear behind it.
    private func listContainer(brews: [CoffeeBrew]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear.opacity(0.8))
                .shadow(radius: 2)
            
            List(brews) { brew in
                NavigationLink {
                    BrewDetailView(brew: brew)
                } label: {
                    VStack(alignment: .leading) {
                        Text(brew.title)
                            .font(.headline)
                        Text(brew.method)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .frame(maxHeight: .infinity)
    }
}
