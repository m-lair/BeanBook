# Pro Palettes Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 10 new Pro-gated color palettes to BeanBook, taking the catalog from 3 → 13.

**Architecture:** Data-only change to one file (`BeanBook/Shared/Theme/Palette.swift`). Each palette is a `Palette` struct literal + a `PaletteID` enum case + a switch arm in `Palette.with(id:)` + an entry in `Palette.all`. `Theme.*` accessors already resolve through `themeStore.palette`, so no feature views change. Pro gating is data (`isPro: true`); existing `PalettePickerSheet` enforces the gate.

**Tech Stack:** Swift 6, SwiftUI, Observation. iOS 18+ (target iOS 26.0 simulator for verification per project conventions).

**Spec:** `docs/superpowers/specs/2026-05-01-pro-palettes-expansion-design.md`

---

## File Structure

**Modify (single file):**
- `BeanBook/Shared/Theme/Palette.swift` — add 10 cases to `PaletteID`, add 10 `static let` literals to `extension Palette`, expand `Palette.all`, expand `Palette.with(id:)` switch.

**No new files. No other files modified.**

Why one file: the existing pattern keeps all palette definitions co-located. Splitting palettes across files would fragment a small, tightly-related concept and break the existing convention.

---

## Task 1: Add 10 enum cases to `PaletteID`

**Files:**
- Modify: `BeanBook/Shared/Theme/Palette.swift` (the `enum PaletteID` block, currently lines 34-40)

- [ ] **Step 1: Add the 10 new cases to `PaletteID`**

Replace the existing enum body so it reads:

```swift
enum PaletteID: String, CaseIterable, Identifiable, Sendable {
    // Free
    case forest

    // Pro — existing
    case ocean
    case mocha

    // Pro — new (warms)
    case latte
    case honey
    case cascara
    case cocoa
    case espresso

    // Pro — new (cools)
    case slate

    // Pro — new (darks)
    case graphite
    case noir

    // Pro — new (botanicals)
    case sage
    case plum

    var id: String { rawValue }
}
```

Note: case order here is the source-of-truth order for `Palette.all` later. Ocean/Mocha keep their existing `rawValue` strings; new cases use lowercase names matching the table in the spec.

- [ ] **Step 2: Verify the file compiles**

Run: `xcodebuild -project BeanBook.xcodeproj -scheme BeanBook -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' build`

Expected: build fails with "switch must be exhaustive" errors in `Palette.with(id:)` and any other exhaustive switches over `PaletteID`. That's the next task. No other failures should appear.

If the build fails for any *other* reason (typo, duplicate case, etc.), fix before moving on.

- [ ] **Step 3: Do not commit yet**

We commit at the end of Task 3 once the file is internally consistent.

---

## Task 2: Add 10 `Palette` literals

**Files:**
- Modify: `BeanBook/Shared/Theme/Palette.swift` (the `extension Palette` block, currently lines 42-106)

Use the exact hex values from the spec table. Implementer may nudge ±2 hex steps for legibility but no hue changes without re-review.

- [ ] **Step 1: Add `static let espresso`**

Insert inside `extension Palette`, after the existing `mocha`:

```swift
static let espresso = Palette(
    id: .espresso,
    name: "Espresso",
    isPro: true,
    background: Color(hex: "F6F0E6"),
    card: Color(hex: "FFFAF2"),
    ink: Color(hex: "1B1108"),
    ink2: Color(hex: "5A4332"),
    ink3: Color(hex: "9A8472"),
    ink4: Color(hex: "D2C2AE"),
    rule: Color(hex: "E1D2BE"),
    accent: Color(hex: "3A2415"),
    accentSoft: Color(hex: "E5D5C0"),
    accentGlow: Color(hex: "3A2415").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "7A5A2A")
)
```

- [ ] **Step 2: Add `static let latte`**

