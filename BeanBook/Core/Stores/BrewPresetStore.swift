import Foundation
import SwiftData

@MainActor
@Observable
final class BrewPresetStore {
    private let context: ModelContext
    private let pro: ProEntitlementProviding

    init(context: ModelContext, pro: ProEntitlementProviding) {
        self.context = context
        self.pro = pro
    }

    var count: Int {
        (try? context.fetchCount(FetchDescriptor<BrewPreset>())) ?? 0
    }

    @discardableResult
    func create(
        name: String,
        method: BrewMethod,
        doseGrams: Double,
        yieldGrams: Double,
        brewTimeSeconds: Int,
        grindSetting: String? = nil,
        waterTempC: Double? = nil
    ) throws -> BrewPreset {
        guard pro.canUse(.recipe, currentCount: count) else {
            throw QuotaExceededError(feature: .recipe, quota: ProQuota.recipes)
        }
        let preset = BrewPreset(
            name: name,
            method: method,
            doseGrams: doseGrams,
            yieldGrams: yieldGrams,
            brewTimeSeconds: brewTimeSeconds,
            grindSetting: grindSetting,
            waterTempC: waterTempC
        )
        context.insert(preset)
        try? context.save()
        return preset
    }
}
