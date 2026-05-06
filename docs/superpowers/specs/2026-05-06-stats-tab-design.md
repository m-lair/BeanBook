# Stats Tab - Design

**Date:** 2026-05-06
**Scope:** Replace the top-level Recipes tab with a Pro-gated Stats tab, and resurface saved recipes from Brews.

## Goal

Add a first-class Stats destination that shows what the user has brewed and what has been working. The feature should feel like a quiet personal ledger, not an analytics dashboard.

Stats are a BeanBook Pro feature. The locked state must lead with one-time purchase positioning and make the value clear without turning the screen into vague marketing.

## Non-goals

- No social, comparison, leaderboard, or benchmark stats.
- No streaks, goals, encouragement loops, or achievement language.
- No global "coffee score" or generated performance judgment.
- No Firebase, account, cloud sync, or backend dependency.
- No rich charting library. V1 uses simple SwiftUI marks and rows.
- No major Recipes rewrite. Existing `RecipesView` stays and moves behind a Brews entry point.

## Navigation

The main tabs become:

1. Brews
2. Bags
3. Stats
4. Shop

The center "+" keeps its current behavior and still presents `NewBrewSheet`.

`RecipesView` leaves the tab bar. Brews gets a `Saved recipes` entry point near the existing recent-shot area because saved recipes are primarily about repeating a brew. Tapping it opens the existing recipes list in a navigation destination or sheet, depending on the least invasive fit with current `BrewListView` navigation.

## Stats states

### Populated Pro

This is the fully unlocked state for users with enough brew history.

Header:

- Eyebrow: rolling window metadata, such as `30 days / since Mar 27`
- Optional small `Pro` chip
- Title: `Stats`
- Body: `A quiet ledger of what you've brewed and what's been working.`

Overview:

- Total brews in the window
- Active bags in the window
- Favorite method
- Average rating

Trend:

- A compact last-30-days brew strip.
- Bars show daily brew counts.
- Labels are minimal: start date, today, and total count.
- No goals or streak language.

What is working:

- Highest-rated recent brews.
- Best bag by average rating once there is enough data.
- Best saved recipe if recipes exist.
- This section should answer "what should I brew again?"

By bag:

- Recent or active bags listed as compact rows.
- Each row shows brew count, average rating, last brewed date, and a useful brew ratio or method summary.
- V1 can stay inline. A bag stats detail screen is a later feature.

Dial-in:

- Focus on the current pinned bag when one exists; otherwise use the most recently brewed bag.
- Show the last several espresso shots as `dose -> yield / time / rating`.
- Subtle change indicators can show movement from shot to shot, but should not claim causation.

### Locked non-Pro

The locked state is a dedicated BeanBook Pro screen.

Header:

- Eyebrow: `BeanBook Pro`
- Title: `Stats`
- Body: `Stats are included with BeanBook Pro - a one-time purchase that also unlocks unlimited bags and exports.`

Content:

- Four short rows: Overview, What's working, By bag, Dial-in.
- Each row has a number and one plain description.
- CTA uses existing paywall/pro purchase flow and must include one-time purchase copy near the action.

### Sparse data

Sparse data appears when there are brews, but not enough history for meaningful patterns.

Show:

- The overview numbers that are available.
- `Favorite method` as an em dash with `more data needed` when the sample is too small.
- A simple card: `More patterns appear as you log.`
- A `Logged so far` section with recent brew rows.

Avoid hiding all content just because charts are not ready.

### No brews

The empty state is simple and direct.

Title:

- `Nothing to show yet.`

Body:

- `Log your first brew and patterns will start to appear here - what's working, by bag, dial-in.`

CTA:

- `Log a brew`
- Uses the same new-brew presentation path as the center "+".

## Data model and derivation

Stats are derived from existing local SwiftData models:

- `Brew`
- `Bag`
- `BrewPreset`

No new stored model is required for V1.

The Stats view should compute lightweight derived values from fetched local data:

- Rolling 30-day brew count.
- Active bags in the rolling window.
- Favorite method by count.
- Average rating among rated brews.
- Daily brew counts for the chart strip.
- Recent high-rated brews.
- Bag summaries: brew count, average rating, last brewed date, method or ratio summary.
- Dial-in rows for the pinned or most recent bag.

Keep the derivation close to the feature unless it starts to spread. If the view becomes hard to read, introduce a small `StatsSummary` value type and a pure builder that can be unit tested.

## Pro gating

Stats are Pro-only, but the tab is visible to everyone.

For non-Pro users:

- Show the locked state.
- Route purchase through the existing `PaywallSheet`.
- Preserve Pro positioning: one-time purchase, unlimited everything, future Pro features included, Family Sharing where space allows.

For Pro users:

- Show stats immediately.
- Do not show upsell copy inside populated stats.

## Visual direction

Follow the approved mock:

- Editorial serif title.
- Tiny uppercase metadata.
- Hairline dividers.
- Compact numeric overview.
- Minimal charting.
- Paper-like surfaces from `Theme.*`.
- No busy dashboard grid.

Use existing design primitives where possible:

- `Theme.background`
- `Theme.card`
- `Theme.accent`
- `Theme.accentSoft`
- `Theme.rule`
- `Eyebrow`
- `HairRule`
- Existing pill button styles

The 30-day strip should be stable across small and large counts. Use a fixed-height row of bars and clamp bar height so one high-volume day does not flatten the rest of the chart into noise.

## Copy

Copy must follow `docs/branding.md`.

Use:

- `Stats`
- `Overview`
- `What's working`
- `By bag`
- `Dial-in`
- `More patterns appear as you log.`
- `Nothing to show yet.`
- `Log a brew`

Avoid:

- `Insights`
- `Performance`
- `Score`
- `Streak`
- Celebration or praise copy

## Error and edge handling

- No brews: empty state.
- One to two brews: sparse state.
- No rated brews: show average rating as an em dash with `rate a brew to see this`.
- No bag on a brew: exclude it from by-bag stats, but keep it in total brew counts.
- No recipes: omit best recipe rows instead of showing a blank placeholder.
- Non-espresso methods: include them in overview and by-bag summaries; dial-in can be espresso-first for V1.

## Testing

Automated:

- Add focused Swift Testing coverage if a pure stats builder is introduced.
- Cover empty, sparse, populated, unrated, and mixed-bag inputs.

Manual:

- Non-Pro account sees locked Stats with one-time purchase positioning.
- Pro account with no brews sees the empty state and `Log a brew` opens `NewBrewSheet`.
- Pro account with sparse brews sees available overview plus `Logged so far`.
- Pro account with populated data sees overview, trend, what is working, by-bag, and dial-in.
- Brews tab exposes saved recipes and opens the existing recipes screen.
- Dynamic Type up to the app-supported limit does not overlap overview values, chart labels, or bottom tab content.

## Risks

- **Stats can feel too dashboard-heavy.** Mitigation: keep V1 to one compact overview, one trend strip, and editorial rows.
- **Sample sizes can mislead.** Mitigation: sparse-state copy and thresholds before claiming best bag or favorite method.
- **Recipes may become hidden.** Mitigation: place `Saved recipes` near recent brews, where repeat-brew behavior already lives.
- **Stats derivation can bloat the view.** Mitigation: extract pure summary building once the view starts carrying nontrivial computation.
