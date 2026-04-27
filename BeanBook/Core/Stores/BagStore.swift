import Foundation
import SwiftData

@MainActor
@Observable
final class BagStore {
    private let context: ModelContext
    private let pro: ProEntitlementProviding

    init(context: ModelContext, pro: ProEntitlementProviding) {
        self.context = context
        self.pro = pro
    }

    var count: Int {
        (try? context.fetchCount(FetchDescriptor<Bag>())) ?? 0
    }

    @discardableResult
    func create(
        brand: String = "",
        name: String = "",
        roastLevel: RoastLevel = .medium,
        origin: String = "",
        process: ProcessMethod? = nil,
        tastingNotes: [String] = [],
        roastedOn: Date? = nil,
        notes: String? = nil,
        imageData: Data? = nil
    ) throws -> Bag {
        guard pro.canUse(.bag, currentCount: count) else {
            throw QuotaExceededError(feature: .bag, quota: ProQuota.bags)
        }
        let bag = Bag(
            brand: brand,
            name: name,
            roastLevel: roastLevel,
            origin: origin,
            process: process,
            tastingNotes: tastingNotes,
            roastedOn: roastedOn,
            imageData: imageData,
            notes: notes
        )
        context.insert(bag)
        try? context.save()
        return bag
    }
}
