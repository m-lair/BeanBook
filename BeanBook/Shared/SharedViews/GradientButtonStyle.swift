import SwiftUI

/// Solid ink pill — primary action (e.g. "Begin", "Brew this again").
struct PrimaryPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(15, weight: .medium))
            .foregroundStyle(Theme.background)
            .padding(.horizontal, 26)
            .padding(.vertical, 15)
            .background(Theme.ink, in: .capsule)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

/// Forest accent pill with soft glow — top-of-funnel CTA (e.g. onboarding "Start brewing").
struct AccentPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(15, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 26)
            .padding(.vertical, 15)
            .background(Theme.accent, in: .capsule)
            .shadow(color: Theme.accentGlow, radius: 14, y: 8)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

/// Hairline outlined pill — secondary action ("Back", "Cancel").
struct OutlinePillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(15, weight: .medium))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Color.clear, in: .capsule)
            .overlay(Capsule().stroke(Theme.rule, lineWidth: 0.5))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PrimaryPillStyle {
    static var primaryPill: PrimaryPillStyle { PrimaryPillStyle() }
    /// Back-compat alias for old `.gradient` call sites.
    static var gradient: PrimaryPillStyle { PrimaryPillStyle() }
}

extension ButtonStyle where Self == AccentPillStyle {
    static var accentPill: AccentPillStyle { AccentPillStyle() }
}

extension ButtonStyle where Self == OutlinePillStyle {
    static var outlinePill: OutlinePillStyle { OutlinePillStyle() }
}
