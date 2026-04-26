import SwiftUI

/// "Ritual" design language — quiet, editorial, hairline-ruled.
/// Tokens mirror `c2-theme.jsx` (forest accent · NY Serif + SF Pro · compact density).
enum Theme {
    // MARK: - Palette

    static let background = Color(hex: "FAFAF7")
    static let card = Color.white

    static let ink = Color(hex: "0F1110")
    static let ink2 = Color(hex: "6B6B66")
    static let ink3 = Color(hex: "A8A8A2")
    static let ink4 = Color(hex: "D8D5CD")
    static let rule = Color(hex: "E8E5DD")

    static let accent = Color(hex: "2D4A2B")        // forest
    static let accentSoft = Color(hex: "DFE7DD")
    static let accentGlow = Color(hex: "2D4A2B").opacity(0.22)

    // Semantic
    static let error = Color(hex: "B5293A")
    static let success = Color(hex: "5A7A3A")

    // Back-compat aliases (older feature code references these)
    static let onBackground = ink
    static let onBackgroundVariant = ink2
    static let surfaceLow = card
    static let surfaceHigh = accentSoft
    nonisolated static let surfaceBright = Color.white
    nonisolated static let primary = accent
    static let primaryContainer = accentSoft
    static let onPrimary = Color.white
    static let cardShadowColor = ink.opacity(0.05)

    /// Back-compat gradients — degraded to flat accent fills under the Ritual redesign.
    /// Kept so legacy call sites (BrewListView, MethodPicker, ShopView, etc.) still compile
    /// until each is restyled.
    static let heroGradient = LinearGradient(
        colors: [accent, accent.opacity(0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let softGradient = LinearGradient(
        colors: [accentSoft, accentSoft.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Type

    /// Display: ui-serif (New York on iOS).
    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Body: SF Pro (system default).
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    // MARK: - Density (compact)

    /// Compact density multiplier — matches the JSX prototype's locked default.
    static let density: CGFloat = 0.78
    static func p(_ n: CGFloat) -> CGFloat { (n * density).rounded() }

    // MARK: - Spacing

    static let cardRadius: CGFloat = 14
    static let cardPadding: CGFloat = 18
    static let screenPadding: CGFloat = 24
    static let cardSpacing: CGFloat = 14
    static let itemSpacing: CGFloat = 10

    static let pillRadius: CGFloat = 100

    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 4

    static let iconSize: CGFloat = 22
    static let iconContainerSize: CGFloat = 36
}
