# BeanBook — Design system

How tokens, type, and components fit together. Source of truth for color is `BeanBook/Shared/Theme/Palette.swift`; constants for spacing/type live in `BeanBook/Shared/Theme.swift`. This doc explains how to use them.

## Color tokens

All color access goes through `Theme.*`, which resolves through `themeStore.palette`. The active palette is selected from a curated set of distinct manual themes. `forest` is default and free; the others are Pro. `midnight` is the single intentional dark palette; BeanBook still does not follow system dark mode.

### Surfaces

| Token | Forest value | Use |
|---|---|---|
| `Theme.background` | `#FAFAF7` | Root surface — every screen sits on this |
| `Theme.card` | `#FFFFFF` | Raised content (settings rows, input fields, recent-shot cards) |
| `Theme.accentSoft` | `#DFE7DD` | Discovery / featured card backgrounds, value-prop chips, choice rows |

### Ink (type + dividers)

Ranked light-to-dark for non-accent type:

| Token | Forest value | Use |
|---|---|---|
| `Theme.ink` | `#0F1110` | Primary type — headlines, body, primary controls |
| `Theme.ink2` | `#6B6B66` | Secondary type — descriptions, captions, "Cancel" buttons |
| `Theme.ink3` | `#A8A8A2` | Tertiary type — eyebrows, metadata, "was Xg" Δ-from-last hints |
| `Theme.ink4` | `#D8D5CD` | Quaternary — separator dots in inline lists |
| `Theme.rule` | `#E8E5DD` | Hairlines — see component patterns below |

### Brand

| Token | Forest value | Use |
|---|---|---|
| `Theme.accent` | `#2D4A2B` | Primary accent — eyebrows, CTA pills, selection states, brand glyphs |
| `Theme.accentSoft` | `#DFE7DD` | Tinted backgrounds, value chips, eyebrow-style chips |
| `Theme.accentGlow` | `#2D4A2B`@22% | Soft shadow under the accent pill (`AccentPillStyle`) |

### Semantic

| Token | Use |
|---|---|
| `Theme.error` | Validation errors, quota-exceeded callouts |
| `Theme.success` | Save-confirmation states |

**Rule:** never hardcode a color. If a value isn't in the palette, the design needs review, not a hex literal.

## Typography

Two type families, no display fonts.

### Serif (display only)

`SF Pro Serif` via `.system(size:, weight:.medium, design:.serif)`. Used for:

- Page titles (32–44pt depending on hierarchy)
- Card title overlays (e.g., "Geometry" on the featured card)
- The big-ratio readout (`BigRatio`, 84pt)
- Numeric stepper values (24pt)

Serif text is always either `Theme.ink` or `Theme.accent` — never ink2/ink3.

### Body (system sans)

`Theme.body(_ size:, weight:)` — `.system(size:, weight:, design:.default)`. Used for everything that isn't a serif headline.

Common sizes:

| Size | Weight | Use |
|---|---|---|
| 17 | regular (serif) | Notes textfield (intentionally serif body) |
| 16 | semibold | Choice-row titles (onboarding, settings) |
| 15 | regular / semibold | Settings row labels, button labels |
| 14 | regular | Body copy, descriptions |
| 13 | regular | Card secondary copy, tasting-note chips |
| 12 | regular / medium | Captions, metadata, footers |
| 11 | semibold | Eyebrow text (always uppercase, tracked) |

### Eyebrow

`Eyebrow(_:)` shared view — uppercase, tracked, 11pt semibold. Defaults to `Theme.ink3`; pass `color:` to tint accent or another ink.

```swift
Eyebrow("Pick of the week", color: Theme.accent)
```

Don't use `Text("...".uppercased())` ad-hoc. Use `Eyebrow`.

### Tracking and weight

- Display serif tracks negative (`-0.4` to `-1.4`). Tighter for larger sizes.
- Eyebrows track positive (`1.2` to `1.6`).
- Body copy tracks default; never set tracking on 13–17pt body text.

## Spacing

Constants on `Theme` for the values that recur:

```swift
Theme.screenPadding   // 24 — horizontal screen edge
Theme.cardPadding     // 18 — interior of any raised card
Theme.cardSpacing     // 14 — between stacked cards
Theme.itemSpacing     // 10 — within a card row
Theme.cardRadius      // 14
Theme.pillRadius      // 100 — capsules
```

For one-offs, use multiples of 4 (`8, 12, 16, 20, 24, 28, 32`). Ad-hoc 7s and 13s are a smell.

## Components

### Hairline rule (`HairRule`)

A 0.5pt horizontal `Theme.rule` line, used as a list-row separator. We do not use SwiftUI `Divider` because its default thickness is too heavy for the editorial feel.

Pattern: every list row should start with `HairRule()` and pad its body. The first row will have a hairline above it, which is what we want — it visually anchors the list to the section header.

### Pill button styles

In `Shared/SharedViews/GradientButtonStyle.swift`:

| Style | Surface | Use |
|---|---|---|
| `.primaryPill` | Solid `Theme.ink` (black) | Wizard "Continue", "Save brew" — primary intra-flow action |
| `.accentPill` | Solid `Theme.accent` with `accentGlow` shadow | Top-of-funnel CTAs — onboarding, paywall, "Add to beans" |
| `.outlinePill` | Hairline outlined | Secondary actions like "Back", "Cancel" |

**Decision rule:** `.primaryPill` is for "advance the user one step in a flow they're already in." `.accentPill` is for "convert the user from passive to active engagement." Discovery, paywall, onboarding all use accent. Save buttons inside an active flow use primary.

### Value chips

Forest-on-accent-soft capsules used for value props (paywall) and tasting notes (catalog cards). Pattern:

