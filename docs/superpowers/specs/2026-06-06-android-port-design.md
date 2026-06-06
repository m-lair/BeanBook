# BeanBook for Android — Port Design

**Date:** 2026-06-06
**Status:** Design approved, pending spec review
**Scope of this spec:** Strategy + v1.0 (Core logging MVP) architecture for a native Android port of BeanBook. Later phases are outlined for context but are **out of scope** for the implementation plan that follows this spec.

## 1. Goal & constraints

- **Goal:** Ship BeanBook on Google Play as a real, long-term-maintained product alongside the iOS app.
- **Hard constraint:** The existing iOS app is **not modified**. SwiftData, SwiftUI, StoreKit, and project structure stay exactly as they are. We knowingly accept **two codebases**.
- **Chosen approach:** A **separate native Android app** in **Kotlin + Jetpack Compose**. The iOS app is the functional/behavioral spec; nothing is shared at the code level in v1.

### Why not a shared-codebase path (recorded for posterity)

Two Swift-on-Android paths were researched and rejected for this goal:

- **Official Swift SDK for Android (Swift 6.3, March 2026):** Real and supported, but covers only the Swift language + Foundation + business logic. **SwiftUI does not run on Android**, and **SwiftData is Apple-only**. It cannot carry BeanBook's UI or data layer.
- **Skip (skip.dev, open-sourced Jan 2026):** Reimplements SwiftUI on Jetpack Compose and is the only way to reuse SwiftUI. But its headline value is a *single shared codebase* — which evaporates here because the iOS app stays on SwiftData and is never restructured. A Skip app would be a second, separate Swift codebase with a younger toolchain, while still forcing a data-layer rewrite (no SwiftData support; SkipSQL/GRDB only) and a StoreKit replacement. No net win over idiomatic Kotlin given the "iOS untouched" constraint.

Conclusion: with two codebases inevitable, the second one should use the best-in-class native Android tooling.

## 2. Repository & project shape

- New independent project directory **`BeanBook-Android`** (sibling to `BeanBook`, matching the workspace convention that each subdirectory is its own project with its own git history).
- The iOS repo (`BeanBook`) is referenced for behavior and brand only. `docs/branding.md` and `docs/design.md` are treated as **cross-platform law** governing both apps.
- The only iOS artifact reused as data (in a later phase, not v1) is the pure-data `Resources/beans_catalog.json`.
- A **parity checklist** doc (`BeanBook-Android/docs/parity.md`) is maintained to prevent feature drift between platforms.

## 3. Technology mapping (iOS → Android)

| iOS (current) | Android (port) | Notes |
|---|---|---|
| SwiftUI | Jetpack Compose | Material3 as substrate, heavily re-themed (see §6) |
| SwiftData `@Model` | Room `@Entity` + DAO | Source of truth on-device, fully local |
| `@MainActor @Observable` store | `ViewModel` + `StateFlow` over a Room-backed repository | One repository per aggregate, mirroring the iOS stores |
| `@Environment` injection | **Manual DI** (constructor injection + a small `AppContainer` factory) | Chosen over Hilt for this app's size; easy to migrate to Hilt later |
| `NavigationStack` + `TabView` (`Tab`) | Navigation-Compose + bottom `NavigationBar` | Center "+" opens NewBrew, does not navigate |
| `@AppStorage` | Jetpack DataStore (Preferences) | `hasOnboarded`, `autoPrefillFromLast`, selected theme |
| `Theme` / `Palette` / `themeStore` | Custom Compose theme: palettes as Kotlin data + a `CompositionLocal`; light-locked | `midnight` is the single dark palette; app does not follow system dark mode |
| StoreKit (`ProEntitlement`) | Google Play Billing (one-time product) | **Phase 2**, out of v1 scope |
| CoreLocation (`LocationService`) | FusedLocationProvider | **Phase 3** |
| Local notifications (`NotificationManager`) | WorkManager + `NotificationManagerCompat` | **Phase 4** |

**Build targets:** Kotlin, Gradle Kotlin-DSL, version catalog (`libs.versions.toml`). `minSdk 26`, `targetSdk 36`.

## 4. Data layer (highest-risk lift)

