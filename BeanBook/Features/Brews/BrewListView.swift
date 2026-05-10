import SwiftUI
import SwiftData

/// "All brews" — destination of the Today screen's "All" link. Editorial list,
/// rule-separated rows; no toolbar Settings button (Settings now lives on Today).
struct BrewListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Brew.createdAt, order: .reverse) private var brews: [Brew]
    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]

    @State private var showAddSheet = false
    @State private var showRecipes = false
    @State private var hotStartBrew: Brew?
    @State private var methodFilter: BrewMethod? = nil
    @State private var bagFilter: Bag? = nil
    @State private var searchText = ""
    @Namespace private var addSheetNamespace

    private var recentBrews: [Brew] { Array(brews.prefix(5)) }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmedSearch.isEmpty }

    private var filteredBrews: [Brew] {
        let needle = trimmedSearch.lowercased()
        return brews.filter { brew in
            if let methodFilter, brew.method != methodFilter { return false }
            if let bagFilter, brew.bag?.persistentModelID != bagFilter.persistentModelID { return false }
            if !needle.isEmpty, !matches(brew, needle: needle) { return false }
            return true
        }
    }

    /// Case-insensitive substring match across the fields a user is most likely
    /// to remember a brew by: notes, the bag's brand/name/tasting-notes, the
    /// method's display name, and the grind setting.
    private func matches(_ brew: Brew, needle: String) -> Bool {
        if let notes = brew.notes, notes.lowercased().contains(needle) { return true }
        if brew.method.displayName.lowercased().contains(needle) { return true }
        if let grind = brew.grindSetting, grind.lowercased().contains(needle) { return true }
        if let bag = brew.bag {
            if bag.brand.lowercased().contains(needle) { return true }
            if bag.name.lowercased().contains(needle) { return true }
            if bag.origin.lowercased().contains(needle) { return true }
            if bag.tastingNotes.contains(where: { $0.lowercased().contains(needle) }) { return true }
        }
        return false
    }

    /// Distinct bags referenced by any brew, in most-recent-brew order.
    /// Used to populate the bag-filter chip row — filtering by a bag with
    /// no logged brews would always yield zero matches.
    private var bagsInBrews: [Bag] {
        var seen = Set<PersistentIdentifier>()
        var result: [Bag] = []
        for brew in brews {
            guard let bag = brew.bag else { continue }
            if seen.insert(bag.persistentModelID).inserted {
                result.append(bag)
            }
        }
        return result
    }

    private var hasActiveFilter: Bool { methodFilter != nil || bagFilter != nil || isSearching }
    private var showsFilters: Bool { brews.count >= 5 }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if brews.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        if !isSearching, recentBrews.count > 1 {
                            RecentShotsStrip(brews: recentBrews) { brew in
                                hotStartBrew = brew
                            }
                            .padding(.top, 24)
                        }
                        if !isSearching, !presets.isEmpty {
                            savedRecipesEntry
                                .padding(.horizontal, 24)
                                .padding(.top, recentBrews.count > 1 ? 22 : 24)
                        }
                        if !isSearching, showsFilters {
                            filterChips
                                .padding(.top, 28)
                        }
                        if filteredBrews.isEmpty {
                            filteredEmptyState
                        } else {
                            list
                        }
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search notes, bag, method, grind"
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Theme.accent)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(Theme.ink)
                .matchedTransitionSource(id: "addBrew", in: addSheetNamespace)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewBrewSheet()
                .navigationTransition(.zoom(sourceID: "addBrew", in: addSheetNamespace))
        }
        .sheet(isPresented: $showRecipes) {
            NavigationStack { RecipesView() }
        }
        .sheet(item: $hotStartBrew) { brew in
            NewBrewSheet(prefill: brew)
        }
        .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
        .navigationDestination(for: Bag.self) { BagDetailView(bag: $0) }
        .onChange(of: brews.count) { _, newCount in
            if newCount < 5 {
                methodFilter = nil
                bagFilter = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(headerCountLabel)
            Text("Brews")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 24)
    }

    private var headerCountLabel: String {
        if hasActiveFilter {
            return "\(filteredBrews.count) of \(brews.count)"
        }
        return "\(brews.count) logged"
    }

    private var savedRecipesEntry: some View {
        Button {
            showRecipes = true
        } label: {
            VStack(spacing: 0) {
                HairRule()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow("\(presets.count) saved")
                        Text("Saved recipes")
                            .font(.system(size: 22, weight: .medium, design: .serif))
                            .tracking(-0.4)
                            .foregroundStyle(Theme.ink)
                        Text("Repeat what worked.")
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.ink2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.ink3)
                }
                .padding(.vertical, 16)
                HairRule()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredBrews.enumerated()), id: \.element.id) { _, brew in
                NavigationLink(value: brew) {
                    BrewListRow(brew: brew)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        hotStartBrew = brew
                    } label: {
                        Label("Brew again", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, showsFilters ? 16 : 28)
    }

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All methods",
                        symbol: nil,
                        selected: methodFilter == nil
                    ) { methodFilter = nil }

                    ForEach(BrewMethod.allCases) { method in
                        FilterChip(
                            label: method.displayName,
                            symbol: method.symbol,
                            selected: methodFilter == method
                        ) {
                            methodFilter = (methodFilter == method) ? nil : method
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            if bagsInBrews.count >= 2 {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "All bags",
                            symbol: nil,
                            selected: bagFilter == nil
                        ) { bagFilter = nil }

                        ForEach(bagsInBrews, id: \.persistentModelID) { bag in
                            FilterChip(
                                label: bagChipLabel(for: bag),
                                symbol: nil,
                                selected: bagFilter?.persistentModelID == bag.persistentModelID
                            ) {
                                bagFilter = (bagFilter?.persistentModelID == bag.persistentModelID) ? nil : bag
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    /// Compact bag chip label — prefer brand, fall back to name, then "Untitled".
    private func bagChipLabel(for bag: Bag) -> String {
        if !bag.brand.isEmpty { return bag.brand }
        if !bag.name.isEmpty { return bag.name }
        return "Untitled bag"
    }

    private var filteredEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isSearching ? "No matches for \u{201C}\(trimmedSearch)\u{201D}." : "No brews match.")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(Theme.ink)
            Button(isSearching && (methodFilter == nil && bagFilter == nil) ? "Clear search" : "Clear filters") {
                methodFilter = nil
                bagFilter = nil
                searchText = ""
            }
            .buttonStyle(.outlinePill)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(Text("No\n").foregroundStyle(Theme.ink))\(Text("brews yet.").foregroundStyle(Theme.accent))")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
            Text("Log your first brew to start dialing in your recipes.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(3)
                .frame(maxWidth: 280, alignment: .leading)
            Button("Log a brew") { showAddSheet = true }
                .buttonStyle(.primaryPill)
                .padding(.top, 16)
        }
        .padding(.horizontal, 32)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Filter chip styled to match `RoastChip` (the catalog filter row).
/// Optional leading SF Symbol used by the BrewMethod filter row.
private struct FilterChip: View {
    let label: String
    let symbol: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(label)
                    .font(Theme.body(11, weight: .semibold))
                    .tracking(0.6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(selected ? .white : Theme.ink2)
            .background(selected ? Theme.accent : Theme.card, in: .capsule)
            .overlay(Capsule().stroke(selected ? .clear : Theme.rule, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct BrewListRow: View {
    let brew: Brew

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(brew.method.displayName)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .tracking(-0.4)
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    RatioText(brew.ratio)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                    if let r = brew.rating, r > 0 {
                        RatingDots(value: r, size: 5)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .contentShape(.rect)
    }

    private var detail: String {
        let bag = brew.bag?.brand ?? "—"
        let date = brew.createdAt.formatted(.relative(presentation: .numeric))
        return "\(bag) · \(date)"
    }
}
