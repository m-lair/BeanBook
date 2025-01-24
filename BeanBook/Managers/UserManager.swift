//
//  UserManager.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

@Observable
class UserManager {
    // The data model for your user doc
    var currentUserProfile: UserProfile?
    
    private let db = Firestore.firestore()
    
    // For convenience, store the current user’s UID (if logged in)
    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Fetch the user document
    func fetchUserProfile() async {
        guard let uid = currentUID else { return }
        print("got currentUID: \(uid)")
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            let profile = try snapshot.data(as: UserProfile.self)
            print("fetched UserProfile: \(profile)")
            currentUserProfile = profile
        } catch {
            print("error fetching User Profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Create or update the user doc
    func createOrUpdateUser(profile: UserProfile) async {
        guard let uid = currentUID else { return }
        
        // Using `setData(from:)` with the `UserProfile` struct
        do {
            var updatedProfile = profile
            updatedProfile.updatedAt = Date() // Set updatedAt to the current timestamp
            
            try db.collection("users")
                .document(uid)
                .setData(from: updatedProfile, merge: true)
            
            // After updating, we might want to refresh our local copy
            await fetchUserProfile()
        } catch {
            print("Error creating/updating user doc: \(error)")
        }
    }

    // MARK: - Favorites Handling
    /// Check if a brew is favorited by the current user
    func isFavorite(brew: CoffeeBrew) -> Bool {
        guard let brewID = brew.id else { return false }
        return currentUserProfile?.favorites.contains(brewID) == true
    }
    
    /// Toggle the brew’s ID in the current user’s favorites list
    func toggleFavorite(brew: CoffeeBrew) async {
        guard let uid = currentUID,
              let brewID = brew.id else { return }
        
        // Make sure we have a local copy of the user profile
        guard var profile = currentUserProfile else { return }
        
        if profile.favorites.contains(brewID) {
            // Already favorited => remove it
            profile.favorites.removeAll { $0 == brewID }
        } else {
            // Not favorited => add it
            profile.favorites.append(brewID)
        }
        
        // Update our local userProfile immediately for a more responsive UI
        currentUserProfile = profile
        
        // Persist to Firestore
        do {
            try db.collection("users").document(uid).setData(from: profile, merge: true)
        } catch {
            print("Failed to update favorites: \(error)")
        }
    }

    // MARK: - Realtime Listener
    private var listener: ListenerRegistration?
    func startListeningForProfile() {
        guard let uid = currentUID else { return }
        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening for user changes: \(error)")
                    return
                }
                if let snapshot = snapshot, snapshot.exists {
                    do {
                        let profile = try snapshot.data(as: UserProfile.self)
                        self?.currentUserProfile = profile
                    } catch {
                        print("Error decoding user profile: \(error)")
                    }
                }
            }
    }
    
    func stopListeningForProfile() {
        listener?.remove()
        listener = nil
    }
}
