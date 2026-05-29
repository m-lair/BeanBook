# Motion Cohesion Pass - Design

**Date:** 2026-05-29
**Scope:** Unify the app's scattered animation curves into a small `Motion` token set, route every animation through a reduce-motion-aware application layer, and migrate existing call sites. No new motion is added — this is a refinement-and-consistency pass that keeps the restrained "paper, not glass" philosophy intact.

## Goal

The prominent animations in BeanBook are good individually but speak slightly different dialects. The same conceptual motion (a step transition) is written three ways (`.snappy(0.32)`, `.snappy(0.3)`, `.snappy(0.35)`), and reduce-motion compliance is handled per-site, so some prominent moments respect it and others silently don't.

Make the motion vocabulary coherent and enforceable — the way color already is via `Theme.*` — and make reduce-motion compliance structural rather than something each call site must remember. The app should look almost identical after this change; it should simply be internally consistent and correct.

## Non-goals

- **No new animated moments.** This is the "refine, stay restrained" direction, not "fill the dead spots."
  - Tab switching keeps the system default. No custom tab transition.
  - The paywall keeps the default sheet presentation. No entrance animation.
  - `TodayView` gets no hero/entrance/staggered-card motion.
- No change to haptics. `.sensoryFeedback` is governed by system haptic settings, not reduce-motion, and stays as-is.
- No new animation *types* (no `.phaseAnimator` choreography beyond what exists, no matched-geometry, no keyframes).
- No motion on type beyond what already exists (the doc's "no motion for type" rule stands; `.numericText` on the ratio readout remains the sanctioned exception).
- No formatter/linter to enforce the new rule mechanically. Enforcement is documentation + review, consistent with the current color-token approach. (Promoting this to a lint rule is a known-harness-gap follow-up, not part of this change.)

## Motion token set

A new namespace mirroring `Theme`. Curves are constant (they don't theme), so they are `nonisolated static let`, the same pattern `Theme` uses for spacing/type.

Four semantic tokens replace the eight ad-hoc values in use today:

| Token | Curve | Replaces | Used for |
|---|---|---|---|
| `Motion.transition` | `.snappy(duration: 0.32)` | `.snappy(0.32)`, `.snappy(0.3)`, `.snappy(0.35)`, toast `.easeOut(0.35)` | State / step / screen moves, numeric count-ups, toast in/out |
| `Motion.control` | `.snappy(duration: 0.2)` | `.snappy(0.2)`, star `.easeOut(0.2)` | Quick interactive control feedback — pickers, selection pills, stars |
| `Motion.confirm` | `.spring(response: 0.4, dampingFraction: 0.6)` | existing save spring | The single celebratory curve — save-success checkmark |
| `Motion.fill` | `.easeOut(duration: 0.4)` | `.easeOut(0.5)`, `.easeOut(0.3)` | Continuous progress / value-bar fills — ratio bar, timer rail |

Deliberate consolidations to call out:

- The ratio count-up moves from `.snappy(0.35)` to `Motion.transition` (`0.32`).
- `StarRating` moves from `.easeOut(0.2)` to `Motion.control` (`.snappy(0.2)`) — a curve-family change so control feedback reads as one family.
- The ratio bar (`0.5`) and timer rail (`0.3`) both become `Motion.fill` (`0.4`) — splitting the difference so fills share one rate.

These are intentional, sub-perceptual changes in service of coherence; each will be eyeballed in the simulator during implementation.

## Application layer

The reason gaps exist today is that every call site independently decides whether to honor reduce-motion. The fix is to make that decision live in one place.

### Declarative — `.motion(_:value:)`

A `View` extension backed by a `ViewModifier` that reads `@Environment(\.accessibilityReduceMotion)` and nils the animation when it is on:

```swift
extension View {
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
```

Call sites change from `.animation(.snappy(0.32), value: step)` to `.motion(Motion.transition, value: step)` and get reduce-motion compliance for free.

### Imperative — `withMotion(_:reduceMotion:_:)`

`withAnimation` runs inside button actions, where there is no view modifier to host the environment read. A free function takes the flag explicitly (the calling view already has `@Environment(\.accessibilityReduceMotion)`):

```swift
@MainActor
func withMotion<R>(_ animation: Animation, reduceMotion: Bool, _ body: () -> R) -> R {
    withAnimation(reduceMotion ? nil : animation, body)
}
```

Call sites change from `withAnimation(.snappy(0.32)) { step += 1 }` to `withMotion(Motion.transition, reduceMotion: reduceMotion) { step += 1 }`.

### Transitions

Key insight: **a `.transition(...)` does not animate without a driving animation.** When the driving `.motion`/`withMotion` nils out under reduce-motion, the associated transition is applied instantly (the view appears/disappears with no interpolation) — which is exactly the desired reduce-motion behavior. So transitions need no per-site reduce-motion branching; correctness flows from the animation layer.

The two reused transitions become named `AnyTransition` tokens for consistency and discoverability:

```swift
extension AnyTransition {
    static var stepForward: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }
    static var toastRise: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}
```

### File placement

Tokens, the two helpers, and the `AnyTransition` extensions live together in `BeanBook/Shared/Theme/Motion.swift`, next to `Palette.swift`. One file, one concern: the motion system.

## Migration

Route these call sites through the tokens + application layer. Reduce-motion gaps close as a side effect of using `.motion`/`withMotion`.

| File | Change |
|---|---|
| `NewBrewSheet.swift` | Step `.animation`/`withAnimation` (lines ~127, 148, 167, 190, 219, 518) → `.motion`/`withMotion(Motion.transition)`; this closes the step-transition reduce-motion gap. Save spring (~484) → `withMotion(Motion.confirm, …)`. `.transition` (~119) → `.stepForward`. |
| `OnboardingView.swift` | Step transition (~47, 128) → `Motion.transition` + `.stepForward`. |
| `BigRatio.swift` | Count-up (~47) → `withMotion(Motion.transition, …)`; `RatioBar` (~71) → `.motion(Motion.fill, value: ratio)`. |
| `BrewTimer.swift` | Rail fill (~71, 152) → `Motion.fill`; label transition → `Motion.transition`; **gate the continuous phase-pulse behind reduce-motion** (a looping pulse is precisely what reduce-motion should stop). |
| `ShopView.swift` | Toast in/out (~75, 306, 314) → `Motion.transition` + `.toastRise` via `.motion`/`withMotion`; closes the toast reduce-motion gap. |
| `NewBagSheet.swift` | Level / process control state (~406, 458) → `.motion(Motion.control, …)`; closes their reduce-motion gap. |
| `MethodPicker.swift` | Selection (~11) → `Motion.control`; closes its reduce-motion gap. |
| `StarRating.swift` | Rating change (~19) → `Motion.control`; closes its reduce-motion gap (and unifies the curve family). |

Line numbers are current-state hints, not contracts; the implementer should grep for the actual animation calls.

## Documentation

`docs/design.md` "Motion" section is rewritten to:

- List the four `Motion` tokens and their semantic use (replacing the current prose that names only two curves).
- State the rule: **never hardcode an animation curve — use a `Motion.*` token, applied via `.motion`/`withMotion` so reduce-motion is automatic.** This mirrors the existing "never hardcode a color" rule.
- Keep the existing "no motion for type" guidance and the `.numericText` exception.
- Replace the manual `.transition(reduceMotion ? .identity : .opacity)` example with the new pattern, and explain that transitions degrade to instant automatically when driven by `.motion`/`withMotion`.

`docs/quality.md`: no new invariant is mandated, but the "Theme access goes through `Theme.*`" invariant gets a sibling sentence noting animation goes through `Motion.*`. (Optional, low-risk; include if it reads naturally.)

CLAUDE.md's Motion bullet under "Conventions"/architecture summary is checked and updated if it names specific curves.

## Testing

Automated:

- SwiftUI animation timing is not meaningfully unit-testable, and there is no snapshot harness. A test asserting token constants exist is low value (the compiler already guarantees that) and is **not** included.
- `./scripts/agent-verify.sh build` must pass — this is the real automated gate for a compile-level refactor.
- `./scripts/agent-verify.sh test` runs to confirm no regression in existing suites.

Manual (the meaningful verification for motion):

- With **Reduce Motion OFF**, exercise the brew flow (Context → Shot → Outcome → Save), the Shop toast, the ratio count-up, the timer, and the pickers — motion should look essentially as before.
- With **Reduce Motion ON** (Settings → Accessibility → Motion), repeat the same flows — every transition should be instant, the timer phase-pulse should not loop, and nothing should visibly slide. Capture a before/after with the simulator's `record_sim_video` for sign-off.
- Confirm haptics still fire in both modes (they are independent of reduce-motion).

This is a "shared behavior" change touching navigation-adjacent transitions, so it sits at verification ladder rung 2–5 (compile, tests, manual smoke).

## Risks

- **Sub-perceptual curve changes accumulate into a "feels different" result.** Mitigation: the consolidations are small (0.30/0.35 → 0.32; 0.30/0.50 → 0.40), and each migrated screen is eyeballed in-sim. If `Motion.fill` at 0.4 reads wrong on the timer rail specifically, that one is the most likely to need a second token — accept a 5th token only if a real visual conflict appears, not preemptively.
- **`withMotion` threading `reduceMotion` is easy to forget at a new call site.** Mitigation: the declarative `.motion` modifier (no flag needed) is the default; `withMotion` is only for imperative button-action paths, which are few. The doc rule names both.
- **The phase-pulse gating could disable a cue some users rely on.** Mitigation: reduce-motion is an explicit user opt-out of exactly this kind of looping motion; the timer's numeric readout still updates, so no information is lost.
- **Scope creep toward "fill the dead spots."** Mitigation: tab/paywall/Today are listed as explicit non-goals; reviewer should reject any new animated moment in this change.
