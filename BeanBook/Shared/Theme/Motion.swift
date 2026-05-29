import SwiftUI

/// Motion tokens for the "Ritual" design language — the animation analogue of `Theme`.
///
/// Curves are constant (they don't theme). Apply them via `.motion(_:value:)`
/// (declarative) or `withMotion(_:reduceMotion:)` (imperative) so that
/// `accessibilityReduceMotion` is honored centrally. Never hardcode an animation
/// curve in a view — add or reuse a token here.
///
/// Sole exception: `BrewTimer`'s continuous progress rail uses a local
/// `.linear` synced to its `TimelineView` tick, which is not a discrete
/// state/value animation and is documented in `docs/design.md`.
enum Motion {
    /// Spatial moves between steps / screens / states, and the hero numeric count-up.
    static let transition: Animation = .snappy(duration: 0.32)

    /// Direct-manipulation feedback — steppers, pickers, selection pills, stars, press states, affordance fades.
    static let control: Animation = .snappy(duration: 0.2)

    /// Pure opacity appear/disappear with no spatial spring (toast, save overlay).
    static let fade: Animation = .easeOut(duration: 0.25)

    /// Discrete value-bar fill to a target (the dose↔yield ratio bar).
    static let fill: Animation = .easeOut(duration: 0.5)

    /// The single celebratory curve — the save-success checkmark.
    static let confirm: Animation = .spring(response: 0.4, dampingFraction: 0.6)
}

extension View {
    /// `.animation(_:value:)` that nils out under Reduce Motion — the only way
    /// declarative animation should be applied in this app.
    func motion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionAnimation(animation: animation, value: value))
    }
}

private struct MotionAnimation<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

/// Imperative companion to `.motion` for `withAnimation` call sites (button actions).
/// The caller supplies its own `accessibilityReduceMotion` environment value.
@MainActor
func withMotion<Result>(
    _ animation: Animation,
    reduceMotion: Bool,
    _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(reduceMotion ? nil : animation, body)
}

extension AnyTransition {
    /// Multi-step forward flow: slide+fade in from trailing, out to leading.
    static var stepForward: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }

    /// Toast: rise from the bottom with a fade.
    static var toastRise: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}