```swift
Text(label)
    .font(Theme.body(11, weight: .semibold))
    .foregroundStyle(Theme.accent)
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(Theme.accentSoft, in: .capsule)
    .overlay(Capsule().stroke(Theme.accent.opacity(0.18), lineWidth: 0.5))
```

The hairline accent border at 18% opacity is what keeps these from looking like buttons.

### Stepper rows (`StepperRow`)

Used in `NewBrewSheet` for dose/yield. Pattern:

- `HairRule` on top.
- Label on the left at `body(14.5)` ink2.
- Optional Δ-from-last caption (`DeltaCaption`) under the label at `body(11)` ink3.
- Stepper buttons on the right with serif numeric value.
- `sensoryFeedback(.selection, trigger: value)` for haptics.

### Cards (raised content blocks)

A card has:

- `Theme.card` fill (or `Theme.accentSoft` for a featured/discovery card).
- `cornerRadius: 14` (or `20` for the featured discovery card).
- Hairline stroke at `Theme.rule` lineWidth `0.5` — replaces shadow as the depth signal.
- 18pt internal padding (`Theme.cardPadding`), or 24 for hero cards.

Cards do not use drop shadows except for the featured discovery card's tilted hero swatch (`black.opacity(0.08)`, radius 12). The brand is paper, not glass.

## Motion

All animation curves are tokens on `Motion` (`BeanBook/Shared/Theme/Motion.swift`) — the animation analogue of `Theme`. There are five, grouped by intent, not duration:

| Token | Curve | Use |
|---|---|---|
| `Motion.transition` | `.snappy(0.32)` | Spatial moves between steps / screens / states, and the hero numeric count-up |
| `Motion.control` | `.snappy(0.2)` | Direct-manipulation feedback — steppers, pickers, selection pills, stars, press states |
| `Motion.fade` | `.easeOut(0.25)` | Pure opacity appear/disappear (toast, save overlay) |
| `Motion.fill` | `.easeOut(0.5)` | Discrete value-bar fill to a target (the dose↔yield ratio bar) |
| `Motion.confirm` | `.spring(0.4 / 0.6)` | The one celebratory curve — the save-success checkmark |

**Rule:** never hardcode an animation curve. Apply a token through `.motion(_:value:)` (declarative) or `withMotion(_:reduceMotion:)` (imperative). If a motion doesn't fit one of the five, the design needs review, not a new literal — same discipline as color.

- **No motion for type.** Text doesn't bounce or scale-in. The exception is `.contentTransition(.numericText(value:))` for stepper and ratio values, which animates digit changes character-by-character.
- **One sanctioned exception to the token rule:** `BrewTimer`'s progress rail uses a local `.linear(0.1)` synced to its `TimelineView` tick. It's a continuous live-tracking fill, not a discrete state animation — tokenizing it would make the bar lag behind each tick.

### Reduce Motion

Reduce-motion is handled **centrally**, not per-site. `.motion`/`withMotion` read `@Environment(\.accessibilityReduceMotion)` and pass `nil` to the underlying animation when it's on — so you never write `reduceMotion ? …` branches in views, and a transition driven by a nil'd animation simply applies instantly (which is the desired reduce-motion behavior). The timer rail is the lone site that gates its own curve, by construction.

```swift
// Declarative — animates normally, instant under Reduce Motion:
.motion(Motion.transition, value: step)

// Imperative — caller passes its own reduceMotion env value:
withMotion(Motion.control, reduceMotion: reduceMotion) { value += 1 }
```

Test with **Settings → Accessibility → Motion → Reduce Motion** before shipping any new transition — every step transition, toast, count-up, and overlay should go instant.

## Accessibility

- `.dynamicTypeSize(...DynamicTypeSize.accessibility2)` is set at the root. Don't override on individual views unless you know the layout breaks at a higher tier.
- Every icon-only button needs a `.accessibilityLabel`. The shared `StepperButton` already does this.
- Combine accessibility for tightly-coupled visual groups (`.accessibilityElement(children: .combine)`) — see `RecentShotCard`.
- VoiceOver gets a "Brew this shot again" hint on each recent-shot card.

## Color Scheme

The app is locked to `.preferredColorScheme(.light)` at the root in `BeanBookApp.swift`. This prevents automatic system dark-mode variants. Dark appearance exists only through the curated `Midnight` palette.

## Surface defaults

Every screen scaffolds the same way:

```swift
ZStack {
    Theme.background.ignoresSafeArea()

    ScrollView {
        VStack(alignment: .leading, spacing: 0) {
            header
            // sections
            Spacer().frame(height: 80)   // bottom safe-area + tab bar clearance
        }
        .padding(.top, 12)
    }
    .scrollIndicators(.hidden)
}
```

Hidden scroll indicators is a brand call — we trust users to know they can scroll. If you find yourself reaching for `.scrollIndicators(.visible)`, the page is probably too long.

## Iconography

SF Symbols only. No custom iconography ever ships unless it's the app icon itself.

Common symbols in use and what they mean:

| Symbol | Meaning |
|---|---|
| `cup.and.saucer.fill` | Espresso (or app glyph) |
| `cup.and.heat.waves.fill` | Pro / paywall hero |
| `drop.fill` | Pour over |
| `cylinder.fill` | French press |
| `flame.fill` | Moka pot |
| `snowflake` | Cold brew |
| `arrow.clockwise` | "Brew again" |
| `pin.fill` | Pinned bag |
| `sparkles` | Pro / curated / featured |
| `location.fill` | Origin / "Near you" |
| `scalemass.fill` | Brew logging |
| `bag.fill` | Beans tab / catalog |