```swift
static let latte = Palette(
    id: .latte,
    name: "Latte",
    isPro: true,
    background: Color(hex: "FBF4ED"),
    card: Color(hex: "FFFAF4"),
    ink: Color(hex: "2A1A12"),
    ink2: Color(hex: "7A5E4A"),
    ink3: Color(hex: "B59B85"),
    ink4: Color(hex: "DDC8B4"),
    rule: Color(hex: "EAD8C4"),
    accent: Color(hex: "A35E4A"),
    accentSoft: Color(hex: "F0DCCC"),
    accentGlow: Color(hex: "A35E4A").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "8A6A40")
)
```

- [ ] **Step 3: Add `static let cascara`**

```swift
static let cascara = Palette(
    id: .cascara,
    name: "Cascara",
    isPro: true,
    background: Color(hex: "FAF1E4"),
    card: Color(hex: "FFF8EC"),
    ink: Color(hex: "2B1A0E"),
    ink2: Color(hex: "7E5A38"),
    ink3: Color(hex: "B49274"),
    ink4: Color(hex: "DCC0A0"),
    rule: Color(hex: "EAD3B0"),
    accent: Color(hex: "B05A1E"),
    accentSoft: Color(hex: "F0D9B4"),
    accentGlow: Color(hex: "B05A1E").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "9A6A22")
)
```

- [ ] **Step 4: Add `static let honey`**

```swift
static let honey = Palette(
    id: .honey,
    name: "Honey",
    isPro: true,
    background: Color(hex: "FBF6E6"),
    card: Color(hex: "FFFBEE"),
    ink: Color(hex: "22180A"),
    ink2: Color(hex: "6E5A2A"),
    ink3: Color(hex: "A89770"),
    ink4: Color(hex: "D2C292"),
    rule: Color(hex: "E5D7A8"),
    accent: Color(hex: "8A6A12"),
    accentSoft: Color(hex: "F1E4B4"),
    accentGlow: Color(hex: "8A6A12").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "7A5E1A")
)
```

- [ ] **Step 5: Add `static let cocoa`**

```swift
static let cocoa = Palette(
    id: .cocoa,
    name: "Cocoa",
    isPro: true,
    background: Color(hex: "F8F1E8"),
    card: Color(hex: "FFFAF2"),
    ink: Color(hex: "241712"),
    ink2: Color(hex: "6A5040"),
    ink3: Color(hex: "A38978"),
    ink4: Color(hex: "D2BCA8"),
    rule: Color(hex: "E5D2BC"),
    accent: Color(hex: "6E3F22"),
    accentSoft: Color(hex: "EAD3BC"),
    accentGlow: Color(hex: "6E3F22").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "8A5A2A")
)
```

- [ ] **Step 6: Add `static let graphite`**

```swift
static let graphite = Palette(
    id: .graphite,
    name: "Graphite",
    isPro: true,
    background: Color(hex: "EAE7E2"),
    card: Color(hex: "F4F1EC"),
    ink: Color(hex: "14171A"),
    ink2: Color(hex: "50545A"),
    ink3: Color(hex: "8A8E94"),
    ink4: Color(hex: "BCBFC4"),
    rule: Color(hex: "D2D4D8"),
    accent: Color(hex: "2A2E33"),
    accentSoft: Color(hex: "D6D8DC"),
    accentGlow: Color(hex: "2A2E33").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "4A6A4A")
)
```

- [ ] **Step 7: Add `static let slate`**

```swift
static let slate = Palette(
    id: .slate,
    name: "Slate",
    isPro: true,
    background: Color(hex: "F1F4F6"),
    card: Color(hex: "FAFCFD"),
    ink: Color(hex: "0F1820"),
    ink2: Color(hex: "56666F"),
    ink3: Color(hex: "909AA2"),
    ink4: Color(hex: "C4CBD0"),
    rule: Color(hex: "DBE1E5"),
    accent: Color(hex: "36586E"),
    accentSoft: Color(hex: "D8E2E8"),
    accentGlow: Color(hex: "36586E").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "3F7E84")
)
```

- [ ] **Step 8: Add `static let noir`**

