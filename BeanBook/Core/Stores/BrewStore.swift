import Foundation
import SwiftData

@MainActor
@Observable
final class BrewStore {
    private let context: ModelContext
    private let pro: ProEntitlementProviding

    init(context: ModelContext, pro: ProEntitlementProviding) {
        self.context = context
        self.pro = pro
    }

    var count: Int {
        (try? context.fetchCount(FetchDescriptor<Brew>())) ?? 0
    }

    @discardableResult
    func create(
        method: BrewMethod,
        doseGrams: Double,
        yieldGrams: Double,
        brewTimeSeconds: Int,
        grindSetting: String? = nil,
        waterTempC: Double? = nil,
        rating: Int? = nil,
        notes: String? = nil,
        bag: Bag? = nil
    ) throws -> Brew {
        guard pro.canUse(.brew, currentCount: count) else {
            throw QuotaExceededError(feature: .brew, quota: ProQuota.brews)
        }
        let brew = Brew(
            method: method,
            doseGrams: doseGrams,
            yieldGrams: yieldGrams,
            brewTimeSeconds: brewTimeSeconds,
            grindSetting: grindSetting,
            waterTempC: waterTempC,
            rating: rating,
            notes: notes,
            bag: bag
        )
        context.insert(brew)
        do {
            try context.save()
        } catch {
            context.delete(brew)
            throw error
        }
        return brew
    }

    /// Most recently logged brew, if any. Used for prefill defaults.
    func mostRecent() -> Brew? {
        var descriptor = FetchDescriptor<Brew>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
