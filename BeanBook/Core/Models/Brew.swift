import Foundation
import SwiftData

@Model
final class Brew {
    #Index<Brew>([\.createdAt], [\.method])

    var method: BrewMethod = BrewMethod.espresso
    var doseGrams: Double = 0
    var yieldGrams: Double = 0
    var brewTimeSeconds: Int = 0
    var grindSetting: String?
    var waterTempC: Double?
    var rating: Int?
    var notes: String?
    var imageData: Data?
    var createdAt: Date = Date()

    var bag: Bag?

    init(
        method: BrewMethod = .espresso,
        doseGrams: Double = 0,
        yieldGrams: Double = 0,
        brewTimeSeconds: Int = 0,
        grindSetting: String? = nil,
        waterTempC: Double? = nil,
        rating: Int? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        bag: Bag? = nil,
        createdAt: Date = Date()
    ) {
        self.method = method
        self.doseGrams = doseGrams
        self.yieldGrams = yieldGrams
        self.brewTimeSeconds = brewTimeSeconds
        self.grindSetting = grindSetting
        self.waterTempC = waterTempC
        self.rating = rating
        self.notes = notes
        self.imageData = imageData
        self.bag = bag
        self.createdAt = createdAt
    }

    /// Yield-to-dose ratio (e.g. 2.0 for a 1:2 espresso).
    var ratio: Double {
        guard doseGrams > 0 else { return 0 }
        return yieldGrams / doseGrams
    }

    var formattedRatio: String {
        guard ratio > 0 else { return "—" }
        return "1:\(ratio.formatted(.number.precision(.fractionLength(2))))"
    }

    var formattedTime: String {
        let s = brewTimeSeconds
        if s < 60 {
            return "\(s)s"
        }
        if s < 3600 {
            return Duration.seconds(s).formatted(.time(pattern: .minuteSecond))
        }
        return Duration.seconds(s).formatted(.time(pattern: .hourMinute))
    }
}