```swift
static let noir = Palette(
    id: .noir,
    name: "Noir",
    isPro: true,
    background: Color(hex: "F4F2EE"),
    card: Color(hex: "FFFFFF"),
    ink: Color(hex: "0A0A0A"),
    ink2: Color(hex: "4E4E4C"),
    ink3: Color(hex: "8F8E8B"),
    ink4: Color(hex: "C2C1BE"),
    rule: Color(hex: "DCDAD6"),
    accent: Color(hex: "1A1A1A"),
    accentSoft: Color(hex: "DCD9D2"),
    accentGlow: Color(hex: "1A1A1A").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "4A6A2A")
)
```

- [ ] **Step 9: Add `static let sage`**

```swift
static let sage = Palette(
    id: .sage,
    name: "Sage",
    isPro: true,
    background: Color(hex: "F4F2EA"),
    card: Color(hex: "FBFAF2"),
    ink: Color(hex: "1A1F18"),
    ink2: Color(hex: "56604E"),
    ink3: Color(hex: "8A9482"),
    ink4: Color(hex: "C0C8B6"),
    rule: Color(hex: "D6DCC8"),
    accent: Color(hex: "6E7E54"),
    accentSoft: Color(hex: "DEE4CC"),
    accentGlow: Color(hex: "6E7E54").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "7A8A52")
)
```

- [ ] **Step 10: Add `static let plum`**

```swift
static let plum = Palette(
    id: .plum,
    name: "Plum",
    isPro: true,
    background: Color(hex: "F1EDEC"),
    card: Color(hex: "F9F6F4"),
    ink: Color(hex: "1A1216"),
    ink2: Color(hex: "5C4E54"),
    ink3: Color(hex: "928288"),
    ink4: Color(hex: "C2B6BC"),
    rule: Color(hex: "D8CED2"),
    accent: Color(hex: "5A2E48"),
    accentSoft: Color(hex: "E2D2D8"),
    accentGlow: Color(hex: "5A2E48").opacity(0.22),
    error: Color(hex: "B5293A"),
    success: Color(hex: "7A5A48")
)
```

- [ ] **Step 11: Do not commit yet**

`Palette.all` and `Palette.with(id:)` still don't reference these. Build will still fail. That's the next task.

---

## Task 3: Wire up `Palette.all` and `Palette.with(id:)`, then build clean

**Files:**
- Modify: `BeanBook/Shared/Theme/Palette.swift`

- [ ] **Step 1: Replace `Palette.all`**

Find the existing line:

```swift
static let all: [Palette] = [.forest, .ocean, .mocha]
```

Replace with the curated picker order from the spec (warms → cools → darks → botanicals, free first):

```swift
static let all: [Palette] = [
    // Free
    .forest,
    // Warms
    .latte, .honey, .cascara, .mocha, .cocoa, .espresso,
    // Cools
    .ocean, .slate,
    // Darks
    .graphite, .noir,
    // Botanicals
    .sage, .plum,
]
```

- [ ] **Step 2: Replace `Palette.with(id:)` switch**

Find the existing function:

```swift
static func with(id: PaletteID) -> Palette {
    switch id {
    case .forest: .forest
    case .ocean:  .ocean
    case .mocha:  .mocha
    }
}
```

Replace with:

```swift
static func with(id: PaletteID) -> Palette {
    switch id {
    case .forest:   .forest
    case .ocean:    .ocean
    case .mocha:    .mocha
    case .latte:    .latte
    case .honey:    .honey
    case .cascara:  .cascara
    case .cocoa:    .cocoa
    case .espresso: .espresso
    case .slate:    .slate
    case .graphite: .graphite
    case .noir:     .noir
    case .sage:     .sage
    case .plum:     .plum
    }
}
```

- [ ] **Step 3: Build and verify clean compile**

Run: `xcodebuild -project BeanBook.xcodeproj -scheme BeanBook -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' build`

Expected: build succeeds, no warnings related to `PaletteID` exhaustiveness.

