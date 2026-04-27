import Foundation
import SwiftData
import Testing
@testable import BeanBook

@MainActor
private final class StubProEntitlement: ProEntitlementProviding {
    var isPro: Bool
    init(isPro: Bool) { self.isPro = isPro }
}

@MainActor
private func makeContext() throws -> ModelContext {
    let schema = Schema([Bag.self, Brew.self, BrewPreset.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return ModelContext(container)
}

// MARK: - Bags

@Suite("Bag quota gating")
@MainActor
struct BagQuotaTests {
    @Test("free tier blocks the 16th bag")
    func freeTierBlocksOverCap() throws {
        let context = try makeContext()
        let pro = StubProEntitlement(isPro: false)
        let store = BagStore(context: context, pro: pro)

        for i in 0..<ProQuota.bags {
            #expect(throws: Never.self) {
                try store.create(brand: "Roaster \(i)")
            }
        }
        #expect(store.count == ProQuota.bags)

        do {
            _ = try store.create(brand: "One too many")
            Issue.record("Expected QuotaExceededError")
        } catch let error as QuotaExceededError {
            #expect(error.feature == .bag)
            #expect(error.quota == ProQuota.bags)
        }
    }

    @Test("pro tier creates past the cap (the unlimited promise)")
    func proTierUnlimited() throws {
        let context = try makeContext()
        let pro = StubProEntitlement(isPro: true)
        let store = BagStore(context: context, pro: pro)

        let target = ProQuota.bags + 5
        for i in 0..<target {
            #expect(throws: Never.self) {
                try store.create(brand: "Roaster \(i)")
            }
        }
        #expect(store.count == target)
    }

    @Test("flipping pro on mid-session unblocks further creates")
    func flippingProOnUnblocks() throws {
        let context = try makeContext()
        let pro = StubProEntitlement(isPro: false)
        let store = BagStore(context: context, pro: pro)

        for i in 0..<ProQuota.bags {
            try store.create(brand: "R\(i)")
        }
        #expect(throws: QuotaExceededError.self) {
            try store.create(brand: "blocked")
        }

        pro.isPro = true
        #expect(throws: Never.self) {
            try store.create(brand: "now allowed")
        }
        #expect(store.count == ProQuota.bags + 1)
    }
}

// MARK: - Brews

@Suite("Brew quota gating")
@MainActor
struct BrewQuotaTests {
    @Test("free tier blocks past 50 brews")
    func freeTierBlocksOverCap() throws {
        let context = try makeContext()
        let pro = StubProEntitlement(isPro: false)
        let store = BrewStore(context: context, pro: pro)

        for _ in 0..<ProQuota.brews {
            try store.create(method: .espresso, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 30)
        }

        do {
            _ = try store.create(method: .espresso, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 30)
            Issue.record("Expected QuotaExceededError")
        } catch let error as QuotaExceededError {
            #expect(error.feature == .brew)
            #expect(error.quota == ProQuota.brews)
        }
    }

    @Test("pro tier creates past the cap")
    func proTierUnlimited() throws {
        let context = try makeContext()
        let pro = StubProEntitlement(isPro: true)
        let store = BrewStore(context: context, pro: pro)

        let target = ProQuota.brews + 3
        for _ in 0..<target {
            try store.create(method: .espresso, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 30)
        }
        #expect(store.count == target)
    }
}

// MARK: - Presets

@Suite("Recipe quota gating")
@MainActor
struct RecipeQuotaTests {
    @Test("free tier blocks the 4th preset")
    func freeTierBlocksOverCap() throws {
        let context = try makeContext()
        let pro = StubProEntitlement(isPro: false)
        let store = BrewPresetStore(context: context, pro: pro)

        for i in 0..<ProQuota.recipes {
            try store.create(name: "r\(i)", method: .pourOver, doseGrams: 15, yieldGrams: 250, brewTimeSeconds: 180)
        }

        do {
            _ = try store.create(name: "blocked", method: .pourOver, doseGrams: 15, yieldGrams: 250, brewTimeSeconds: 180)
            Issue.record("Expected QuotaExceededError")
        } catch let error as QuotaExceededError {
            #expect(error.feature == .recipe)
            #expect(error.quota == ProQuota.recipes)
        }
    }

    @Test("pro tier creates past the cap")
    func proTierUnlimited() throws {
        let context = try makeContext()
        let pro = StubProEntitlement(isPro: true)
        let store = BrewPresetStore(context: context, pro: pro)

        let target = ProQuota.recipes + 5
        for i in 0..<target {
            try store.create(name: "r\(i)", method: .pourOver, doseGrams: 15, yieldGrams: 250, brewTimeSeconds: 180)
        }
        #expect(store.count == target)
    }
}
