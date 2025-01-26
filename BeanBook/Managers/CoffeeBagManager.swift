//
//  CoffeeBagManager.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/25/25.
//


import FirebaseFirestore
import FirebaseFirestore

@Observable
class CoffeeBagManager {
    var bags: [CoffeeBag] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        stopListening() // Remove any previous listener

        listener = db.collection("coffeeBags")
            .order(by: "dateAdded", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening to coffeeBags: \(error)")
                    return
                }
                self.bags = snapshot?.documents.compactMap {
                    try? $0.data(as: CoffeeBag.self)
                } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addBag(_ bag: CoffeeBag) {
        do {
            _ = try db.collection("coffeeBags").addDocument(from: bag)
        } catch {
            print("Error adding bag: \(error)")
        }
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
