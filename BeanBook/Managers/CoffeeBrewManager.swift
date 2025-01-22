//
//  CoffeeBrewViewModel.swift
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
    
    func fetchBrews() async {
        do {
            let snapshot = try await db.collection("coffeeBrews").getDocuments()
            self.coffeeBrews = snapshot.documents.compactMap { doc in
                try? doc.data(as: CoffeeBrew.self)
            }
        } catch {
            print("Error fetching coffee brews: \(error)")
        }
    }
    
    // Fetch the current user’s brews
    func fetchUserBrews(for uid: String) async {
        do {
            let snapshot = try await db.collection("coffeeBrews")
                .whereField("creatorId", isEqualTo: uid)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            self.userBrews = snapshot.documents.compactMap { doc in
                try? doc.data(as: CoffeeBrew.self)
            }
        } catch {
            print("Error fetching user brews: \(error)")
        }
    }
    
    func addBrew(_ brew: CoffeeBrew) async {
        let db = Firestore.firestore()
        do {
            try db.collection("coffeeBrews").addDocument(from: brew)
        } catch {
            print("Error adding brew: \(error)")
        }
    }
}
