import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "cup.and.saucer.fill") {
                NavigationStack { TodayView() }
            }
            Tab("Beans", systemImage: "bag.fill") {
                NavigationStack { BagListView() }
            }
            Tab("Recipes", systemImage: "list.bullet") {
                NavigationStack { RecipesView() }
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Bag.self, Brew.self, BrewPreset.self], inMemory: true)
        .environment(CatalogService())
}
