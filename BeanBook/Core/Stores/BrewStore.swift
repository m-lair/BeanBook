import Foundation
import SwiftData

@MainActor
@Observable
final class BrewStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ brew: Brew) {
        context.insert(brew)
        try? context.save()
    }

    func delete(_ brew: Brew) {
        context.delete(brew)
        try? context.save()
    }

    func save() {
        try? context.save()
    }

    /// Most recent brew on a given bag with the same method, if any.
    func lastBrew(for bag: Bag, method: BrewMethod) -> Brew? {
        bag.brews
            .filter { $0.method == method }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
}
