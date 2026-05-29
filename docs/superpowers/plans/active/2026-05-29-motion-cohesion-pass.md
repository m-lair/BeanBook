# Motion Cohesion Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate the ~12 ad-hoc SwiftUI animation curves in BeanBook into a 5-token `Motion` namespace applied through a reduce-motion-aware layer, so motion is consistent and accessibility-correct by construction — without adding any new animation.

**Architecture:** A new `Motion` enum (mirroring `Theme`) holds five constant `Animation` tokens. A `.motion(_:value:)` `ViewModifier` and a `withMotion(_:reduceMotion:_:)` helper read/accept `accessibilityReduceMotion` and nil the animation when it is on, so reduce-motion compliance lives in one place. Named `AnyTransition` tokens (`.stepForward`, `.toastRise`) replace the two reused inline transitions. Existing call sites are migrated file-by-file; the timer's continuous `.linear` rail is intentionally exempt.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI (iOS 18+), SwiftData. No new dependencies.

**Spec:** [`docs/superpowers/specs/2026-05-29-motion-cohesion-pass-design.md`](../../specs/2026-05-29-motion-cohesion-pass-design.md)

---

## Verification approach (read first)

This is a mechanical refactor, not feature work, so the classic write-failing-test-first TDD loop does not apply — SwiftUI animation timing is not unit-testable and the spec explicitly excludes token-existence tests. The per-task "test" is therefore:

1. **Compile gate:** `./scripts/agent-verify.sh build` → expect `** BUILD SUCCEEDED **`.
2. **Grep gate:** after migrating a file, grep it for raw curve literals — expect none remain (except the documented timer-rail exemption).
3. **Final manual gate (Task 10):** toggle Reduce Motion in the simulator and confirm transitions go instant.

Commit after every green task. Never use `--no-verify`.

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `BeanBook/Shared/Theme/Motion.swift` | The motion system: 5 tokens, `.motion` modifier, `withMotion` helper, `AnyTransition` tokens | **Create** |
| `BeanBook/Shared/SharedViews/StarRating.swift` | Rating dots — migrate to `Motion.control` | Modify |
| `BeanBook/Features/Bags/NewBagSheet.swift` | Bag form pickers — migrate to `Motion.control` | Modify |
| `BeanBook/Features/Brews/Components/MethodPicker.swift` | Method list — migrate to `Motion.control` (+ env) | Modify |
| `BeanBook/Shared/SharedViews/BigRatio.swift` | Ratio readout + bar — `Motion.transition` / `Motion.fill` | Modify |
| `BeanBook/Features/Brews/Components/BrewTimer.swift` | Timer — phase→`transition`, canReset→`control`; rail exempt | Modify |
| `BeanBook/Features/Shop/ShopView.swift` | Toast — `Motion.fade` + `.toastRise` (+ env) | Modify |
| `BeanBook/Features/Onboarding/OnboardingView.swift` | Onboarding steps — `Motion.transition` + `.stepForward` | Modify |
| `BeanBook/Features/Brews/NewBrewSheet.swift` | Brew flow — all four non-fill tokens + `DeltaCaption` cleanup | Modify |
| `docs/design.md` | Motion section rewrite | Modify |
| `docs/quality.md` | Add `Motion.*` sibling to the Theme invariant | Modify |
| `CLAUDE.md` | Update Motion bullet if it names specific curves | Modify (conditional) |

## Migration patterns (referenced by every migration task)

- **P1 — declarative:** `.animation(<curve>, value: v)` → `.motion(Motion.<token>, value: v)`. If the original was `.animation(reduceMotion ? nil : <curve>, value: v)`, the result is the same `.motion(...)` call — drop the ternary, the modifier handles it.
- **P2 — imperative:** `withAnimation(<curve>) { … }` → `withMotion(Motion.<token>, reduceMotion: reduceMotion) { … }`. The enclosing view MUST have `@Environment(\.accessibilityReduceMotion) private var reduceMotion`; add it if missing.
- **P3 — collapse if/else:** `if reduceMotion { x = v } else { withAnimation(<curve>) { x = v } }` → `withMotion(Motion.<token>, reduceMotion: reduceMotion) { x = v }`.
- **P4 — transition token:** inline reused transition → `.transition(.stepForward)` or `.transition(.toastRise)`; drop any `reduceMotion ? .identity :` wrapper.

