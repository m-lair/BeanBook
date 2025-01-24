//
//  CoffeeBrew.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import Foundation
import FirebaseFirestore

struct CoffeeBrew: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var method: String      // e.g. "Pour Over", "Espresso"
    var coffeeAmount: String
    var waterAmount: String
    var brewTime: String
    var grindSize: String
    var creatorName: String?
    var creatorId: String
    var createdAt: Date
    var notes: String?
    var imageURL: String?
    
    // For Swift or SwiftUI previews
    init(id: String? = nil,
         title: String,
         method: String,
         coffeeAmount: String,
         waterAmount: String,
         brewTime: String,
         grindSize: String,
         creatorName: String,
         creatorId: String,
         createdAt: Date = Date(),
         notes: String? = nil,
         imageURL: String? = nil
    )
    {
        self.id = id
        self.title = title
        self.method = method
        self.coffeeAmount = coffeeAmount
        self.waterAmount = waterAmount
        self.brewTime = brewTime
        self.grindSize = grindSize
        self.creatorName = creatorName
        self.creatorId = creatorId
        self.createdAt = createdAt
        self.notes = notes
        self.imageURL = imageURL
    }
}
