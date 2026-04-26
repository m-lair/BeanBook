import Foundation
import SwiftData

@Model
final class Bag {
    #Index<Bag>([\.createdAt])

    var brand: String = ""
    var name: String = ""
    var roastLevel: RoastLevel = RoastLevel.medium
    var origin: String = ""
    var process: ProcessMethod?
    var tastingNotes: [String] = []
    var roastedOn: Date?
    var purchasedAt: Date?
    var imageData: Data?
    var notes: String?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Brew.bag)
    var brews: [Brew] = []

    init(
        brand: String = "",
        name: String = "",
        roastLevel: RoastLevel = .medium,
        origin: String = "",
        process: ProcessMethod? = nil,
        tastingNotes: [String] = [],
        roastedOn: Date? = nil,
        purchasedAt: Date? = nil,
        imageData: Data? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.brand = brand
        self.name = name
        self.roastLevel = roastLevel
        self.origin = origin
        self.process = process
        self.tastingNotes = tastingNotes
        self.roastedOn = roastedOn
        self.purchasedAt = purchasedAt
        self.imageData = imageData
        self.notes = notes
        self.createdAt = createdAt
    }

    var displayTitle: String {
        if !name.isEmpty && !brand.isEmpty {
            return "\(brand) — \(name)"
        }
        if !brand.isEmpty { return brand }
        if !name.isEmpty { return name }
        return "Untitled bag"
    }
}
