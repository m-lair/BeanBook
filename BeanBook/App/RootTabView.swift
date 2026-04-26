import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var showAddBrew = false

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
        .tabViewBottomAccessory {
            Button {
                showAddBrew = true
            } label: {
                Label("Log brew", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Log brew")
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