---

### Task 1: Create the `Motion` system

**Files:**
- Create: `BeanBook/Shared/Theme/Motion.swift`

- [ ] **Step 1: Write the file**

```swift
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
```

- [ ] **Step 2: Add the file to the Xcode target**

The project may use folder-synced groups (file auto-included) or explicit membership. Verify after the build step; if the build can't see `Motion`, add the file to the `BeanBook` target in `BeanBook.xcodeproj`.

- [ ] **Step 3: Build**

Run: `./scripts/agent-verify.sh build`
Expected: `** BUILD SUCCEEDED **` (nothing references `Motion` yet, but the new file must compile).

- [ ] **Step 4: Commit**

```bash
git add BeanBook/Shared/Theme/Motion.swift BeanBook.xcodeproj
git commit -m "feat(motion): add Motion token namespace and reduce-motion application layer"
```

---

### Task 2: Migrate leaf controls — StarRating + NewBagSheet (declarative `control`)

Pure P1 swaps, no environment additions needed.

**Files:**
- Modify: `BeanBook/Shared/SharedViews/StarRating.swift:19`
- Modify: `BeanBook/Features/Bags/NewBagSheet.swift:406,458`

- [ ] **Step 1: StarRating** — apply P1. Replace:

```swift
.animation(.easeOut(duration: 0.2), value: rating)
```
with:
```swift
.motion(Motion.control, value: rating)
```
(Deliberate curve-family change easeOut→snappy per spec — the dot fill gains slight spring.)

- [ ] **Step 2: NewBagSheet** — apply P1 at both sites. Replace `.animation(.snappy(duration: 0.2), value: level)` → `.motion(Motion.control, value: level)` (line ~406) and `.animation(.snappy(duration: 0.2), value: process)` → `.motion(Motion.control, value: process)` (line ~458).

- [ ] **Step 3: Grep gate**

Run: `grep -nE '\.animation\(|withAnimation|\.snappy|\.easeOut' BeanBook/Shared/SharedViews/StarRating.swift BeanBook/Features/Bags/NewBagSheet.swift`
Expected: no raw curve literals; only `.motion(Motion.control, …)`.

- [ ] **Step 4: Build**

Run: `./scripts/agent-verify.sh build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add BeanBook/Shared/SharedViews/StarRating.swift BeanBook/Features/Bags/NewBagSheet.swift
git commit -m "refactor(motion): route StarRating and NewBagSheet through Motion.control"
```

---

### Task 3: Migrate MethodPicker (imperative `control` + env)

**Files:**
- Modify: `BeanBook/Features/Brews/Components/MethodPicker.swift:5,11`

- [ ] **Step 1: Add the environment read** to `MethodPicker` (it currently has none). After the `@Binding var selection` line:

