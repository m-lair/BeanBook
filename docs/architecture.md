# BeanBook — Architecture

What lives where, and why. Reflects the app's current state (3-step brew log, prefill snapshot, bag pinning, recent-shots strip, Pro stats).

## Targets

- **`BeanBook`** — the iOS app. SwiftUI + SwiftData, Swift 6 strict concurrency.
- **`BeanBookTests`** — Swift Testing.
- **`BeanBookUITests`** — XCTest only.
- **`scripts/`** — agent-facing verification harness. `agent-preflight.sh` checks repo invariants; `validate-catalog.js` validates bundled catalog data.

## Data layer

### SwiftData is the source of truth

`BeanBookApp.swift` constructs a single `ModelContainer` with the schema `[Bag, Brew, BrewPreset]` and injects via `.modelContainer(...)`. The iOS target is **fully local** — no Firebase SDK, no backend. All reads and writes are on-device.

### Models (`Core/Models/`)

| Type | Kind | Notes |
|---|---|---|
| `Bag` | `@Model` | `isPinned: Bool` controls the pin-as-default behavior. `brews: [Brew]` is the inverse of `Brew.bag`. |
| `Brew` | `@Model` | `bag: Bag?` back-reference. Methods, dose, yield, time, grind, water temp, rating, notes. |
| `BrewPreset` | `@Model` | Saved recipes. Created from the Outcome step toggle in `NewBrewSheet`. |
| `BrewMethod` | enum | Espresso, Pour Over, French Press, AeroPress, Moka Pot, Cold Brew. Holds method defaults (`defaultDose`, `defaultYield`, etc.) and ranges for steppers. |
| `RoastLevel`, `ProcessMethod` | enum | Bag metadata. |
| `CatalogBean` | Codable struct | **Not** `@Model` — bundled catalog entries. Imported into SwiftData via `BagStore.import(from:)`. |

**Convention:** every stored property gets a default value. Required for CloudKit-compatible schemas and lightweight migration. Don't break this when adding fields.

### Stores (`Core/Stores/`)

Thin `@MainActor @Observable` wrappers over `ModelContext`. Constructed once in `BeanBookApp.init()`, injected via `.environment(...)`. Never use as singletons.

| Store | Notable APIs |
|---|---|
| `BagStore` | `create(...)`, `pin(_:)` (single-pin invariant), `pinnedBag` |
| `BrewStore` | `create(...)`, `mostRecent() -> Brew?` (used by prefill hydration) |
| `BrewPresetStore` | `create(...)` |

Pro quotas are enforced at the store level — `create(...)` throws `QuotaExceededError` when the free tier is full. The presenting view catches and surfaces `PaywallSheet`.

### Services (`Core/Services/`)

| Service | Role |
|---|---|
| `CatalogService` | Loads `Resources/beans_catalog.json` at init. Powers the Shop/Discover tab. |
| `LocationService` | CoreLocation wrapper. Powers the "Near you" section in Shop. |
| `NotificationManager` | Local notifications (daily reminder). |

## App layer

### Entry (`BeanBookApp.swift`)

- Constructs `ModelContainer`, `ProEntitlement`, all stores.
- Injects everything via `.environment(...)`.
- Locks `.preferredColorScheme(.light)` at root so the app does not follow system dark mode. The manual `Midnight` palette is the only dark appearance.
- Branches on `hasOnboarded`: shows `OnboardingView` or `RootTabView`. Same environment chain applies to both branches.

### Root navigation (`App/RootTabView.swift`)

Top-level `TabView` using iOS 18's `Tab` initializer: **Today**, **Beans**, **Stats**, and **Shop**. Each content tab wraps in its own `NavigationStack`. The center "+" tab triggers `NewBrewSheet` rather than navigating.

## Feature layer

Each feature lives under `Features/{Name}/`, with shared subcomponents in a `Components/` subfolder when they're reused only within that feature.

### Brews (`Features/Brews/`)

The dominant feature. Recent rework collapsed a 5-step wizard into 3 steps with prefill-from-last and hot-start.

| File | Role |
|---|---|
| `BrewListView.swift` | The all-brews destination. Renders the `RecentShotsStrip`, a `Saved recipes` entry when presets exist, and a `.contextMenu` "Brew again" on each row. Hot-start uses `.sheet(item: $hotStartBrew)`. |
| `BrewDetailView.swift` | Single-brew detail; "Brew this again" enters `NewBrewSheet(prefill:)`. |
| `NewBrewSheet.swift` | The 3-step flow: **Context** (method + bag) → **Shot** (dose, yield, time, grind, all visible) → **Outcome** (rating, notes, save-as-recipe). |
| `Components/MethodPicker.swift` | Method chip row used in step 0. |
| `Components/BrewTimer.swift` | Count-up / count-down timer used in step 1. |
| `Components/RecentShotsStrip.swift` | Horizontal `LazyHStack` of last 5 brews. Tap = hot-start. |

