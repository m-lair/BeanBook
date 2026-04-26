import SwiftUI
import SwiftData

struct BagListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]

    @State private var showAddSheet = false
    @Namespace private var addSheetNamespace

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if bags.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.cardSpacing) {
                        ForEach(bags) { bag in
                            NavigationLink(value: bag.persistentModelID) {
                                BagRow(bag: bag)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.screenPadding)
                }
            }
        }
        .navigationTitle("Bags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .matchedTransitionSource(id: "addBag", in: addSheetNamespace)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewBagSheet()
                .navigationTransition(.zoom(sourceID: "addBag", in: addSheetNamespace))
        }
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let bag = bags.first(where: { $0.persistentModelID == id }) {
                BagDetailView(bag: bag)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No bags yet", systemImage: "bag")
        } description: {
            Text("Track the beans you're brewing — origin, roast, tasting notes.")
        } actions: {
            Button("Add a bag") { showAddSheet = true }
                .buttonStyle(.gradient)
        }
    }
}

private struct BagRow: View {
    let bag: Bag

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.softGradient)
                        .frame(width: 56, height: 56)
                    if let data = bag.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Image(systemName: "bag.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(bag.displayTitle)
                        .font(.headline)
                        .foregroundStyle(Theme.onBackground)
                        .lineLimit(1)
                    Text(metaLine)
                        .font(.caption)
                        .foregroundStyle(Theme.onBackgroundVariant)
                        .lineLimit(1)
                    if !bag.brews.isEmpty {
                        Text("\(bag.brews.count) brew\(bag.brews.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(Theme.primary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.onBackgroundVariant.opacity(0.5))
            }
        }
    }

    private var metaLine: String {
        var parts: [String] = []
        if !bag.origin.isEmpty { parts.append(bag.origin) }
        parts.append(bag.roastLevel.displayName)
        if let process = bag.process { parts.append(process.displayName) }
        return parts.joined(separator: " · ")
    }
}
