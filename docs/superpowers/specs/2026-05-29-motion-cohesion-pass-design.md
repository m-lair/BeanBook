# Motion Cohesion Pass - Design

**Date:** 2026-05-29
**Scope:** Unify the app's scattered animation curves into a small `Motion` token set, route every animation through a reduce-motion-aware application layer, and migrate existing call sites. No new motion is added — this is a refinement-and-consistency pass that keeps the restrained "paper, not glass" philosophy intact.

## Goal

The prominent animations in BeanBook are good individually but speak slightly different dialects. The same conceptual motion is written several ways — step transitions appear as `.snappy(0.32)`, `.snappy(0.3)`, and (the ratio count-up) `.snappy(0.35)`; direct-manipulation feedback ranges across `.snappy(0.25)`, `.snappy(0.2)`, `.snappy(0.18)`, a bare `.snappy`, and `.easeOut(0.2)`. Reduce-motion compliance is handled per-site, so some prominent moments respect it and others silently don't (the brew-flow step transitions and the timer's phase animations currently do not).

Make the motion vocabulary coherent and enforceable — the way color already is via `Theme.*` — and make reduce-motion compliance structural rather than something each call site must remember. The app should look almost identical after this change; it should simply be internally consistent and correct.

## Verified current-state inventory

Built from a direct grep of `BeanBook/` (not a summary). This is the authoritative set the migration is built on.

**Declarative `.animation(_:value:)`:**

| File:line | Curve | Driven by | Reduce-motion today |
|---|---|---|---|
| `NewBrewSheet:127` | `.snappy(0.32)` | `step` | ✗ unconditional |
| `NewBrewSheet:148` | `.snappy(0.32)` | `step` | ✗ unconditional |
| `NewBrewSheet:167` | `.snappy(0.3)` | `step` | ✗ unconditional |
| `NewBrewSheet:219` | `.snappy(0.3)` | `step` | ✗ unconditional |
| `NewBrewSheet:859` | `.snappy(0.18)` | `configuration.isPressed` (button-press style) | ✗ unconditional |
| `OnboardingView:52` | `.snappy(0.32)` | `step` | ✗ unconditional |
| `BrewTimer:38` | `.snappy(0.25)` | `phase` (eyebrow label) | ✗ unconditional |
| `BrewTimer:107` | `.snappy(0.25)` | `canReset` (reset-button fade) | ✗ unconditional |
| `BrewTimer:111` | `.snappy(0.3)` | `phase` (whole-timer layout reflow) | ✗ unconditional |
| `BrewTimer:152` | `.linear(0.1)` | `progress` (continuous rail fill) | ✓ gated |
| `NewBagSheet:406` | `.snappy(0.2)` | `level` | ✗ unconditional |
| `NewBagSheet:458` | `.snappy(0.2)` | `process` | ✗ unconditional |
| `StarRating:19` | `.easeOut(0.2)` | `rating` | ✗ unconditional |
| `BigRatio:71` | `.easeOut(0.5)` | `ratio` (RatioBar) | ✓ gated |

**Imperative `withAnimation(_:)`:**

| File:line | Curve | Effect | Reduce-motion today |
|---|---|---|---|
| `NewBrewSheet:190` | `.snappy(0.3)` | `step -= 1` (Back) | ✗ |
| `NewBrewSheet:518` | `.snappy(0.32)` | `step += 1` (advance) | ✗ |
| `NewBrewSheet:484` | `.spring(0.4/0.6)` | save checkmark scale-in | ✓ via `if reduceMotion` branch |
| `NewBrewSheet:572` | `.easeOut(0.25)` | `showSaved = true` (overlay) | ✗ |
| `NewBrewSheet:717/737/767/787` | `.snappy(0.25)` | stepper value changes (dose/yield/grind) | ✗ |
| `OnboardingView:128` | `.snappy(0.32)` | `step = 1` | ✗ |
| `BigRatio:47` | `.snappy(0.35)` | `displayRatio` count-up | ✓ via `if reduceMotion` branch |
| `MethodPicker:11` | `.snappy` (bare, ≈0.35 default) | `selection` change | ✗ |
| `ShopView:306` | `.easeOut(0.25)` | toast show | ✗ |
| `ShopView:314` | `.easeOut(0.25)` | toast hide | ✗ |

