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
                BagListEmptyState { showAddSheet = true }
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
                Button("Add bag", systemImage: "plus") { showAddSheet = true }
                    .matchedTransitionSource(id: "addBag", in: addSheetNamespace)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewBagSheet()
                .navigationTransition(.zoom(sourceID: "addBag", in: addSheetNamespace))
        }
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let bag = context.model(for: id) as? Bag {
                BagDetailView(bag: bag)
            }
        }
    }
}

private struct BagListEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No bags yet", systemImage: "bag")
        } description: {
            Text("Track the beans you're brewing — origin, roast, tasting notes.")
        } actions: {
            Button("Add a bag", action: onAdd)
                .buttonStyle(.gradient)
        }
    }
}

private struct BagRow: View {
    let bag: Bag

    @State private var thumbnail: UIImage?

    private var metaLine: String {
        var parts: [String] = []
        if !bag.origin.isEmpty { parts.append(bag.origin) }
        parts.append(bag.roastLevel.displayName)
        if let process = bag.process { parts.append(process.displayName) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.softGradient)
                        .frame(width: 56, height: 56)
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(.rect(cornerRadius: 14))
                    } else {
                        Image(systemName: "bag.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.primary)
                    }
                }
                .accessibilityHidden(true)

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
                        Text("^[\(bag.brews.count) brew](inflect: true)")
                            .font(.caption)
                            .foregroundStyle(Theme.primary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.onBackgroundVariant.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .task(id: bag.imageData) {
            thumbnail = bag.imageData.flatMap(UIImage.init(data:))
        }
    }
}
