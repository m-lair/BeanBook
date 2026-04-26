import SwiftUI
import SwiftData

/// Home — mirrors `C2Today` from the design.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Brew.createdAt, order: .reverse) private var brews: [Brew]
    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]

    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var showAllBrews = false

    private var openBags: [Bag] { bags }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if brews.isEmpty {
                TodayEmptyView { showAddSheet = true }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        topRow
                        hero
                        HairRule().padding(.horizontal, 24).padding(.top, 32)
                        lastLogged
                        if !openBags.isEmpty {
                            HairRule().padding(.horizontal, 24)
                            beansPreview
                        }
                        Spacer().frame(height: 120)
                    }
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .foregroundStyle(Theme.ink2)
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewBrewSheet()
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .sheet(isPresented: $showAllBrews) {
            NavigationStack { BrewListView() }
        }
        .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
        .navigationDestination(for: Bag.self) { BagDetailView(bag: $0) }
    }

    // MARK: - Sections

    private var topRow: some View {
        Eyebrow(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
    }

    private var hero: some View {
        let last = brews.first
        let lastBag = last?.bag
        let ratio = last?.ratio ?? 2.0
        let dose = last.map { Int($0.doseGrams) } ?? 18
        let yieldG = last.map { Int($0.yieldGrams) } ?? 36
        let time = last?.formattedTime ?? "30s"

        return VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Today", color: Theme.accent)

            Text("\(Text("\(last?.method.displayName ?? "Espresso"), like\nyesterday — but a touch ").foregroundStyle(Theme.ink))\(Text("finer.").italic().foregroundStyle(Theme.accent))")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1.0)
                .lineSpacing(2)
                .padding(.top, 14)

            Text(heroDescription(last: last, lastBag: lastBag))
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(3)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.top, Theme.p(20))

            VStack(alignment: .leading, spacing: 14) {
                BigRatio(
                    ratio: ratio,
                    size: 56,
                    sub: "\(dose)g · \(yieldG)g · \(time)",
                    alignment: .leading
                )
                RatioBar(ratio: ratio, height: 3)
                    .frame(maxWidth: 200)
            }
            .padding(.top, Theme.p(28))

            Button { showAddSheet = true } label: {
                HStack(spacing: 10) {
                    Text("Begin")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .buttonStyle(.primaryPill)
            .padding(.top, Theme.p(28))
        }
        .padding(.horizontal, 24)
    }

    private var lastLogged: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("Last logged")
                Spacer()
                Button("All") { showAllBrews = true }
                    .font(Theme.body(11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
            }
            .padding(.top, Theme.p(24))

            VStack(spacing: 0) {
                ForEach(Array(brews.prefix(3).enumerated()), id: \.element.id) { index, brew in
                    if index > 0 { HairRule() }
                    NavigationLink(value: brew) {
                        TodayBrewRow(brew: brew)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 24)
    }

    private var beansPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("Beans · \(openBags.count) open")
                Spacer()
                NavigationLink {
                    BagListView()
                } label: {
                    Text("All")
                        .font(Theme.body(11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.accent)
                        .textCase(.uppercase)
                }
            }
            .padding(.top, Theme.p(24))

            VStack(spacing: 0) {
                ForEach(Array(openBags.prefix(3).enumerated()), id: \.element.id) { index, bag in
                    if index > 0 { HairRule() }
                    NavigationLink(value: bag) {
                        TodayBagRow(bag: bag)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 24)
    }

    private func heroDescription(last: Brew?, lastBag: Bag?) -> String {
        guard let last else {
            return "Log your first brew below."
        }
        let bag = lastBag?.displayTitle ?? "Today's bag"
        let time = last.formattedTime
        guard let rating = last.rating, rating > 0 else {
            return "\(bag). Same dose, pulled \(time)."
        }
        let qual: String = {
            switch rating {
            case 5: "outstanding"
            case 4: "great"
            case 3: "solid"
            case 2: "fine"
            default: "off"
            }
        }()
        return "\(bag). Same dose, pulled \(time) — yesterday's was \(qual)."
    }
}

// MARK: - Rows

private struct TodayBrewRow: View {
    let brew: Brew

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(brew.method.displayName)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .tracking(-0.4)
                    .foregroundStyle(Theme.ink)
                Text(rowDetail)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(brew.formattedRatio)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
                if let r = brew.rating, r > 0 {
                    RatingDots(value: r, size: 5)
                }
            }
        }
        .padding(.vertical, 14)
        .contentShape(.rect)
    }

    private var rowDetail: String {
        let when = brew.createdAt.formatted(.relative(presentation: .numeric))
        if let bag = brew.bag?.brand, !bag.isEmpty {
            return "\(bag) · \(when)"
        }
        return when
    }
}

private struct TodayBagRow: View {
    let bag: Bag

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(bag.name.isEmpty ? bag.brand : bag.name)
                    .font(.system(size: 19, weight: .medium, design: .serif))
                    .tracking(-0.3)
                    .foregroundStyle(Theme.ink)
                Text(rowMeta)
                    .font(Theme.body(11.5))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(1)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(bag.roastLevel.swatch)
                .frame(width: 5, height: 30)
        }
        .padding(.vertical, 13)
        .contentShape(.rect)
    }

    private var rowMeta: String {
        var parts: [String] = []
        if !bag.brand.isEmpty && !bag.name.isEmpty { parts.append(bag.brand) }
        parts.append(bag.roastLevel.displayName)
        return parts.joined(separator: " · ")
    }
}

// MARK: - Empty state

struct TodayEmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .padding(.horizontal, 24)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(Text("Your\nfirst\n").foregroundStyle(Theme.ink))\(Text("brew.").foregroundStyle(Theme.accent))")
                    .font(.system(size: 44, weight: .medium, design: .serif))
                    .tracking(-1.4)

                Text("BeanBook is a quiet place to log what you brew. No streaks, no scoring — just the recipe and how it tasted.")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink2)
                    .lineSpacing(4)
                    .frame(maxWidth: 280, alignment: .leading)
                    .padding(.top, 28)

                Button(action: onAdd) {
                    HStack(spacing: 10) {
                        Text("Log a brew")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .buttonStyle(.accentPill)
                .padding(.top, 36)
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