**`.transition(...)`** (degrade to instant automatically once the driving animation respects reduce-motion — see Application layer): `NewBrewSheet:119` (asymmetric step), `:162`, `:204`, `:501`; `OnboardingView:47` (already gated, asymmetric); `ShopView:75` (toast); `BrewTimer:77` (adjust pills).

**Out of inventory by design:** `.contentTransition(.numericText/.opacity)` calls are content transitions, not curves, and stay as-is. `TimelineView(.animation(...))` at `BrewTimer:40/141` are timeline *schedules*, not view animations. There is **no `.phaseAnimator`, no `repeatForever`, no looping/pulsing animation anywhere** — `BrewTimer.Phase` is a discrete enum `{idle, running, paused, finished}` and its `.animation(value: phase)` calls animate state changes; the live "ticking" is the `TimelineView` re-rendering the readout/rail.

## Motion token set

A new namespace mirroring `Theme`. Curves are constant (they don't theme), so they are `nonisolated static let`, the same pattern `Theme` uses for spacing/type. Five semantic tokens, grouped by the motion's *intent* (not by raw duration):

| Token | Curve | Used for | Replaces |
|---|---|---|---|
| `Motion.transition` | `.snappy(duration: 0.32)` | Spatial moves between steps/screens/states + the hero numeric count-up | step `.snappy(0.3/0.32)`, ratio count-up `.snappy(0.35)`, BrewTimer `phase` `.snappy(0.25/0.3)` |
| `Motion.control` | `.snappy(duration: 0.2)` | Direct-manipulation feedback — steppers, pickers, selection pills, stars, press state, affordance fades | `.snappy(0.25)` steppers, `.snappy(0.2)` pickers, `.snappy(0.18)` press, bare `.snappy` method pick, `.easeOut(0.2)` stars, BrewTimer `canReset` `.snappy(0.25)` |
| `Motion.fade` | `.easeOut(duration: 0.25)` | Pure opacity appear/disappear with no spatial spring | toast in/out `.easeOut(0.25)`, saved-overlay `.easeOut(0.25)` |
| `Motion.fill` | `.easeOut(duration: 0.5)` | Discrete value-bar fill to a target | ratio bar `.easeOut(0.5)` |
| `Motion.confirm` | `.spring(response: 0.4, dampingFraction: 0.6)` | The single celebratory curve — save-success checkmark | save spring (unchanged) |

### Why five, not four

The real distribution doesn't collapse cleanly into four without lossy remaps. Specifically:

- `fade` (easeOut) is kept distinct from `transition` (snappy) because three real sites — the toast and the saved overlay — use a non-spring opacity ramp; folding them into the snappy `transition` token would change their curve *family*. Keeping `fade` means those three sites change **not at all**.
- `confirm` and `fill` are each exact matches for their existing curves (`.spring(0.4/0.6)`, `.easeOut(0.5)`), so they cost nothing and earn their place by making "the celebration curve" and "the bar-fill curve" nameable.

This is a semantic grain, chosen from the inventory above — not a target count. We do **not** add a sixth token for the timer rail (see exemption); that would be a token for a single site (YAGNI).

### Honest perceptual deltas

Not every migration is invisible. Categorized:

- **Exact (zero change):** `Motion.fill` (0.5→0.5), `Motion.confirm` (spring unchanged), `Motion.fade` (0.25→0.25 for toast + overlay).
- **Sub-perceptual (<70 ms, same family):** `transition` absorbing step `0.3→0.32` and count-up `0.35→0.32`; `control` absorbing steppers `0.25→0.2` and press `0.18→0.2`.
- **Deliberate and noticeable — called out for sign-off:**
  - **MethodPicker** bare `.snappy` (≈0.35 default) → `control` `.snappy(0.2)`: method selection becomes clearly snappier. Intended improvement.
  - **StarRating** `.easeOut(0.2)` → `control` `.snappy(0.2)`: a curve-*family* change; the star fill gains a slight spring character so it reads as one family with other controls.
  - **BrewTimer** `phase` `.snappy(0.25/0.3)` → `transition` `.snappy(0.32)`: the eyebrow label and the timer's layout reflow on phase change get marginally slower (≤70 ms).

### Timer rail exemption

`BrewTimer:152` (`.linear(duration: 0.1)`, gated) stays as a local literal and is **not** migrated. It is a continuous live-tracking fill synced to the rail's `TimelineView(minimumInterval: 0.1)` tick — semantically unlike the discrete state/value animations the tokens cover. Easing it (e.g. to `Motion.fill`'s 0.5s easeOut) would make the bar visibly lag and ease behind each 0.1s tick. This is the single sanctioned non-token curve and is documented as such in `design.md`.

