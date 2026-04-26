import SwiftUI

enum Theme {
    // MARK: - Core Palette

    /// Warm cream — page background
    static let background = Color(hex: "FAF6F0")
    /// Espresso brown — primary text
    static let onBackground = Color(hex: "2A1A10")
    /// Muted secondary text
    static let onBackgroundVariant = Color(hex: "7A5A45")

    // MARK: - Surface Tiers

    static let surfaceLow = Color.white
    static let surfaceHigh = Color(hex: "F0E4D6")
    nonisolated static let surfaceBright = Color.white

    // MARK: - Accent (warm caramel / roasted coffee)

    nonisolated static let primary = Color(hex: "A8682A")
    static let primaryContainer = Color(hex: "E6C39A")
    static let onPrimary = Color.white

    /// Hero gradient — caramel through cream
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "5C2E14"), Color(hex: "A8682A"), Color(hex: "D9A86A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle gradient for secondary cards
    static let softGradient = LinearGradient(
        colors: [primaryContainer.opacity(0.35), primaryContainer.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Semantic

    static let error = Color(hex: "B5293A")
    static let success = Color(hex: "5A7A3A")

    // MARK: - Spacing

    static let cardRadius: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let screenPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
    static let itemSpacing: CGFloat = 12

    // MARK: - Icon

    static let iconSize: CGFloat = 44
    static let iconContainerSize: CGFloat = 52

    // MARK: - Shadow

    static let cardShadowColor = Color(hex: "2A1A10").opacity(0.06)
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 4

    // MARK: - Pills

    static let pillRadius: CGFloat = 100
}
