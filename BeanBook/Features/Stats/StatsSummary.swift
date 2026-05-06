import Foundation
import SwiftData

struct StatsSummary {
    struct DailyCount: Identifiable, Equatable {
        let id: Date
        let date: Date
        let count: Int
    }

    struct BagSummary: Identifiable, Equatable {
        let id: PersistentIdentifier
        let title: String
        let brewCount: Int
        let averageRating: Double?
        let lastBrewedAt: Date
        let methodLabel: String
        let ratioLabel: String
    }

    struct BrewRow: Identifiable, Equatable {
        let id: PersistentIdentifier
        let brewID: PersistentIdentifier
        let title: String
        let detail: String
        let ratioLabel: String
        let rating: Int?
        let createdAt: Date
    }

    struct DialInRow: Identifiable, Equatable {
        let id: PersistentIdentifier
        let brewID: PersistentIdentifier
        let detail: String
        let rating: Int?
        let createdAt: Date
    }

    let windowStart: Date
    let windowEnd: Date
    let totalBrews: Int
    let totalLifetimeBrews: Int
    let activeBagCount: Int
    let favoriteMethod: BrewMethod?
    let averageRating: Double?
    let dailyCounts: [DailyCount]
    let workingBrews: [BrewRow]
    let bestBag: BagSummary?
    let bestRecipeName: String?
    let bagSummaries: [BagSummary]
    let dialInBagTitle: String?
    let dialInRows: [DialInRow]
    let loggedSoFar: [BrewRow]

    var isSparse: Bool { totalBrews < 3 }
}

extension StatsSummary {
    static func build(
        brews: [Brew],
        bags: [Bag],
        presets: [BrewPreset],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> StatsSummary {
        let end = now
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
        let sorted = brews.sorted { $0.createdAt > $1.createdAt }
        let windowBrews = sorted.filter { $0.createdAt >= start && $0.createdAt <= end }
        let rated = windowBrews.compactMap(\.rating).filter { $0 > 0 }
        let activeBags = Set(windowBrews.compactMap { $0.bag?.persistentModelID })
        let dialInBag = dialInBag(from: sorted, bags: bags)

        return StatsSummary(
            windowStart: start,
            windowEnd: end,
            totalBrews: windowBrews.count,
            totalLifetimeBrews: brews.count,
            activeBagCount: activeBags.count,
            favoriteMethod: favoriteMethod(in: windowBrews),
            averageRating: average(rated.map(Double.init)),
            dailyCounts: dailyCounts(from: windowBrews, start: start, calendar: calendar),
            workingBrews: workingBrews(from: windowBrews),
            bestBag: bestBag(from: windowBrews),
            bestRecipeName: bestRecipeName(from: presets),
            bagSummaries: bagSummaries(from: windowBrews),
            dialInBagTitle: dialInBag?.displayTitle,
            dialInRows: dialInRows(from: sorted, bag: dialInBag),
            loggedSoFar: Array(sorted.prefix(5)).map(BrewRow.init)
        )
    }

    private static func favoriteMethod(in brews: [Brew]) -> BrewMethod? {
        guard brews.count >= 3 else { return nil }
        let counts = Dictionary(grouping: brews, by: \.method).mapValues(\.count)
        return counts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.displayName < rhs.key.displayName
            }
            return lhs.value > rhs.value
        }.first?.key
    }

    private static func dailyCounts(
        from brews: [Brew],
        start: Date,
        calendar: Calendar
    ) -> [DailyCount] {
        let grouped = Dictionary(grouping: brews) { calendar.startOfDay(for: $0.createdAt) }
        return (0..<30).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            return DailyCount(id: day, date: day, count: grouped[day, default: []].count)
        }
    }

    private static func workingBrews(from brews: [Brew]) -> [BrewRow] {
        brews
            .filter { ($0.rating ?? 0) > 0 }
            .sorted { lhs, rhs in
                if lhs.rating == rhs.rating {
                    return lhs.createdAt > rhs.createdAt
                }
                return (lhs.rating ?? 0) > (rhs.rating ?? 0)
            }
            .prefix(3)
            .map(BrewRow.init)
    }

    private static func bagSummaries(from brews: [Brew]) -> [BagSummary] {
        let grouped = Dictionary(grouping: brews.compactMap { brew -> (Bag, Brew)? in
            guard let bag = brew.bag else { return nil }
            return (bag, brew)
        }) { pair in
            pair.0.persistentModelID
        }

        return grouped.values.compactMap { pairs in
            guard let bag = pairs.first?.0 else { return nil }
            let bagBrews = pairs.map(\.1)
            return BagSummary(bag: bag, brews: bagBrews)
        }
        .sorted { lhs, rhs in
            lhs.lastBrewedAt > rhs.lastBrewedAt
        }
    }

    private static func bestBag(from brews: [Brew]) -> BagSummary? {
        bagSummaries(from: brews)
            .filter { $0.brewCount >= 3 && $0.averageRating != nil }
            .sorted { lhs, rhs in
                if lhs.averageRating == rhs.averageRating {
                    return lhs.brewCount > rhs.brewCount
                }
                return (lhs.averageRating ?? 0) > (rhs.averageRating ?? 0)
            }
            .first
    }

    private static func bestRecipeName(from presets: [BrewPreset]) -> String? {
        presets
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.name)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func dialInBag(from brews: [Brew], bags: [Bag]) -> Bag? {
        if let pinned = bags.first(where: \.isPinned) {
            return pinned
        }
        return brews.first?.bag
    }

    private static func dialInRows(from brews: [Brew], bag: Bag?) -> [DialInRow] {
        guard let bag else { return [] }
        return brews
            .filter { brew in
                brew.method == .espresso && brew.bag?.persistentModelID == bag.persistentModelID
            }
            .prefix(5)
            .map(DialInRow.init)
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let raw = values.reduce(0, +) / Double(values.count)
        return (raw * 10).rounded() / 10
    }
}

