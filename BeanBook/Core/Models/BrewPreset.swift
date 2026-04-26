import Foundation
import SwiftData

@Model
final class BrewPreset {
    var name: String = ""
    var method: BrewMethod = BrewMethod.espresso
    var doseGrams: Double = 0
    var yieldGrams: Double = 0
    var brewTimeSeconds: Int = 0
    var grindSetting: String?
    var waterTempC: Double?
    var createdAt: Date = Date()

    init(
        name: String = "",
        method: BrewMethod = .espresso,
        doseGrams: Double = 0,
        yieldGrams: Double = 0,
        brewTimeSeconds: Int = 0,
        grindSetting: String? = nil,
        waterTempC: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.name = name
        self.method = method
        self.doseGrams = doseGrams
        self.yieldGrams = yieldGrams
        self.brewTimeSeconds = brewTimeSeconds
        self.grindSetting = grindSetting
        self.waterTempC = waterTempC
        self.createdAt = createdAt
    }
}