**Hot-start contract:** when `NewBrewSheet` is presented with a non-nil `prefill: Brew`, `hydrate()` snapshots the brew's values into `prefillSnapshot` and starts at `step = 1` (Shot). Used by the recent strip, the brew-row context menu, `BrewDetailView`'s "Brew this again," and `RecipesView`'s preset-launch.

**Auto-prefill:** `@AppStorage("autoPrefillFromLast")` (default `true`) controls whether cold-start "+" hydration pulls from `BrewStore.mostRecent()` or falls back to `BrewMethod.default*`. Wired from the toggle in `SettingsView`.

**Δ-from-last hint:** `prefillSnapshot` is captured once during hydrate and compared against current state per field. Fields that diverge render a `DeltaCaption` ("was 18 g") under the label. Respects `accessibilityReduceMotion`.

### Bags (`Features/Bags/`)

| File | Role |
|---|---|
| `BagListView.swift` | The Beans tab (the user-facing label for bags). Pinned bag floats to top with a `pin.fill` glyph. Long-press → "Pin as default" / "Unpin" via `BagStore.pin(_:)`. |
| `BagDetailView.swift` | Detail. Lists the bag's brews. |
| `NewBagSheet.swift` | Add/edit bag. Includes `RoastDatePickerSheet` (graphical `DatePicker` in a custom-headered sheet). |

### Shop / Discover (`Features/Shop/`)

| File | Role |
|---|---|
| `ShopView.swift` | Browses `CatalogService.beans`. Featured card at top (forest-on-sage editorial card with a layered tilted swatch), "Near you" section if location is granted, then filtered list. `.accentPill` "Add to beans" imports a catalog entry into SwiftData via `BagStore`. |

### Stats (`Features/Stats/`)

Stats are a BeanBook Pro feature, but the tab is visible to everyone. Non-Pro users see a locked state that leads with one-time-purchase positioning and routes to `PaywallSheet`.

| File | Role |
|---|---|
| `StatsView.swift` | The Stats tab. Renders locked, empty, sparse, and populated states from local SwiftData data. Presents `NewBrewSheet` from the empty state and `PaywallSheet` from the locked state. |
| `StatsSummary.swift` | Pure aggregation builder over `[Brew]`, `[Bag]`, and `[BrewPreset]`. Derives 30-day totals, active bags, favorite method, average rating, daily brew counts, working brews, by-bag summaries, and dial-in rows. |

### Recipes (`Features/Recipes/`)

| File | Role |
|---|---|
| `RecipesView.swift` | Lists `BrewPreset`s. Tapping a preset constructs a temp `Brew` and presents `NewBrewSheet(prefill:)`. Recipes are no longer a top-level tab; they are surfaced from Brews because they primarily support repeating what worked. |

### Onboarding (`Features/Onboarding/`)

Two-step flow:

1. **Intro.** Brand statement + three feature bullets + "Get started."
2. **Beans handoff.** "Add a bag I own" (presents `NewBagSheet`), "Browse roasters" (presents `ShopView` in a sheet), or skip. The CTA copy flips between "Skip for now" and "Start brewing" based on whether at least one bag exists.

Completion: tapping "Skip for now" / "Start brewing" calls `onStart`, which the app uses to set `hasOnboarded = true`.

### Settings (`Features/Settings/`)

`SettingsView.swift` — Pro upsell row at top (one-time-purchase positioning per `branding.md`), then General, Brewing, Data, and saved recipes sections.

The Pro row leads with **"One-time purchase · Unlimited everything · Future features included"** as its subtitle. This copy is brand-load-bearing — see `branding.md` before changing.

## Pro tier (`Pro/`)

| File | Role |
|---|---|
| `ProEntitlement.swift` | `@Observable` StoreKit wrapper. `isPro: Bool`, `purchaseState`, `purchase()`, `restore()`. |
| `PaywallSheet.swift` | The full paywall. One-time-purchase positioning is non-negotiable (hero "One purchase. / Yours forever.", value-prop chip strip, CTA reads "Unlock Pro · $X once"). |

`ProQuota` defines the free-tier ceilings (`bags`, `brews`, `recipes`). Stores enforce. Views surface `PaywallSheet` on `QuotaExceededError`.

Stats are Pro-only but read from existing local data. They do not change the free core logging flow and do not introduce sync or backend dependencies.

## Theme (`Shared/Theme/`)

- `Theme.swift` — color/spacing/type accessors. All resolve through `themeStore.palette`.
- `Theme/Palette.swift` — curated, distinct manual palettes. `forest` is free; all other palettes are Pro. `midnight` is the only dark palette.
- `themeStore` — process-wide `@Observable` source of truth. Mutating `palette` invalidates dependent views via Observation.

See `design.md` for tokens and patterns.

## Testing

- **Swift Testing** for unit tests (`BeanBookTests`).
- **XCTest** for UI tests (`BeanBookUITests`).

Run from the project root:

```bash
xcodebuild test -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

## Sensitive files — do not commit

No sensitive files in the repo today. The iOS target is fully local with no API keys or service accounts.