```swift
@Binding var selection: BrewMethod
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

- [ ] **Step 2: Apply P2** at line ~11. Replace:

```swift
withAnimation(.snappy) { selection = method }
```
with:
```swift
withMotion(Motion.control, reduceMotion: reduceMotion) { selection = method }
```
(Also tightens the bare `.snappy` default ≈0.35 → 0.2 per spec.)

- [ ] **Step 3: Grep gate**

Run: `grep -nE 'withAnimation|\.snappy|\.easeOut' BeanBook/Features/Brews/Components/MethodPicker.swift`
Expected: no raw curve literals.

- [ ] **Step 4: Build** → `./scripts/agent-verify.sh build` → `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add BeanBook/Features/Brews/Components/MethodPicker.swift
git commit -m "refactor(motion): route MethodPicker through Motion.control with reduce-motion support"
```

---

### Task 4: Migrate BigRatio (`transition` count-up + `fill` bar)

**Files:**
- Modify: `BeanBook/Shared/SharedViews/BigRatio.swift:44-48,71`

- [ ] **Step 1: Collapse the count-up if/else (P3).** Replace lines ~43-49:

```swift
.onChange(of: ratio) { _, newValue in
    if reduceMotion {
        displayRatio = newValue
    } else {
        withAnimation(.snappy(duration: 0.35)) { displayRatio = newValue }
    }
}
```
with:
```swift
.onChange(of: ratio) { _, newValue in
    withMotion(Motion.transition, reduceMotion: reduceMotion) { displayRatio = newValue }
}
```

- [ ] **Step 2: Migrate RatioBar (P1).** Replace line ~71:

```swift
.animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: ratio)
```
with:
```swift
.motion(Motion.fill, value: ratio)
```
`RatioBar` keeps its own `@Environment(\.accessibilityReduceMotion)` for now; if it becomes unused after this edit, remove it (the `.motion` modifier owns the read). Verify with the build — an unused `@Environment` is not an error, but prefer removing it if nothing else references `reduceMotion` in `RatioBar`.

- [ ] **Step 3: Grep gate**

Run: `grep -nE 'withAnimation|\.snappy|\.easeOut|\.spring|\.linear' BeanBook/Shared/SharedViews/BigRatio.swift`
Expected: no raw curve literals.

- [ ] **Step 4: Build** → `./scripts/agent-verify.sh build` → `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add BeanBook/Shared/SharedViews/BigRatio.swift
git commit -m "refactor(motion): route BigRatio count-up and ratio bar through Motion tokens"
```

---

### Task 5: Migrate BrewTimer (`transition` + `control`; rail exempt)

**Files:**
- Modify: `BeanBook/Features/Brews/Components/BrewTimer.swift:38,107,111`
- **Do NOT touch line 152** (`.linear(duration: 0.1)` rail — documented exemption).

- [ ] **Step 1: Eyebrow phase animation (P1).** Replace line ~38 `.animation(.snappy(duration: 0.25), value: phase)` → `.motion(Motion.transition, value: phase)`.

- [ ] **Step 2: Reset-button affordance (P1).** Replace line ~107 `.animation(.snappy(duration: 0.25), value: canReset)` → `.motion(Motion.control, value: canReset)`.

- [ ] **Step 3: Whole-timer layout reflow (P1).** Replace line ~111 `.animation(.snappy(duration: 0.3), value: phase)` → `.motion(Motion.transition, value: phase)`. (This also makes the adjust-pill `.transition` at line ~77 degrade correctly under reduce-motion, since it is driven by this animation.)

- [ ] **Step 4: Confirm the rail is untouched**

Run: `grep -n '\.linear(duration: 0.1)' BeanBook/Features/Brews/Components/BrewTimer.swift`
Expected: line ~152 still present, unchanged.

- [ ] **Step 5: Grep gate (everything except the rail)**

Run: `grep -nE 'withAnimation|\.snappy|\.easeOut|\.spring' BeanBook/Features/Brews/Components/BrewTimer.swift`
Expected: no matches (the only remaining curve literal is the exempt `.linear`, which this grep does not match).

- [ ] **Step 6: Build** → `./scripts/agent-verify.sh build` → `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add BeanBook/Features/Brews/Components/BrewTimer.swift
git commit -m "refactor(motion): route BrewTimer phase/affordance animations through Motion tokens"
```

---

### Task 6: Migrate ShopView toast (`fade` + `.toastRise` + env)

**Files:**
- Modify: `BeanBook/Features/Shop/ShopView.swift:75,306,314`

- [ ] **Step 1: Add the environment read** to the `ShopView` struct (it currently has none). Near the other `@Environment`/`@State` properties at the top of the view:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

- [ ] **Step 2: Toast transition (P4).** Replace line ~75 `.transition(.move(edge: .bottom).combined(with: .opacity))` → `.transition(.toastRise)`.

- [ ] **Step 3: Toast show (P2).** Replace line ~306 `withAnimation(.easeOut(duration: 0.25)) {` (wrapping `toastMessage = "Added …"`) → `withMotion(Motion.fade, reduceMotion: reduceMotion) {`.

- [ ] **Step 4: Toast hide (P2).** Replace line ~314 `withAnimation(.easeOut(duration: 0.25)) { toastMessage = nil }` → `withMotion(Motion.fade, reduceMotion: reduceMotion) { toastMessage = nil }`.

Note: the hide runs inside a detached `Task { … }`. `withMotion` is `@MainActor`; the surrounding `Task` inherits `ShopView`'s `@MainActor` context, so this compiles. If the compiler flags isolation, wrap the call in `await MainActor.run { … }` — but try the direct call first.

- [ ] **Step 5: Grep gate**

Run: `grep -nE 'withAnimation|\.easeOut|\.snappy' BeanBook/Features/Shop/ShopView.swift`
Expected: no raw curve literals.

- [ ] **Step 6: Build** → `./scripts/agent-verify.sh build` → `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add BeanBook/Features/Shop/ShopView.swift
git commit -m "refactor(motion): route ShopView toast through Motion.fade with reduce-motion support"
```

---

### Task 7: Migrate OnboardingView (`transition` + `.stepForward`)

**Files:**
- Modify: `BeanBook/Features/Onboarding/OnboardingView.swift:47,52,128`

`OnboardingView` already has `@Environment(\.accessibilityReduceMotion) private var reduceMotion` (line 16).

- [ ] **Step 1: Step transition (P4).** Replace lines ~47-50:

```swift
.transition(reduceMotion ? .identity : .asymmetric(
    insertion: .opacity.combined(with: .move(edge: .trailing)),
    removal: .opacity.combined(with: .move(edge: .leading))
))
```
with:
```swift
.transition(.stepForward)
```

- [ ] **Step 2: Driving animation (P1).** Replace line ~52 `.animation(.snappy(duration: 0.32), value: step)` → `.motion(Motion.transition, value: step)`.

- [ ] **Step 3: Advance button (P2).** Replace line ~128 `withAnimation(.snappy(duration: 0.32)) { step = 1 }` → `withMotion(Motion.transition, reduceMotion: reduceMotion) { step = 1 }`.

- [ ] **Step 4: Grep gate**

Run: `grep -nE 'withAnimation|\.snappy|\.easeOut|\.identity' BeanBook/Features/Onboarding/OnboardingView.swift`
Expected: no raw curve literals and no `.identity` ternary.

- [ ] **Step 5: Build** → `./scripts/agent-verify.sh build` → `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add BeanBook/Features/Onboarding/OnboardingView.swift
git commit -m "refactor(motion): route OnboardingView steps through Motion.transition and .stepForward"
```

---

### Task 8: Migrate NewBrewSheet (the hub) + DeltaCaption cleanup

The densest file. Work top-down; build once at the end of the task.

**Files:**
- Modify: `BeanBook/Features/Brews/NewBrewSheet.swift` — lines 119, 127, 148, 167, 190, 219, 484, 518, 572, 670-681, 717, 737, 767, 787, 859 and the 3 `DeltaCaption(...)` call sites (376, 704, 816).

- [ ] **Step 1: Step driving animations (P1).** At lines ~127, ~148 (`.snappy(0.32)`) and ~167, ~219 (`.snappy(0.3)`), all `value: step` → `.motion(Motion.transition, value: step)`.

- [ ] **Step 2: Step transition token (P4).** Replace the asymmetric transition at line ~119 with `.transition(.stepForward)`.

- [ ] **Step 3: Step advance/back (P2).** Line ~190 `withAnimation(.snappy(duration: 0.3)) { step -= 1 }` and line ~518 `withAnimation(.snappy(duration: 0.32)) { step += 1 }` → `withMotion(Motion.transition, reduceMotion: reduceMotion) { … }`. (`NewBrewSheet` already reads `reduceMotion` — confirm; if a nested view owns the `withAnimation`, ensure that view has the env read.)

- [ ] **Step 4: Save overlay show (P2).** Line ~572 `withAnimation(.easeOut(duration: 0.25)) { showSaved = true }` → `withMotion(Motion.fade, reduceMotion: reduceMotion) { showSaved = true }`.

- [ ] **Step 5: Save checkmark (P3).** Replace the if/else at lines ~480-488:

```swift
.onAppear {
    if reduceMotion {
        savedScale = 1
    } else {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            savedScale = 1
        }
    }
}
```
with:
```swift
.onAppear {
    withMotion(Motion.confirm, reduceMotion: reduceMotion) { savedScale = 1 }
}
```

- [ ] **Step 6: Steppers (P2).** The four `withAnimation(.snappy(duration: 0.25)) { … }` blocks in `StepperRow` (lines ~717, ~737) and `StepperIntRow` (lines ~767, ~787) → `withMotion(Motion.control, reduceMotion: reduceMotion) { … }`. `StepperRow` already reads `reduceMotion` (line 693); **`StepperIntRow` does NOT** — add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to `StepperIntRow`.

- [ ] **Step 7: Button-press style (P1).** Line ~859 in `StepperPressStyle`: `.animation(.snappy(duration: 0.18), value: configuration.isPressed)` → `.motion(Motion.control, value: configuration.isPressed)`.

- [ ] **Step 8: DeltaCaption cleanup.** Simplify `DeltaCaption` (lines ~670-681): change `.transition(reduceMotion ? .identity : .opacity)` → `.transition(.opacity)`, and remove the `let reduceMotion: Bool` stored property. Update the 3 call sites (lines ~376, ~704, ~816) from `DeltaCaption(text: …, reduceMotion: reduceMotion)` → `DeltaCaption(text: …)`. The caption's transition is inert without a driving animation, and every value/prefill change that surfaces a caption is now reduce-motion-gated via `.motion`/`withMotion`, so dropping the param does not regress accessibility.
  - **Verify:** after removing the param, grep `grep -n 'reduceMotion' BeanBook/Features/Brews/NewBrewSheet.swift` and confirm any view whose ONLY use of `reduceMotion` was the removed `DeltaCaption` arg has its now-unused `@Environment` removed too (avoid dead declarations). `StepperRow`/`GrindRow` keep theirs only if still referenced.

- [ ] **Step 9: Leave as-is.** Do not modify the `.transition(...)` at lines ~162, ~204, ~501 (they degrade via their now-gated drivers) or the `.contentTransition(.numericText/.opacity)` calls.

- [ ] **Step 10: Grep gate**

Run: `grep -nE 'withAnimation|\.snappy|\.easeOut|\.spring|\.identity' BeanBook/Features/Brews/NewBrewSheet.swift`
Expected: no matches.

- [ ] **Step 11: Build** → `./scripts/agent-verify.sh build` → `** BUILD SUCCEEDED **`

- [ ] **Step 12: Commit**

```bash
git add BeanBook/Features/Brews/NewBrewSheet.swift
git commit -m "refactor(motion): route NewBrewSheet through Motion tokens and simplify DeltaCaption"
```

---

### Task 9: Update documentation

**Files:**
- Modify: `docs/design.md` (Motion section, ~lines 165-179)
- Modify: `docs/quality.md` (Theme invariant, ~line 37)
- Modify: `CLAUDE.md` (Motion guidance — conditional)

- [ ] **Step 1: Rewrite the `docs/design.md` "Motion" section** to:
  - List the five tokens and their semantic use (replacing the two-curve prose):
    - `Motion.transition` — `.snappy(0.32)` — step/screen/state moves + hero numeric count-up
    - `Motion.control` — `.snappy(0.2)` — direct-manipulation feedback (steppers, pickers, pills, stars, press)
    - `Motion.fade` — `.easeOut(0.25)` — pure opacity appear/disappear (toast, save overlay)
    - `Motion.fill` — `.easeOut(0.5)` — discrete value-bar fills (ratio bar)
    - `Motion.confirm` — `.spring(0.4/0.6)` — the save-success celebration
  - State the rule: **never hardcode an animation curve — use a `Motion.*` token, applied via `.motion(_:value:)` or `withMotion(_:reduceMotion:)` so reduce-motion is automatic** (mirrors the "never hardcode a color" rule).
  - Document the one exception: the timer's continuous live-tracking rail uses a local `.linear` synced to its `TimelineView` tick.
  - Keep "No motion for type" and the `.numericText` exception.
  - Replace the `.transition(reduceMotion ? .identity : .opacity)` example under "Reduce Motion" with the new pattern, and explain that transitions degrade to instant automatically when driven by `.motion`/`withMotion`.

- [ ] **Step 2: `docs/quality.md`** — under "Structural invariants," append a sibling to the Theme line: `Animation curves go through Motion.*; no raw curve literals in views except the documented timer-rail exemption.`

- [ ] **Step 3: `CLAUDE.md`** — grep for the Motion guidance: `grep -n 'snappy\|spring\|Motion\|motion' CLAUDE.md`. If it names specific curves (e.g. an architecture-summary Motion bullet), update it to point at `Motion.*` and the `.motion`/`withMotion` rule. If it does not, leave it.

- [ ] **Step 4: Docs verify**

Run: `./scripts/agent-verify.sh preflight`
Expected: pass (docs-only rung).

- [ ] **Step 5: Commit**

```bash
git add docs/design.md docs/quality.md CLAUDE.md
git commit -m "docs(motion): codify Motion token set and the no-hardcoded-curve rule"
```

---

### Task 10: Full verification + manual reduce-motion check

**Files:** none (verification only)

- [ ] **Step 1: Repo-wide straggler grep.** Confirm no raw view-animation curves remain anywhere except the timer rail:

Run:
```bash
grep -rnE '\.animation\(\s*\.(snappy|easeOut|easeIn|easeInOut|linear|spring)|withAnimation\(\s*\.(snappy|easeOut|easeIn|easeInOut|linear|spring)' BeanBook/ --include='*.swift'
```
Expected: **only** `BrewTimer.swift:152` (the exempt `.linear` is gated as `reduceMotion ? nil : .linear(...)` — note it will appear via the `withAnimation`/`.animation` form only if matched; the rail uses `.animation(reduceMotion ? nil : .linear(duration: 0.1), value: progress)`, so confirm that single line is the sole result). No other matches.

- [ ] **Step 2: Full build** → `./scripts/agent-verify.sh build` → `** BUILD SUCCEEDED **`

- [ ] **Step 3: Tests** → `./scripts/agent-verify.sh test` → all existing suites pass (no regression).

- [ ] **Step 4: Manual reduce-motion check (simulator).** Use the xcodebuild MCP. Boot iPhone 16 Pro (iOS 26.0), install, launch.
  - **Reduce Motion OFF:** run the brew flow (method → bag → shot steppers → outcome stars → Save), trigger a Shop toast, watch the ratio count-up and the timer. Confirm motion reads as before, and the three deliberate deltas feel right: method selection snappier, star fill slight spring, timer phase changes marginally slower.
  - Toggle **Settings → Accessibility → Motion → Reduce Motion ON.** Repeat. Confirm every step transition, toast, ratio count-up, stepper/picker/star change, and the save overlay + checkmark are **instant** (no slide/spring). Confirm the timer rail behaves as it did before (it already nilled under reduce-motion).
  - Record both passes with `record_sim_video` for sign-off.

- [ ] **Step 5: If all green, no commit needed** (verification only). If the manual pass surfaces a curve that reads wrong (per spec risks — most likely the star spring), note it and either accept or fall back that single site to an easeOut-flavored control curve; re-build and commit that adjustment.

- [ ] **Step 6: Finalize.** This plan lives in `docs/superpowers/plans/active/`. On completion, move it to `docs/superpowers/plans/completed/`:

```bash
git mv docs/superpowers/plans/active/2026-05-29-motion-cohesion-pass.md docs/superpowers/plans/completed/
git commit -m "chore(plans): complete motion cohesion pass"
```

---

## Notes for the implementer

- **Reduce-motion is gained for free**, not added by hand: many migrated sites (all the `.animation(value:)` step/phase calls) were animating *unconditionally* before — using `.motion` fixes that as a side effect. Don't add manual `reduceMotion ?` branches; that's the whole point of the layer.
- **The timer rail is sacred.** If a grep or a reviewer suggests folding `BrewTimer.swift:152` into `Motion.fill`, don't — it's a continuous tick-synced fill and easing it makes the bar lag. The exemption is in the spec and the design doc.
- **No new motion.** If you find yourself adding an `.animation`/`.transition` to a site that had none (tab bar, paywall, Today, list rows), stop — that's explicitly out of scope.
