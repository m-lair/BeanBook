import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Brews", systemImage: "cup.and.saucer.fill") {
                NavigationStack { BrewListView() }
            }
            Tab("Bags", systemImage: "bag.fill") {
                NavigationStack { BagListView() }
            }
            Tab("Shop", systemImage: "sparkles") {
                NavigationStack { ShopView() }
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Bag.self, Brew.self, BrewPreset.self], inMemory: true)
        .environment(CatalogService())
}