Room schema mirrors the iOS schema `[Bag, Brew, BrewPreset]`. **Every column gets a default value**, mirroring the iOS convention (originally for CloudKit/migration; on Android it keeps Room migrations lightweight and intent identical).

### Entities

- **Bag** — `@Entity`. Fields: id (String UUID), name, roaster, `roastLevel` (enum), `processMethod` (enum), roastDate (epoch `Long?`), `isPinned` (Bool), notes, createdAt. `brews` exposed via Room `@Relation` (read side); write side uses `bagId` FK on Brew.
- **Brew** — `@Entity` with `bagId` foreign key (nullable, matching `Brew.bag: Bag?`). Fields (from iOS `Brew`): `method` (enum), `doseGrams` (Double), `yieldGrams` (Double), `brewTimeSeconds` (Int), `grindSetting` (String?), `waterTempC` (Double?), `rating` (Int?), `notes` (String?), `imageData` (blob?, a brew photo), `createdAt`. Index on `createdAt` (iOS declares `#Index<Brew>([\.createdAt])`). The `ratio` (yield/dose, formatted "1:2") and time/ratio formatters are **computed**, not stored — implement as Kotlin functions/extensions, not columns.
- **BrewPreset** — `@Entity`. **Included in v1** to back the Outcome step "save as recipe" toggle. The Recipes *browsing screen* is deferred; the entity ships now to avoid a later migration. Fields (from iOS `BrewPreset`): `name` (String), `method` (enum), `doseGrams`, `yieldGrams`, `brewTimeSeconds`, `grindSetting` (String?), `waterTempC` (Double?), `createdAt`. Note it does **not** carry rating, notes, or image — a preset is a target recipe, not a logged shot.

### Enums (Room `TypeConverter`s)

- **BrewMethod** — Kotlin `enum` carrying method defaults (`defaultDose`, `defaultYield`, etc.) and stepper ranges as properties, mirroring the iOS enum. Values: Espresso, Pour Over, French Press, AeroPress, Moka Pot, Cold Brew.
- **RoastLevel**, **ProcessMethod** — Kotlin enums.

### Repositories & invariants

Thin repositories over DAOs, the analog of the iOS stores:

- **BagRepository** — `create(...)`, `pin(bag)` enforcing the **single-pin invariant** in one transaction (unset all others, set one), `pinnedBag`.
- **BrewRepository** — `create(...)`, `mostRecent(): Brew?` (DAO query `ORDER BY createdAt DESC LIMIT 1`) for prefill hydration.
- **BrewPresetRepository** — `create(...)`.

Pro quota enforcement (`QuotaExceededError` equivalent) lives in repositories but is dormant in v1 (no Pro tier yet); the seam exists so Phase 2 adds enforcement without re-plumbing.

## 5. v1.0 scope — Core logging MVP

**In:** Bags, the 3-step brew log, brew list & detail, lean Today home, settings, themes, BrewPreset entity + save-as-recipe toggle.
**Out (later phases):** Pro/paywall, Stats, Shop/Discover, location, Recipes browsing screen, notifications.

### Navigation

Bottom `NavigationBar`: **Today** · **Beans** · **+** (center) · **Settings**. The "+" destination presents the NewBrew flow (modal/bottom-sheet style) rather than navigating a back-stack.

### Screens

- **Today (lean editorial home)** — recent shots + an entry point into the full chronological brew list. A simplified port of the iOS Today (not the full editorial surface); enough to feel like a home, not a bare list.
- **NewBrew (3-step flow)** — Context (method + bag) → Shot (dose, yield, time, grind, all visible) → Outcome (rating, notes, save-as-recipe). The Shot step surfaces dose/yield/time/grind; `waterTempC` is persisted in the model and may be entered via a secondary control or left to a later phase — **decide and note in the plan** (do not silently drop the column). The `imageData` brew photo is **deferred to a later phase** (camera/photo-picker + storage is its own work item); the column ships in v1 nullable so no migration is needed when it lands. Ports the full behavior contract:
  - **Cold start** lands on Context; **hot start** (`prefill`) lands on Shot with values prefilled.
  - **Hot-start surfaces:** RecentShotsStrip tap, brew-row long-press menu, BrewDetail "Brew this again." (RecipesView launch deferred with the Recipes screen.)
  - **`prefillSnapshot`** captured at hydration; per-field **Δ-caption** ("was 18 g") renders under any diverging field. Respects the system "reduce motion" setting.
  - **Bag pinning:** pinned bag wins over recency; a "Recent: [bag]" swap chip surfaces when pin and most-recent diverge.
  - **Auto-prefill** toggle (DataStore, default on) controls whether cold-start "+" hydrates from `mostRecent()` or from `BrewMethod` defaults.
