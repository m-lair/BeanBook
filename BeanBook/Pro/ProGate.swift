import SwiftUI

/// Free-tier quotas. Pro removes them entirely.
enum ProQuota {
    static let bags = 15
    static let brews = 50
    static let recipes = 3
}

/// Features that can be gated behind Pro.
enum ProFeature {
    case bag
    case brew
    case recipe
}

extension ProEntitlement {
    /// Returns true if the user can perform the action given their current
    /// item count. Pro users always pass.
    func canUse(_ feature: ProFeature, currentCount: Int) -> Bool {
        if isPro { return true }
        switch feature {
        case .bag:    return currentCount < ProQuota.bags
        case .brew:   return currentCount < ProQuota.brews
        case .recipe: return currentCount < ProQuota.recipes
        }
    }

    /// Free-tier quota for a feature, or nil if unlimited.
    func quota(for feature: ProFeature) -> Int? {
        guard !isPro else { return nil }
        switch feature {
        case .bag:    return ProQuota.bags
        case .brew:   return ProQuota.brews
        case .recipe: return ProQuota.recipes
        }
    }
}