## Application layer

The reason gaps exist today is that every call site independently decides whether to honor reduce-motion (and most of the declarative sites simply don't). The fix is to make that decision live in one place.

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

Call sites change from `.animation(.snappy(0.32), value: step)` to `.motion(Motion.transition, value: step)` and get reduce-motion compliance for free — closing every "✗ unconditional" row in the inventory.

### Imperative — `withMotion(_:reduceMotion:_:)`

`withAnimation` runs inside button actions, where there is no view modifier to host the environment read. A free function takes the flag explicitly (the calling view already has, or will add, `@Environment(\.accessibilityReduceMotion)`):

```swift
@MainActor
func withMotion<R>(_ animation: Animation, reduceMotion: Bool, _ body: () -> R) -> R {
    withAnimation(reduceMotion ? nil : animation, body)
}
```

`withAnimation(nil) { x = final }` applies the change instantly, so this also subsumes the existing `if reduceMotion { x = final } else { withAnimation(...) { … } }` branches at `NewBrewSheet:484` and `BigRatio:47` — they collapse to one `withMotion(...)` call.

### Transitions

Key insight: **a `.transition(...)` does not animate without a driving animation.** When the driving `.motion`/`withMotion` nils out under reduce-motion, the associated transition is applied instantly (the view appears/disappears with no interpolation) — exactly the desired reduce-motion behavior. So transitions need no per-site reduce-motion branching, and the existing manual `reduceMotion ? .identity : …` ternaries (`NewBrewSheet:679`, `OnboardingView:47`) can be simplified to the plain transition.

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

Route these call sites through the tokens + application layer. Reduce-motion gaps close as a side effect of using `.motion`/`withMotion`. Line numbers are current-state hints — grep for the actual calls.

| File | Changes |
|---|---|
| `NewBrewSheet.swift` | `:127/:148/:167/:219` (`value: step`) → `.motion(Motion.transition, …)`. `:190/:518` (`withAnimation` step ±1) → `withMotion(Motion.transition, …)`. `:484` save spring → `withMotion(Motion.confirm, …)` (replaces the if/else branch). `:572` `showSaved` → `withMotion(Motion.fade, …)`. `:717/:737/:767/:787` steppers → `withMotion(Motion.control, …)`. `:859` press style → `.motion(Motion.control, value: configuration.isPressed)`. `:119` step transition → `.stepForward`. `:679` ternary → plain `.opacity`. (`:162/:204/:501` transitions left as-is; they degrade via the now-gated drivers.) |
| `OnboardingView.swift` | `:52` → `.motion(Motion.transition, …)`; `:128` → `withMotion(Motion.transition, …)`; `:47` → `.transition(.stepForward)` (drop the `reduceMotion ? .identity` ternary). |
| `BigRatio.swift` | `:47` count-up → `withMotion(Motion.transition, reduceMotion:)` (collapse if/else); `:71` RatioBar → `.motion(Motion.fill, value: ratio)`. |
| `BrewTimer.swift` | `:38` (eyebrow, `value: phase`) → `.motion(Motion.transition, …)`; `:111` (layout reflow, `value: phase`) → `.motion(Motion.transition, …)`; `:107` (`canReset`) → `.motion(Motion.control, …)`. **`:152` linear rail fill stays as-is (documented exemption).** Closing `:38/:107/:111` also makes the `:77` adjust-pill transition degrade correctly under reduce-motion. |
| `ShopView.swift` | Add `@Environment(\.accessibilityReduceMotion)`. `:306/:314` toast show/hide → `withMotion(Motion.fade, reduceMotion:)`; `:75` → `.transition(.toastRise)`. |
| `NewBagSheet.swift` | `:406` (`level`) and `:458` (`process`) → `.motion(Motion.control, …)`. |
| `MethodPicker.swift` | Add `@Environment(\.accessibilityReduceMotion)`. `:11` → `withMotion(Motion.control, reduceMotion:)` (also tightens bare `.snappy` ≈0.35 → 0.2). |
| `StarRating.swift` | `:19` → `.motion(Motion.control, value: rating)` (curve-family change easeOut → snappy). |

## Non-goals

- **No new animated moments.** This is the "refine, stay restrained" direction, not "fill the dead spots."
  - Tab switching keeps the system default. No custom tab transition.
  - The paywall keeps the default sheet presentation. No entrance animation.
  - `TodayView` gets no hero/entrance/staggered-card motion.
- No change to haptics. `.sensoryFeedback` is governed by system haptic settings, not reduce-motion, and stays as-is at every site.
- No new animation *types* (no `.phaseAnimator`, matched-geometry, or keyframes).
- No motion on type beyond what already exists; the doc's "no motion for type" rule stands, and `.numericText`/`.contentTransition` remain the sanctioned exceptions (left untouched).
- No sixth token for the timer rail, and no formatter/linter to enforce the rule mechanically — enforcement stays documentation + review, consistent with the existing color-token approach. (A lint rule is a known-harness-gap follow-up, not part of this change.)

## Documentation

`docs/design.md` "Motion" section is rewritten to:

- List the five `Motion` tokens and their semantic use (replacing the current prose that names only two curves).
- State the rule: **never hardcode an animation curve — use a `Motion.*` token, applied via `.motion`/`withMotion` so reduce-motion is automatic.** This mirrors the existing "never hardcode a color" rule.
- Document the single exception: the timer's continuous live-tracking rail uses a local `.linear` synced to its tick, not a token.
- Keep the existing "no motion for type" guidance and the `.numericText` exception.
- Replace the manual `.transition(reduceMotion ? .identity : .opacity)` example with the new pattern, and explain that transitions degrade to instant automatically when driven by `.motion`/`withMotion`.

`docs/quality.md`: the "Theme access goes through `Theme.*`" invariant gets a sibling sentence noting animation curves go through `Motion.*` (with the timer-rail exception). CLAUDE.md's Motion guidance is checked and updated if it names specific curves.

## Testing

Automated:

- SwiftUI animation timing is not meaningfully unit-testable, and there is no snapshot harness. A test asserting token constants exist is low value (the compiler already guarantees that) and is **not** included.
- `./scripts/agent-verify.sh build` must pass — the real automated gate for a compile-level refactor.
- `./scripts/agent-verify.sh test` runs to confirm no regression in existing suites.

Manual (the meaningful verification for motion), via the simulator with `record_sim_video`:

- **Reduce Motion OFF:** exercise the brew flow (Context → Shot → Outcome → Save), the Shop toast, the ratio count-up, the steppers/pickers/stars, method selection, and the timer. Motion should read as before, except the three deliberate deltas (method picker snappier, star fill gains slight spring, timer phase changes marginally slower) — confirm those feel right.
- **Reduce Motion ON** (Settings → Accessibility → Motion): repeat. Every step/screen transition, the toast, the ratio count-up, the stepper/picker/star changes, and the save overlay + checkmark should be **instant** (no slide, no spring). The timer rail (exempt) keeps its existing gated behavior — it already nils under reduce-motion, so it steps per tick rather than easing; confirm that's unchanged.
- Confirm haptics still fire in both modes (independent of reduce-motion).

This change touches navigation-adjacent transitions and shared components, so it sits at verification ladder rungs 2–5 (compile, tests, manual smoke).

## Risks

- **The deliberate family/speed changes (method picker, star rating, timer phase) read worse, not just different.** Mitigation: these three are explicitly flagged for in-sim sign-off above. If the star spring specifically reads wrong, that one site can fall back to an easeOut-flavored control curve — but the default is the unified `control` feel.
- **`withMotion` threading `reduceMotion` is easy to forget at a new call site.** Mitigation: the declarative `.motion` modifier (no flag needed) is the default; `withMotion` is only for the few imperative button-action paths. The doc rule names both. Two views (`ShopView`, `MethodPicker`) gain a `reduceMotion` env read as part of this work.
- **The timer-rail exemption is a hole in "never hardcode a curve."** Mitigation: it is documented in `design.md` as the single sanctioned exception with the reason (continuous tick-synced fill), so it is a known intentional literal, not drift.
- **Scope creep toward "fill the dead spots."** Mitigation: tab/paywall/Today are explicit non-goals; the reviewer should reject any new animated moment in this change.
