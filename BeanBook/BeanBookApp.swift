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
    @State private var pro = ProEntitlement()
    @State private var location = LocationService()

    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(catalog)
                .environment(notifications)
                .environment(pro)
                .environment(location)
                .tint(Theme.accent)
                .preferredColorScheme(.light)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .task { await pro.start() }
                .fullScreenCover(isPresented: .constant(!hasOnboarded)) {
                    OnboardingView { hasOnboarded = true }
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
        }
        .modelContainer(container)
    }
}