If any other file (e.g., a feature view or test) had its own switch on `PaletteID`, the compiler will catch it now. Search the codebase if so:

```bash
rg "switch.*paletteID|PaletteID\\." --type swift
```

For each non-exhaustive switch found, decide whether the new cases need explicit handling or a `default` is appropriate. The spec assumes there are no such switches outside `Palette.with(id:)`.

- [ ] **Step 4: Run the existing test suite**

Run: `xcodebuild test -project BeanBook.xcodeproj -scheme BeanBook -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'`

Expected: all existing tests pass. We are not adding new tests — the change is data-only and exercising 10 hex literals through unit tests provides no signal.

- [ ] **Step 5: Commit**

```bash
git add BeanBook/Shared/Theme/Palette.swift
git commit -m "feat: add 10 Pro palettes (Espresso, Latte, Cascara, Honey, Cocoa, Graphite, Slate, Noir, Sage, Plum)"
```

---

## Task 4: Manual visual verification

This is a UI change. Type checks and unit tests cannot verify it looks right — the human (or the implementing agent if they have a simulator) must run the app and look at every new palette.

**Files:** none (verification only)

- [ ] **Step 1: Launch the app in the simulator**

Boot iPhone 16 Pro / iOS 26.0 from Xcode and run the BeanBook scheme. Sign in / get past onboarding to land on the main `RootTabView`.

- [ ] **Step 2: Open the palette picker**

Settings tab → Appearance → Palette. Verify all 13 palettes are listed in this order: Forest, Latte, Honey, Cascara, Mocha, Cocoa, Espresso, Ocean, Slate, Graphite, Noir, Sage, Plum.

Verify Forest reads "Included" and every other palette reads "Pro palette" with a lock icon (assuming a non-Pro test account).

- [ ] **Step 3: Preview each new palette and sweep the app**

For each of the 10 new palettes:

1. Tap the palette in the picker (live preview triggers).
2. Dismiss back to the Brews tab. Check `BrewListView` rows: text legibility (`ink`, `ink2`, `ink3`), hairline rules (`rule`).
3. Open a brew row → `BrewDetailView`. Check accent fills, gradient if any.
4. Tap the center "+" → `NewBrewSheet`. Check form field colors, `BrewTimer` accent, button styles.
5. Bags tab → tap a bag → `BagDetailView`. Check the bag photo card.
6. Shop tab → `CatalogBeanCard`. Check Pro badge color (`accentSoft` background + `accent` text).

If any palette fails legibility (e.g., `ink2` too close to `card` and captions disappear), nudge the relevant hex value ±2 steps and rebuild. Anything beyond ±2 steps or a hue change requires re-review against the spec.

- [ ] **Step 4: Verify Pro gating still works**

With a non-Pro account, tap any new Pro palette and tap "Done." The paywall should appear with the headline `"<Palette Name> is a Pro palette. Unlock to keep it."`. Cancelling should revert preview to the originally-stored palette.

- [ ] **Step 5: Verify persistence**

Confirm a Pro palette (with a Pro account, or by temporarily flipping `pro.isPro` in a debug build), then force-quit and relaunch. The stored palette should still be active. (`@AppStorage("paletteID")` already handles this — this is a regression check.)

- [ ] **Step 6: Commit any nudges**

If hex values were adjusted in Step 3, commit them:

```bash
git add BeanBook/Shared/Theme/Palette.swift
git commit -m "fix: nudge <palette> hex values for legibility"
```

If nothing was adjusted, no additional commit.

---

## Done criteria

- [ ] `xcodebuild build` succeeds clean
- [ ] `xcodebuild test` passes
- [ ] All 13 palettes render in the picker in the documented order
- [ ] Each new palette has been previewed across Brews, Bags, Shop, NewBrewSheet, and PaywallSheet
- [ ] Pro gating triggers paywall for each new palette on a non-Pro account
- [ ] Spec hex values are used exactly, or any deviations are documented in the commit message
