import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var selection: TabSelection = .today
    @State private var previous: TabSelection = .today
    @State private var showAddBrew = false

    enum TabSelection: Hashable {
        case today, beans, recipes, add
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "cup.and.saucer.fill", value: TabSelection.today) {
                NavigationStack { TodayView() }
            }
            Tab("Beans", systemImage: "bag.fill", value: TabSelection.beans) {
                NavigationStack { BagListView() }
            }
            Tab("Recipes", systemImage: "list.bullet", value: TabSelection.recipes) {
                NavigationStack { RecipesView() }
            }
            Tab(value: TabSelection.add, role: .search) {
                Color.clear
            } label: {
                Label("Log brew", systemImage: "plus")
                    .foregroundStyle(Theme.accent)
                    .tint(Theme.accent)
            }
        }
        .tint(Theme.accent)
        .onChange(of: selection) { _, new in
            if new == .add {
                showAddBrew = true
                selection = previous
            } else {
                previous = new
            }
        }
        .sheet(isPresented: $showAddBrew) {
            NewBrewSheet()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Bag.self, Brew.self, BrewPreset.self], inMemory: true)
        .environment(CatalogService())
}