- **Beans (bag list)** — pinned bag floats to top with a pin glyph; long-press → Pin/Unpin. Detail screen lists the bag's brews. Add/edit sheet with a graphical roast-date picker.
- **Brew list & detail** — chronological list (the "all brews" surface), RecentShotsStrip, save-as-recipe entry when presets exist, long-press "Brew again". Detail shows a single brew with "Brew this again".
- **Settings** — General / Brewing (auto-prefill toggle) / Data, plus theme selection.

### Theming

All palettes ported as Kotlin data; `Theme.*`-equivalent accessors resolve through a `CompositionLocal` holding the current palette. App is **light-locked** (ignores system dark mode); `midnight` is the single intentional dark palette, selectable manually. No hardcoded colors — every value comes from the palette, mirroring the iOS rule.

## 6. UI/design fidelity

BeanBook's look is editorial and custom; stock Material3 will look wrong. The Compose theme must encode BeanBook's tokens (color, type, spacing) from `design.md`, and list surfaces use scrolling column layouts (the iOS app deliberately uses `ScrollView`+`VStack`, not `List`, for editorial styling) rather than stock Material list items. Row-level actions use long-press context menus (the iOS app's `.contextMenu` analog), not swipe. Design fidelity is a first-class work item, not a finishing pass.

## 7. Testing & verification

- **Data layer:** JUnit + Room **in-memory DB** tests for the single-pin invariant, `mostRecent()`, default values, and FK behavior. Mirrors the iOS Swift Testing unit suite.
- **UI:** Compose UI tests (`androidx.compose.ui.test`) for the 3-step flow, hot-start/prefill hydration, and Δ-caption rendering. Analog of the iOS XCUITest suite.
- **Screenshot (optional):** Roborazzi snapshots to guard the custom theme against Material drift.
- Verification is on-device/emulator: a change is not "done" until it builds and the behavior is observed running, never asserted from code inspection.

## 8. Post-MVP phasing (out of scope for the v1 plan)

- **Phase 2 — Pro + Stats:** Google Play Billing one-time product, quota enforcement turned on in repositories, Stats screen behind the paywall. **Branding check required:** `branding.md` promises Family Sharing; Play's family-library rules for one-time in-app products differ from Apple Family Sharing — copy and eligibility must be reconciled before shipping Pro on Android.
- **Phase 3 — Shop/Discover:** catalog browsing (reuse `beans_catalog.json` directly), "Near you" via FusedLocationProvider.
- **Phase 4 — Recipes & polish:** Recipes browsing screen (entity already present), daily-reminder notifications, theme/animation polish to full parity.

## 9. Risks

1. **Design fidelity** — custom editorial look vs. stock Material3. Mitigation: theme tokens as a first-class deliverable; screenshot tests.
2. **Two-codebase drift** — features diverge over time. Mitigation: parity checklist + brand docs as cross-platform law.
3. **Play Billing parity (Phase 2)** — one-time-purchase semantics + Family Sharing promise differ from Apple. Mitigation: resolve before Phase 2 ships, flagged in §8.
4. **Toolchain learning curve** — first Android project in this workspace. Mitigation: manual DI and a small dependency set keep v1 surface area low.

## 10. Success criteria for v1

- Installable Android app on an emulator/device that can: create/edit/pin bags, log a brew through the 3-step flow (cold and hot start), view the brew list and detail, re-brew from prefill, save a recipe, and switch themes — all persisted locally via Room across launches.
- Data-layer invariants covered by passing instrumented tests.
- Visual parity with the iOS editorial design within the ported screens.
