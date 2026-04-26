import SwiftUI
import SwiftData

@main
struct BeanBookApp: App {
    let container: ModelContainer = {
        let schema = Schema([Bag.self, Brew.self, BrewPreset.self])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @State private var catalog = CatalogService()
    @State private var notifications = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(catalog)
                .environment(notifications)
                .tint(Theme.primary)
        }
        .modelContainer(container)
    }
}
