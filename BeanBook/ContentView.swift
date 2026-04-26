import SwiftUI

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Bag.self, Brew.self, BrewPreset.self], inMemory: true)
        .environment(CatalogService())
}
