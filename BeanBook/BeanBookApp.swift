import SwiftUI
import SwiftData

@main
struct BeanBookApp: App {
    let container: ModelContainer

    @State private var catalog = CatalogService()
    @State private var notifications = NotificationManager()
    @State private var pro: ProEntitlement
    @State private var location = LocationService()
    @State private var bagStore: BagStore
    @State private var brewStore: BrewStore
    @State private var brewPresetStore: BrewPresetStore

    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("paletteID") private var paletteIDRaw: String = PaletteID.forest.rawValue

    init() {
        let schema = Schema([Bag.self, Brew.self, BrewPreset.self])
        let config = ModelConfiguration(schema: schema)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        self.container = container

        let pro = ProEntitlement()
        self._pro = State(wrappedValue: pro)
        self._bagStore = State(wrappedValue: BagStore(context: container.mainContext, pro: pro))
        self._brewStore = State(wrappedValue: BrewStore(context: container.mainContext, pro: pro))
        self._brewPresetStore = State(wrappedValue: BrewPresetStore(context: container.mainContext, pro: pro))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(catalog)
                .environment(notifications)
                .environment(pro)
                .environment(location)
                .environment(bagStore)
                .environment(brewStore)
                .environment(brewPresetStore)
                .tint(Theme.accent)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .task {
                    if let id = PaletteID(rawValue: paletteIDRaw) {
                        themeStore.palette = Palette.with(id: id)
                    }
                    await pro.start()
                }
                .onChange(of: paletteIDRaw) { _, newRaw in
                    if let id = PaletteID(rawValue: newRaw) {
                        themeStore.palette = Palette.with(id: id)
                    }
                }
                .fullScreenCover(isPresented: .constant(!hasOnboarded)) {
                    OnboardingView { hasOnboarded = true }
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
        }
        .modelContainer(container)
    }
}
