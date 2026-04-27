import Foundation

/// Thrown by gated stores when a non-Pro user tries to create an item past
/// the free-tier cap. Carries the feature so the UI can present an
/// appropriate paywall headline.
struct QuotaExceededError: Error {
    let feature: ProFeature
    let quota: Int
}
