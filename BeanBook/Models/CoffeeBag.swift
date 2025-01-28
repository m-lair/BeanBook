//
//  CoffeeBag.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/25/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct CoffeeBag: Identifiable, Codable {
    @DocumentID var id: String?
    var brandName: String
    var roastLevel: String
    var origin: String
    var userName: String // user that added the bag
    var userId: String
    var location: String?
    var createdAt: Date = Date()

    init(
        id: String? = nil,
        brandName: String,
        roastLevel: String,
        userName: String,
        userId: String,
        location: String,
        origin: String
    ) {
        self.id = id
        self.brandName = brandName
        self.roastLevel = roastLevel
        self.userName = userName
        self.userId = userId
        self.location = location
        self.origin = origin
    }
}
