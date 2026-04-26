import Foundation
import SwiftData

@MainActor
@Observable
final class BagStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ bag: Bag) {
        context.insert(bag)
        try? context.save()
    }

    func delete(_ bag: Bag) {
        context.delete(bag)
        try? context.save()
    }

    func save() {
        try? context.save()
    }

    /// Imports a catalog entry as a new local Bag.
    @discardableResult
    func `import`(from catalogBean: CatalogBean) -> Bag {
        let bag = Bag(
            brand: catalogBean.roaster,
            name: catalogBean.name,
            roastLevel: catalogBean.roastLevel,
            origin: catalogBean.origin,
            process: catalogBean.process,
            tastingNotes: catalogBean.tastingNotes,
            notes: catalogBean.description
        )
        add(bag)
        return bag
    }
}
