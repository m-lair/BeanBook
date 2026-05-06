import Foundation
import SwiftData
import Testing
@testable import BeanBook

@Suite("Stats summary")
@MainActor
struct StatsSummaryTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSinceReferenceDate: 800_000)

    @Test("empty inputs produce empty summary")
    func emptyInputs() {
        let summary = StatsSummary.build(brews: [], bags: [], presets: [], now: now, calendar: calendar)

        #expect(summary.totalBrews == 0)
        #expect(summary.activeBagCount == 0)
        #expect(summary.favoriteMethod == nil)
        #expect(summary.averageRating == nil)
        #expect(summary.dailyCounts.count == 30)
        #expect(summary.isSparse)
        #expect(summary.bagSummaries.isEmpty)
        #expect(summary.dialInRows.isEmpty)
    }

    @Test("sparse summary keeps available values without claiming favorite method")
    func sparseInputs() {
        let bag = Bag(brand: "Onyx", name: "Geometry")
        let brew = Brew(method: .espresso, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 30, rating: 5, bag: bag, createdAt: now)
        bag.brews = [brew]

        let summary = StatsSummary.build(brews: [brew], bags: [bag], presets: [], now: now, calendar: calendar)

        #expect(summary.totalBrews == 1)
        #expect(summary.activeBagCount == 1)
        #expect(summary.favoriteMethod == nil)
        #expect(summary.averageRating == 5)
        #expect(summary.isSparse)
        #expect(summary.loggedSoFar.count == 1)
    }

    @Test("populated summary derives overview, bag summaries, and daily counts")
    func populatedInputs() {
        let bag = Bag(brand: "Onyx", name: "Geometry")
        let brews = (0..<5).map { index in
            Brew(
                method: .espresso,
                doseGrams: 18,
                yieldGrams: 36 + Double(index),
                brewTimeSeconds: 28 + index,
                rating: index == 0 ? 3 : 4,
                bag: bag,
                createdAt: calendar.date(byAdding: .day, value: -index, to: now)!
            )
        }
        bag.brews = brews

        let summary = StatsSummary.build(brews: brews, bags: [bag], presets: [], now: now, calendar: calendar)

        #expect(summary.totalBrews == 5)
        #expect(summary.activeBagCount == 1)
        #expect(summary.favoriteMethod == .espresso)
        #expect(summary.averageRating == 3.8)
        #expect(!summary.isSparse)
        #expect(summary.dailyCounts.reduce(0) { $0 + $1.count } == 5)
        #expect(summary.bagSummaries.first?.brewCount == 5)
        #expect(summary.dialInRows.count == 5)
    }

    @Test("unrated brews keep rating nil")
    func unratedInputs() {
        let brew = Brew(method: .pourOver, doseGrams: 20, yieldGrams: 320, brewTimeSeconds: 180, createdAt: now)
        let summary = StatsSummary.build(brews: [brew], bags: [], presets: [], now: now, calendar: calendar)

        #expect(summary.averageRating == nil)
    }

    @Test("pinned bag drives dial-in rows when present")
    func pinnedBagDrivesDialInRows() {
        let pinned = Bag(brand: "Sey", name: "A", isPinned: true)
        let recent = Bag(brand: "Onyx", name: "B")
        let pinnedBrew = Brew(method: .espresso, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 30, rating: 4, bag: pinned, createdAt: calendar.date(byAdding: .day, value: -2, to: now)!)
        let recentBrew = Brew(method: .espresso, doseGrams: 19, yieldGrams: 38, brewTimeSeconds: 31, rating: 5, bag: recent, createdAt: now)
        pinned.brews = [pinnedBrew]
        recent.brews = [recentBrew]

        let summary = StatsSummary.build(brews: [recentBrew, pinnedBrew], bags: [pinned, recent], presets: [], now: now, calendar: calendar)

        #expect(summary.dialInBagTitle == pinned.displayTitle)
        #expect(summary.dialInRows.map(\.brewID) == [pinnedBrew.persistentModelID])
    }
}
