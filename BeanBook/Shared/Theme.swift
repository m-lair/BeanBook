import SwiftUI

/// "Ritual" design language — quiet, editorial, hairline-ruled.
///
/// Color tokens resolve through `themeStore.palette` so views automatically
/// re-render when the active palette changes. Non-color tokens (fonts,
/// spacing, radii) are constants — they don't theme.
@MainActor
enum Theme {
    // MARK: - Palette-backed color tokens

    static var background: Color { themeStore.palette.background }
    static var card: Color { themeStore.palette.card }

    static var ink: Color { themeStore.palette.ink }
    static var ink2: Color { themeStore.palette.ink2 }
    static var ink3: Color { themeStore.palette.ink3 }
    static var ink4: Color { themeStore.palette.ink4 }
    static var rule: Color { themeStore.palette.rule }

    static var accent: Color { themeStore.palette.accent }
    static var accentSoft: Color { themeStore.palette.accentSoft }
    static var accentGlow: Color { themeStore.palette.accentGlow }

    static var error: Color { themeStore.palette.error }
    static var success: Color { themeStore.palette.success }

    // Back-compat aliases (older feature code).
    static var onBackground: Color { ink }
    static var onBackgroundVariant: Color { ink2 }
    static var surfaceLow: Color { card }
    static var surfaceHigh: Color { accentSoft }
    static var primary: Color { accent }
    static var primaryContainer: Color { accentSoft }
    static var cardShadowColor: Color { ink.opacity(0.05) }

    // Truly constant — fine to evaluate without MainActor.
    nonisolated static let surfaceBright: Color = .white
    nonisolated static let onPrimary: Color = .white

    /// Back-compat gradients — degraded to flat accent fills under the Ritual redesign.
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    static var softGradient: LinearGradient {
        LinearGradient(
            colors: [accentSoft, accentSoft.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Type (constant, no theming)

    nonisolated static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    nonisolated static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    // MARK: - Density (compact)

    nonisolated static let density: CGFloat = 0.78
    nonisolated static func p(_ n: CGFloat) -> CGFloat { (n * density).rounded() }

    // MARK: - Spacing

    nonisolated static let cardRadius: CGFloat = 14
    nonisolated static let cardPadding: CGFloat = 18
    nonisolated static let screenPadding: CGFloat = 24
    nonisolated static let cardSpacing: CGFloat = 14
    nonisolated static let itemSpacing: CGFloat = 10

    nonisolated static let pillRadius: CGFloat = 100

    nonisolated static let cardShadowRadius: CGFloat = 12
    nonisolated static let cardShadowY: CGFloat = 4

    nonisolated static let iconSize: CGFloat = 22
    nonisolated static let iconContainerSize: CGFloat = 36
}
