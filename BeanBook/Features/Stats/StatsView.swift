import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(ProEntitlement.self) private var pro
    @Query(sort: \Brew.createdAt, order: .reverse) private var brews: [Brew]
    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]
    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]

    @State private var showPaywall = false
    @State private var showAddBrew = false

    private var summary: StatsSummary {
        StatsSummary.build(brews: brews, bags: bags, presets: presets)
    }

    private var brewsByID: [PersistentIdentifier: Brew] {
        Dictionary(uniqueKeysWithValues: brews.map { ($0.persistentModelID, $0) })
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if !pro.isPro {
                lockedState
            } else if brews.isEmpty {
                noBrewsState
            } else if summary.isSparse {
                sparseState
            } else {
                populatedState
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(headline: "Stats are included with BeanBook Pro.")
        }
        .sheet(isPresented: $showAddBrew) {
            NewBrewSheet()
        }
        .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
    }

    private var lockedState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("BeanBook Pro")
                    .padding(.top, 12)

                Text("Stats")
                    .font(.system(size: 42, weight: .medium, design: .serif))
                    .tracking(-1.2)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 28)

                Text("Stats are included with BeanBook Pro - a one-time purchase that also unlocks unlimited bags and exports.")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink2)
                    .lineSpacing(4)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, 12)

                Eyebrow("What you get")
                    .padding(.top, 32)

                VStack(spacing: 0) {
                    StatsProFeatureRow(number: "01", title: "Overview", detail: "Total brews, active bags, favorite method, average rating.")
                    StatsProFeatureRow(number: "02", title: "What's working", detail: "Highest-rated brews, your best bag, best saved recipe.")
                    StatsProFeatureRow(number: "03", title: "By bag", detail: "Brew count, average rating, common ratio, last brewed.")
                    StatsProFeatureRow(number: "04", title: "Dial-in", detail: "Espresso shot history with grind and rating changes.", showsRule: false)
                }
                .padding(.top, 16)

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        Text("Unlock Pro once")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .buttonStyle(.accentPill)
                .padding(.top, 36)

                Text("One-time purchase. No subscription. Family Sharing supported.")
                    .font(Theme.body(12, weight: .medium))
                    .foregroundStyle(Theme.ink2)
                    .padding(.top, 16)

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var noBrewsState: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Stats")
                .padding(.top, 12)

            Text("\(Text("Nothing\nto show\n").foregroundStyle(Theme.ink))\(Text("yet.").foregroundStyle(Theme.accent))")
                .font(.system(size: 42, weight: .medium, design: .serif))
                .tracking(-1.2)
                .lineSpacing(1)
                .padding(.top, 56)

            Text("Log your first brew and patterns will start to appear here - what's working, by bag, dial-in.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(4)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.top, 28)

            Button {
                showAddBrew = true
            } label: {
                HStack(spacing: 10) {
                    Text("Log a brew")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .buttonStyle(.accentPill)
            .padding(.top, 36)

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sparseState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                statsHeader
                StatsOverviewGrid(summary: summary)
                    .padding(.top, 28)

                StatsEmptyCard(
                    eyebrow: "Patterns",
                    title: "More patterns appear as you log.",
                    detail: "What's working, by-bag breakdowns, and dial-in trends start showing once you have a handful of brews on each bag."
                )
                .padding(.top, 24)

                if !summary.loggedSoFar.isEmpty {
                    statsSectionHeader("Logged so far")
                        .padding(.top, 28)
                    VStack(spacing: 0) {
                        ForEach(summary.loggedSoFar) { row in
                            brewRowLink(for: row)
                        }
                    }
                }

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var populatedState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                statsHeader
                StatsOverviewGrid(summary: summary)
                    .padding(.top, 28)

                BrewActivityStrip(days: summary.dailyCounts, total: summary.totalBrews)
                    .padding(.top, 30)

                if hasWorkingContent {
                    statsSectionHeader("What's working")
                        .padding(.top, 30)
                    VStack(spacing: 0) {
                        ForEach(summary.workingBrews) { row in
                            brewRowLink(for: row)
                        }
                        if let bestBag = summary.bestBag {
                            StatsBagRow(summary: bestBag, label: "Best bag")
                        }
                        if let bestRecipeName = summary.bestRecipeName {
                            StatsInfoRow(title: "Best recipe", detail: bestRecipeName, value: "Saved")
                        }
                    }
                }

                if !summary.bagSummaries.isEmpty {
                    statsSectionHeader("By bag")
                        .padding(.top, 30)
                    VStack(spacing: 0) {
                        ForEach(summary.bagSummaries) { bag in
                            StatsBagRow(summary: bag)
                        }
                    }
                }

                if !summary.dialInRows.isEmpty {
                    statsSectionHeader(dialInTitle)
                        .padding(.top, 30)
                    VStack(spacing: 0) {
                        ForEach(summary.dialInRows) { row in
                            StatsDialInRow(row: row)
                        }
                    }
                }

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Eyebrow(statsEyebrow)
                Spacer()
                Text("Pro")
                    .font(Theme.body(10, weight: .semibold))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.ink3)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.card, in: .capsule)
                    .overlay(Capsule().stroke(Theme.rule, lineWidth: 0.5))
            }

            Text("Stats")
                .font(.system(size: 42, weight: .medium, design: .serif))
                .tracking(-1.2)
                .foregroundStyle(Theme.ink)

            if !summary.isSparse {
                Text("A quiet ledger of what you've brewed and what's been working.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink2)
                    .lineSpacing(3)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }

    private var statsEyebrow: String {
        if summary.totalBrews <= 0 {
            return "Stats"
        }
        let start = summary.windowStart.formatted(.dateTime.month(.abbreviated).day())
        let dayCount = Calendar.current.dateComponents([.day], from: summary.windowStart, to: summary.windowEnd).day ?? 29
        return "\(dayCount + 1) days / since \(start)"
    }

    private var hasWorkingContent: Bool {
        !summary.workingBrews.isEmpty || summary.bestBag != nil || summary.bestRecipeName != nil
    }

    private var dialInTitle: String {
        if let title = summary.dialInBagTitle {
            return "Dial-in / \(title)"
        }
        return "Dial-in"
    }

    private func statsSectionHeader(_ title: String) -> some View {
        Eyebrow(title, color: Theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func brewRowLink(for row: StatsSummary.BrewRow) -> some View {
        if let brew = brewsByID[row.brewID] {
            NavigationLink(value: brew) {
                StatsBrewRow(row: row)
            }
            .buttonStyle(.plain)
        } else {
            StatsBrewRow(row: row)
        }
    }
}

private struct StatsOverviewGrid: View {
    let summary: StatsSummary

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
            StatsMetric(value: "\(summary.totalBrews)", label: "Total brews", caption: "this month")
            StatsMetric(value: "\(summary.activeBagCount)", label: "Active bags")
            StatsMetric(
                value: summary.favoriteMethod?.displayName ?? "-",
                label: "Favorite method",
                caption: summary.favoriteMethod == nil ? "more data needed" : nil
            )
            StatsMetric(
                value: averageRatingLabel,
                label: "Avg rating",
                caption: summary.averageRating == nil ? "rate a brew to see this" : "out of 5"
            )
        }
    }

    private var averageRatingLabel: String {
        guard let average = summary.averageRating else { return "-" }
        return average.formatted(.number.precision(.fractionLength(average.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))
    }
}

private struct StatsMetric: View {
    let value: String
    let label: String
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: value.count > 9 ? 22 : 30, weight: .medium, design: .serif))
                .tracking(-0.6)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Theme.ink)
            Eyebrow(label)
            if let caption {
                Text(caption)
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BrewActivityStrip: View {
    let days: [StatsSummary.DailyCount]
    let total: Int

    private var maxCount: Int {
        max(days.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Brews / last 30 days")
                    .font(Theme.body(12, weight: .medium))
                    .foregroundStyle(Theme.ink2)
                Spacer()
                Text("\(total) total")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.ink3)
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(day.count > 0 ? Theme.ink.opacity(0.82) : Theme.rule)
                        .frame(maxWidth: .infinity)
                        .frame(height: height(for: day.count))
                        .accessibilityLabel("\(day.count) brews")
                }
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.accent)
                    .frame(width: 6, height: 12)
                    .accessibilityHidden(true)
            }
            .frame(height: 44, alignment: .bottom)

            HStack {
                Text(days.first?.date.formatted(.dateTime.month(.abbreviated).day()).uppercased() ?? "")
                Spacer()
                Text("Today")
            }
            .font(Theme.body(10, weight: .semibold))
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(Theme.ink3)
        }
    }

    private func height(for count: Int) -> CGFloat {
        guard count > 0 else { return 2 }
        let scaled = CGFloat(count) / CGFloat(maxCount) * 42
        return min(max(scaled, 4), 42)
    }
}

