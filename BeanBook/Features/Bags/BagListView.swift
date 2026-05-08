import SwiftUI
import SwiftData

/// "The shelf" — bag list. Color-stripe rows, big serif title, fold-in Discover entry.
struct BagListView: View {
    @Environment(\.modelContext) private var context
    @Environment(BagStore.self) private var bagStore
    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]

    @State private var showAddSheet = false
    @State private var showDiscover = false
    @State private var roastFilter: RoastLevel? = nil
    @Namespace private var addSheetNamespace

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if bags.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        filterRow
                        list
                        discoverLink
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(Theme.ink)
                .matchedTransitionSource(id: "addBag", in: addSheetNamespace)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewBagSheet()
        }
        .sheet(isPresented: $showDiscover) {
            NavigationStack { ShopView(showsDoneButton: true) }
        }
        .navigationDestination(for: Bag.self) { BagDetailView(bag: $0) }
        .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Beans · \(bags.count) open")

            Text("The shelf")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 24)
    }

    private var sortedBags: [Bag] {
        let filtered = roastFilter.map { level in bags.filter { $0.roastLevel == level } } ?? bags
        return filtered.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private var filterRow: some View {
        RoastFilterRow(selection: $roastFilter)
            .padding(.horizontal, 24)
            .padding(.top, 24)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(sortedBags) { bag in
                NavigationLink(value: bag) {
                    BagShelfRow(bag: bag)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        bagStore.pin(bag)
                    } label: {
                        Label(
                            bag.isPinned ? "Unpin" : "Pin as default",
                            systemImage: bag.isPinned ? "pin.slash" : "pin"
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    private var discoverLink: some View {
        Button {
            showDiscover = true
        } label: {
            VStack(spacing: 0) {
                HairRule()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow("Discover", color: Theme.accent)
                        Text("Curated roasters")
                            .font(.system(size: 18, weight: .medium, design: .serif))
                            .tracking(-0.3)
                            .foregroundStyle(Theme.ink)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.vertical, 18)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow("Beans")
                .padding(.bottom, 32)
            Text("\(Text("The shelf is\n").foregroundStyle(Theme.ink))\(Text("empty.").foregroundStyle(Theme.accent))")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
            Text("Add a bag to track origin, roast date, and tasting notes. Linked to your brews automatically.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(3)
                .frame(maxWidth: 280, alignment: .leading)
                .padding(.top, 8)
            Button("Add a bag") { showAddSheet = true }
                .buttonStyle(.accentPill)
                .matchedTransitionSource(id: "addBag", in: addSheetNamespace)
                .padding(.top, 16)
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct BagShelfRow: View {
    let bag: Bag

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(bag.roastLevel.swatch)
                    .frame(width: 8)
                    .frame(minHeight: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Eyebrow(bag.brand.isEmpty ? "Bag" : bag.brand)
                        if bag.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    Text(bag.name.isEmpty ? "Untitled" : bag.name)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .tracking(-0.5)
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 1)
                    if !bag.tastingNotes.isEmpty {
                        Text(bag.tastingNotes.prefix(3).joined(separator: " · "))
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.ink2)
                            .lineLimit(1)
                            .padding(.top, 1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(bag.brews.count) brews")
                        .font(Theme.body(11))
                        .foregroundStyle(Theme.ink3)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.ink3)
                }
            }
            .padding(.vertical, 18)
        }
        .contentShape(.rect)
    }
}
