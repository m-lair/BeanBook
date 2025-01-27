//
//  CoffeeBagManager.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/25/25.
//

import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

@Observable
class CoffeeBagManager {
    var bags: [CoffeeBag] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func fetchCoffeeBags() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("coffeeBags")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            self.bags = snapshot.documents.compactMap {
                try? $0.data(as: CoffeeBag.self)
            }
        } catch {
            print("error fetching coffee bags: \(error)")
        }
    }

    func addBag(_ bag: CoffeeBag) async throws -> String {
        let docRef = try db.collection("coffeeBags").addDocument(from: bag)
        return docRef.documentID
    }

    func updateBag(_ bag: CoffeeBag) {
        guard let bagId = bag.id else { return }
        do {
            try db.collection("coffeeBags").document(bagId)
                .setData(from: bag, merge: true)
        } catch {
            print("Error updating bag: \(error)")
        }
    }

    func deleteBag(_ bag: CoffeeBag) {
        guard let bagId = bag.id else { return }
        db.collection("coffeeBags").document(bagId)
            .delete { error in
                if let error = error {
                    print("Error deleting bag: \(error)")
                }
            }
    }
}
