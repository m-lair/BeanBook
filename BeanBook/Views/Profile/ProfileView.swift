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
    @Environment(CoffeeBagManager.self) var bagManager
    @Environment(UserManager.self) var userManager
    
    @State private var showNewBrew = false
    
    // We'll keep a local copy of the user's favorite brews
    @State private var favoriteBrews: [CoffeeBrew] = []
    
    // Segmented Picker selection
    @State private var selectedSegment: ProfileSegment = .myBrews
    
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
                        userHeaderView(profile: profile)
                    } else {
                        Text("No profile data")
                            .foregroundStyle(.secondary)
                    }
                    
                    // MARK: - Segmented Picker
                    Picker("", selection: $selectedSegment) {
                        ForEach(ProfileSegment.allCases, id: \.self) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    
                    // MARK: - Display the Selected List
                    if selectedSegment == .myBrews {
                        listContainer(brews: brewManager.userBrews)
                    } else if selectedSegment == .favorites {
                        listContainer(brews: favoriteBrews)
                    } else {
                        BagListView()
                    }
                    
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 16)
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
            .task {
                guard let user = authManager.user else { return }
                // Fetch the user's brews
                await brewManager.fetchUserBrews(for: user.uid)
                // Fetch the user profile
                await userManager.fetchUserProfile()
                
                await bagManager.fetchCoffeeBags()
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
            
            if let bio = profile.bio, !bio.isEmpty, bio != "nil" {
                Text(bio)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
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
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
    }
    
}

// MARK: - Segmented Picker Enum
enum ProfileSegment: CaseIterable {
    case myBrews
    case myBags
    case favorites
    
    
    var title: String {
        switch self {
        case .myBrews: return "My Brews"
        case .myBags: return "My Bags"
        case .favorites: return "Favorites"
        }
    }
}