extension StatsSummary.BagSummary {
    init(bag: Bag, brews: [Brew]) {
        let sorted = brews.sorted { $0.createdAt > $1.createdAt }
        let rated = brews.compactMap(\.rating).filter { $0 > 0 }.map(Double.init)
        let methodCounts = Dictionary(grouping: brews, by: \.method).mapValues(\.count)
        let method = methodCounts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.displayName < rhs.key.displayName
            }
            return lhs.value > rhs.value
        }.first?.key

        self.id = bag.persistentModelID
        self.title = bag.displayTitle
        self.brewCount = brews.count
        self.averageRating = Self.average(rated)
        self.lastBrewedAt = sorted.first?.createdAt ?? bag.createdAt
        self.methodLabel = method?.displayName ?? "More data needed"
        self.ratioLabel = Self.averageRatio(from: brews)
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let raw = values.reduce(0, +) / Double(values.count)
        return (raw * 10).rounded() / 10
    }

    private static func averageRatio(from brews: [Brew]) -> String {
        let ratios = brews.map(\.ratio).filter { $0 > 0 }
        guard !ratios.isEmpty else { return "-" }
        let average = ratios.reduce(0, +) / Double(ratios.count)
        return "1:\(average.formatted(.number.precision(.fractionLength(2))))"
    }
}

extension StatsSummary.BrewRow {
    init(_ brew: Brew) {
        self.id = brew.persistentModelID
        self.brewID = brew.persistentModelID
        self.title = brew.method.displayName
        self.detail = Self.detail(for: brew)
        self.ratioLabel = brew.formattedRatio
        self.rating = brew.rating
        self.createdAt = brew.createdAt
    }

    private static func detail(for brew: Brew) -> String {
        let date = brew.createdAt.formatted(date: .abbreviated, time: .omitted)
        if let bag = brew.bag?.brand, !bag.isEmpty {
            return "\(bag) / \(date)"
        }
        return date
    }
}

extension StatsSummary.DialInRow {
    init(_ brew: Brew) {
        self.id = brew.persistentModelID
        self.brewID = brew.persistentModelID
        self.detail = Self.detail(for: brew)
        self.rating = brew.rating
        self.createdAt = brew.createdAt
    }

    private static func detail(for brew: Brew) -> String {
        var parts = [
            "\(Self.numeric(brew.doseGrams))g -> \(Self.numeric(brew.yieldGrams))g",
            brew.formattedTime
        ]
        if let grind = brew.grindSetting, !grind.isEmpty {
            parts.append(grind)
        }
        return parts.joined(separator: " / ")
    }

    private static func numeric(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}
