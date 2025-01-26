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
    var createdAt: Date = Date()

    init(
        id: String? = nil,
        brandName: String,
        roastLevel: String,
        origin: String
    ) {
        self.id = id
        self.brandName = brandName
        self.roastLevel = roastLevel
        self.origin = origin
    }
}
