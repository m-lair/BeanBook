//
//  CoffeeBrewManager.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import Observation
import Foundation
import FirebaseFirestore

@Observable
class CoffeeBrewManager {
    // All brews
    var coffeeBrews: [CoffeeBrew] = []
    // Holds only the current user’s brews (for the “Profile” screen)
    var userBrews: [CoffeeBrew] = []
    
    private let db = Firestore.firestore()
    
    private var userNameCache: [String: String] = [:]
    
    // ---------------------------------------
    // MARK: - Fetch All Brews
    // ---------------------------------------
    func fetchBrews() async {
        do {
            let snapshot = try await db.collection("coffeeBrews")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var fetchedBrews = snapshot.documents.compactMap {
                try? $0.data(as: CoffeeBrew.self)
            }
            
            for i in fetchedBrews.indices {
                let brew = fetchedBrews[i]
                let creatorName = await getCreatorName(for: brew.creatorId)
                fetchedBrews[i].creatorName = creatorName
            }
            self.coffeeBrews = fetchedBrews
        } catch {
            print("Error fetching coffee brews: \(error)")
        }
    }
    
    // ---------------------------------------
    // MARK: - Fetch Current User’s Brews
    // ---------------------------------------
    func fetchUserBrews(for uid: String) async {
        do {
            let snapshot = try await db.collection("coffeeBrews")
                .whereField("creatorId", isEqualTo: uid)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var fetchedBrews = snapshot.documents.compactMap {
                try? $0.data(as: CoffeeBrew.self)
            }
            
            for i in fetchedBrews.indices {
                let brew = fetchedBrews[i]
                let creatorName = await getCreatorName(for: brew.creatorId)
                fetchedBrews[i].creatorName = creatorName
            }
            self.userBrews = fetchedBrews
        } catch {
            print("Error fetching user brews: \(error)")
        }
    }
    
    // ---------------------------------------
    // MARK: - Fetch Favorite Brews
    // ---------------------------------------
    /// Fetch all brews whose IDs appear in `brewIDs`.
    func fetchFavoriteBrews(for brewIDs: [String]) async -> [CoffeeBrew] {
        guard !brewIDs.isEmpty else { return [] }
        
        do {
            // Firestore limit: you can only pass up to 10 IDs in one `in` query
            // If you expect more, you need a different approach (like chunking).
            let snapshot = try await db.collection("coffeeBrews")
                .whereField(FieldPath.documentID(), in: brewIDs)
                .getDocuments()
            
            var favoriteBrews = snapshot.documents.compactMap {
                try? $0.data(as: CoffeeBrew.self)
            }
            
            // Fill in the creatorName for each brew
            for i in favoriteBrews.indices {
                let brew = favoriteBrews[i]
                let creatorName = await getCreatorName(for: brew.creatorId)
                favoriteBrews[i].creatorName = creatorName
            }
            
            return favoriteBrews
        } catch {
            print("Error fetching favorite brews: \(error)")
            return []
        }
    }
    
    // ---------------------------------------
    // MARK: - incr save count
    // ---------------------------------------
    func updateSaveCount(for brew: CoffeeBrew, incrementValue: Int) async {
        guard let brewID = brew.id else { return }
        let brewRef = db.collection("coffeeBrews").document(brewID)
        
        do {
            // Update Firestore: increment the saveCount field
            try await brewRef.updateData([
                "saveCount": FieldValue.increment(Int64(incrementValue))
            ])
            
            // Also update our local arrays for real-time UI reflection
            // 1) Update coffeeBrews
            if let index = coffeeBrews.firstIndex(where: { $0.id == brewID }) {
                coffeeBrews[index].saveCount += incrementValue
            }
            
            // 2) Update userBrews
            if let index = userBrews.firstIndex(where: { $0.id == brewID }) {
                userBrews[index].saveCount += incrementValue
            }
        } catch {
            print("Error updating saveCount for brew \(brewID): \(error)")
        }
    }
    
    // ---------------------------------------
    // MARK: - Add Brew
    // ---------------------------------------
    func addBrew(_ brew: CoffeeBrew) async {
        do {
            try db.collection("coffeeBrews").addDocument(from: brew)
        } catch {
            print("Error adding brew: \(error)")
        }
    }
    
    // ---------------------------------------
    // MARK: - Get Creator Name
    // ---------------------------------------
    /// Returns the creator’s displayName from Firestore (or from the cache).
    func getCreatorName(for creatorId: String) async -> String {
        // Check cache first
        if let cached = userNameCache[creatorId] {
            return cached
        }
        do {
            let doc = try await db.collection("users").document(creatorId).getDocument()
            let user = try doc.data(as: UserProfile.self)
            if let displayName = user.displayName {
                userNameCache[creatorId] = displayName
                return displayName
            }
        } catch {
            print("Error fetching user profile for \(creatorId): \(error)")
        }
        return "Unknown"
    }
}
