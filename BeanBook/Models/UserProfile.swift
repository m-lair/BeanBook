//
//  UserProfile.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import Foundation

struct UserProfile: Codable {
    var displayName: String?
    var email:String
    var photoURL: String?
    var createdAt: Date?
    var updatedAt: Date?
    var bio: String?
    var favorites: [String] = []
    
    init(
        displayName: String? = "nil",
        email: String,
        photoURL: String? = "nil",
        createdAt: Date? = Date(),
        updatedAt: Date? = nil,
        bio: String? = "nil",
        favorites: [String] = []
    ) {
        self.displayName = displayName
        self.bio = bio
        self.email = email
        self.createdAt = createdAt
        self.favorites = favorites
        self.photoURL = photoURL
        self.updatedAt = updatedAt
    }
}
