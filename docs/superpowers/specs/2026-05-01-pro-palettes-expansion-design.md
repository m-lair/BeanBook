# Pro Palettes Expansion — Design

**Date:** 2026-05-01
**Scope:** Add 10 new Pro-gated color palettes to BeanBook.

> Superseded note: the final shipped palette set was later consolidated for distinctness, and `Midnight` became the single intentional dark palette. Current theme rules live in `docs/design.md` and `BeanBook/Shared/Theme/Palette.swift`.

## Goal

Expand the palette catalog from 3 (Forest free, Ocean Pro, Mocha Pro) to 13 (Forest free + 12 Pro). Give Pro users meaningful aesthetic variety while keeping the editorial light-mode brand intact.

## Non-goals

- Originally avoided dark palettes; this was superseded by the later `Midnight` manual palette.
- No changes to feature views — `Theme.*` accessors already resolve through `themeStore.palette`.
- No changes to `PalettePickerSheet` layout. Single-column vertical scroll handles 13 entries fine.
- No new tokens on the `Palette` struct. Existing token shape is sufficient.
- No telemetry or analytics for palette selection.

## The 10 new palettes

All `isPro: true`. Names are short, single-word, editorial.

| # | ID | Name | Vibe |
|---|----|----|------|
| 1 | `espresso` | Espresso | Deep warm charcoal accent on cream paper |
| 2 | `latte` | Latte | Muted rose-tan accent on warm ivory |
| 3 | `cascara` | Cascara | Amber/cherry-husk accent on sand |
| 4 | `honey` | Honey | Golden accent on pale wheat |
| 5 | `cocoa` | Cocoa | Milk-chocolate accent on bone |
| 6 | `graphite` | Graphite | Cool dark charcoal accent on dimmed warm-grey paper (the "darker" pick) |
| 7 | `slate` | Slate | Cool blue-grey accent on pale stone |
| 8 | `noir` | Noir | Near-black accent on neutral paper |
| 9 | `sage` | Sage | Dusty olive accent on parchment (distinct from Forest's deep evergreen) |
| 10 | `plum` | Plum | Muted aubergine accent on warm grey |

## Design constraints (apply to every new palette)

Every palette must follow the existing `Palette` token shape and these brand rules:

- **Light-mode only.** Background is always lighter than card-or-equal. No dark backgrounds.
- **Desaturated accents.** No neon, no fully-saturated primaries. Match the quiet/editorial feel of Forest, Ocean, Mocha.
- **Ink ramp must pass legibility.** `ink` is near-black for body copy; `ink2` is mid (captions); `ink3` is muted (placeholders); `ink4` is near-rule (disabled). `rule` is the hairline divider color.
- **`accentSoft` is a tinted surface** — it's used as a fill behind chips and the "Pro" badge. Should be the accent hue, very desaturated.
- **`accentGlow` is `accent.opacity(0.22)`** — used for shadows. Keep the opacity literal at 0.22 for visual consistency with existing palettes.
- **`error` stays close to `#B5293A`** across all palettes (semantic color, low variance).
- **`success` may shift hue per palette** (current palettes already do this — Forest uses olive-green, Ocean uses teal, Mocha uses amber).

## File changes

Single file: `BeanBook/Shared/Theme/Palette.swift`.

1. Add 10 new cases to `enum PaletteID`.
2. Add 10 new `static let` palette literals to `extension Palette`.
3. Extend `Palette.all` to include all 13 palettes, ordered: Forest first (free), then the 12 Pro palettes in a curated order that flows visually (warm → cool → dark → botanical).
4. Extend `Palette.with(id:)` switch to cover all 13 cases.

Proposed order in `Palette.all` (for the picker):

```
Forest (free)
— Pro —
Latte, Honey, Cascara, Mocha, Cocoa, Espresso,    // warms
Ocean, Slate,                                      // cools
Graphite, Noir,                                    // darks
Sage, Plum                                         // botanicals
```

## Concrete color values

These are the proposed hex values. Locked at implementation time but listed here so the spec is reviewable end-to-end.

| Palette | bg | card | ink | ink2 | ink3 | ink4 | rule | accent | accentSoft | success |
|---|---|---|---|---|---|---|---|---|---|---|
| Espresso | F6F0E6 | FFFAF2 | 1B1108 | 5A4332 | 9A8472 | D2C2AE | E1D2BE | 3A2415 | E5D5C0 | 7A5A2A |
| Latte | FBF4ED | FFFAF4 | 2A1A12 | 7A5E4A | B59B85 | DDC8B4 | EAD8C4 | A35E4A | F0DCCC | 8A6A40 |
| Cascara | FAF1E4 | FFF8EC | 2B1A0E | 7E5A38 | B49274 | DCC0A0 | EAD3B0 | B05A1E | F0D9B4 | 9A6A22 |
| Honey | FBF6E6 | FFFBEE | 22180A | 6E5A2A | A89770 | D2C292 | E5D7A8 | 8A6A12 | F1E4B4 | 7A5E1A |
| Cocoa | F8F1E8 | FFFAF2 | 241712 | 6A5040 | A38978 | D2BCA8 | E5D2BC | 6E3F22 | EAD3BC | 8A5A2A |
| Graphite | EAE7E2 | F4F1EC | 14171A | 50545A | 8A8E94 | BCBFC4 | D2D4D8 | 2A2E33 | D6D8DC | 4A6A4A |
| Slate | F1F4F6 | FAFCFD | 0F1820 | 56666F | 909AA2 | C4CBD0 | DBE1E5 | 36586E | D8E2E8 | 3F7E84 |
| Noir | F4F2EE | FFFFFF | 0A0A0A | 4E4E4C | 8F8E8B | C2C1BE | DCDAD6 | 1A1A1A | DCD9D2 | 4A6A2A |
| Sage | F4F2EA | FBFAF2 | 1A1F18 | 56604E | 8A9482 | C0C8B6 | D6DCC8 | 6E7E54 | DEE4CC | 7A8A52 |
| Plum | F1EDEC | F9F6F4 | 1A1216 | 5C4E54 | 928288 | C2B6BC | D8CED2 | 5A2E48 | E2D2D8 | 7A5A48 |

The implementer is allowed to nudge a value ±2 hex steps for legibility, but no hue changes without re-review.

## Pro gating

No control-flow changes. `isPro: true` on each new palette is the entire gate — `PalettePickerSheet` already renders a lock and routes to the paywall on confirm for Pro palettes.

## Picker layout

Unchanged. `PalettePickerSheet`'s vertical scroll of full-width cards handles 13 entries fine. Verified the user is comfortable with longer scroll.

## Persistence

`@AppStorage("paletteID")` already stores the raw string. New palette IDs persist automatically. If a user has a Pro palette stored and lapses Pro (not currently possible — one-time purchase, but defensive), `Palette.with(id:)` still resolves it; runtime gating is enforced only at the picker.

## Testing

- Manual check in iPhone 16 Pro / iOS 26 simulator: open `PalettePickerSheet`, scroll all 13, tap each to preview live, confirm legibility on `BrewListView` (typography), `BagDetailView` (gradients), `NewBrewSheet` (form fields, `BrewTimer` color), `PaywallSheet` (confirms `accent`/`accentSoft` look right against Pro CTAs).
- No new unit tests. Palette additions are data-only and the existing observation flow is already covered.

## Risks

- **Visual regressions in feature views.** Several views (e.g., `BrewTimer`, `GradientButtonStyle`, `CatalogBeanCard`) compose multiple tokens. A new palette with an unbalanced ink ramp could look fine in isolation and broken in those views. Mitigation: manual sweep across the feature views listed above.
- **Picker scroll length.** 13 cards × ~110pt ≈ 1430pt — long but acceptable. If users complain, the follow-up is a 2-column grid, not a redesign.
- **Sage / Forest similarity.** Sage is intentionally lighter and more olive than Forest. If side-by-side they read as duplicates, Sage's accent should shift further toward yellow-olive.