private struct StatsBrewRow: View {
    let row: StatsSummary.BrewRow

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .tracking(-0.4)
                        .foregroundStyle(Theme.ink)
                    Text(row.detail)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(row.ratioLabel)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                    if let rating = row.rating, rating > 0 {
                        RatingDots(value: rating, size: 5)
                    }
                }
            }
            .padding(.vertical, 15)
        }
    }
}

private struct StatsBagRow: View {
    let summary: StatsSummary.BagSummary
    var label: String?

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    if let label {
                        Eyebrow(label)
                    }
                    Text(summary.title)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .tracking(-0.4)
                        .foregroundStyle(Theme.ink)
                    Text("\(summary.brewCount) brews / \(summary.methodLabel)")
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(summary.ratioLabel)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.accent)
                    Text(ratingLabel)
                        .font(Theme.body(11, weight: .medium))
                        .foregroundStyle(Theme.ink3)
                }
            }
            .padding(.vertical, 15)
        }
    }

    private var ratingLabel: String {
        guard let average = summary.averageRating else { return "No ratings" }
        return "\(average.formatted(.number.precision(.fractionLength(average.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))) avg"
    }
}

private struct StatsDialInRow: View {
    let row: StatsSummary.DialInRow

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(row.detail)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Spacer()
                if let rating = row.rating, rating > 0 {
                    RatingDots(value: rating, size: 5)
                }
            }
            .padding(.vertical, 14)
        }
    }
}

private struct StatsInfoRow: View {
    let title: String
    let detail: String
    let value: String

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Spacer()
                Text(value)
                    .font(Theme.body(12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.vertical, 15)
        }
    }
}

private struct StatsProFeatureRow: View {
    let number: String
    let title: String
    let detail: String
    var showsRule = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 22) {
                Text(number)
                    .font(Theme.body(11, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
                    .frame(width: 28, alignment: .trailing)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .tracking(-0.2)
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.ink2)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            if showsRule {
                HairRule()
                    .padding(.leading, 50)
            }
        }
    }
}

private struct StatsEmptyCard: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(eyebrow)
            Text(title)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.rule, lineWidth: 0.5)
        )
    }
}
