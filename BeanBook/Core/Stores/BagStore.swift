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
        do {
            try context.save()
        } catch {
            context.delete(bag)
            throw error
        }
        return bag
    }

    /// Pinned bag (if any). Single-pin invariant enforced by `pin(_:)`.
    var pinnedBag: Bag? {
        var descriptor = FetchDescriptor<Bag>(predicate: #Predicate { $0.isPinned })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Pin a bag, unpinning all others. Pass the same bag again to unpin.
    func pin(_ bag: Bag) {
        let shouldUnpin = bag.isPinned
        let all = (try? context.fetch(FetchDescriptor<Bag>(predicate: #Predicate { $0.isPinned }))) ?? []
        for b in all where b.id != bag.id {
            b.isPinned = false
        }
        bag.isPinned = !shouldUnpin
        try? context.save()
    }
}
