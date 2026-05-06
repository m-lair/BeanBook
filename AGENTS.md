# AGENTS.md

Guidance for Codex (Codex.ai/code) when working in this repository.

## Project

**BeanBook** — iOS app for tracking coffee bags and shots. SwiftUI + SwiftData on the client, Firebase Cloud Functions (TypeScript) on the backend.

Read these before making non-trivial changes:

- [`docs/branding.md`](docs/branding.md) — **read before writing or changing copy.** Voice, tone, naming, and Pro positioning are load-bearing brand decisions.
- [`docs/design.md`](docs/design.md) — design tokens, type, spacing, components. Read before adding UI.
- [`docs/architecture.md`](docs/architecture.md) — current architecture in detail.
- [`docs/agent-workflow.md`](docs/agent-workflow.md) — how to run BeanBook in an agent-first workflow.
- [`docs/quality.md`](docs/quality.md) — verification ladder, invariants, and harness gaps.

## Build & run

Default simulator is **iPhone 16 Pro / iOS 26.0** (per workspace convention).

```bash
xcodebuild -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' build

# Tests (BeanBookTests = Swift Testing; BeanBookUITests = XCTest)
xcodebuild test -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'

# Single Swift Testing test
xcodebuild test -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -only-testing:BeanBookTests/<SuiteName>/<testName>
```

Cloud Functions (`functions/`, Node 18, TypeScript):

```bash
cd functions
npm run build      # tsc → lib/
npm run serve      # build + firebase emulators:start --only functions
npm run deploy
npm run logs
```

`functions/config/serviceAccountKey.json` is required at runtime and must not be committed.

Agent preflight:

```bash
./scripts/agent-preflight.sh
```

Agent verification:

```bash
./scripts/agent-verify.sh build
./scripts/agent-verify.sh test
./scripts/agent-verify.sh catalog
./scripts/agent-verify.sh functions
```

## Architecture (summary)

Full detail in [`docs/architecture.md`](docs/architecture.md). The shape:

- **SwiftData is the source of truth.** `BeanBookApp.swift` builds one `ModelContainer` (`[Bag, Brew, BrewPreset]`) and injects it. The iOS target has no Firebase SDK today — Cloud Functions exist but aren't wired to the client.
- **Stores are `@MainActor @Observable` wrappers** over `ModelContext`, injected via `.environment(...)`. No singletons. Stores enforce Pro quotas at `create(...)` and throw `QuotaExceededError`.
- **Theme.** All color goes through `Theme.*`, which resolves through `themeStore.palette`. The palette set is curated for distinct manual themes; `forest` is free/default and the rest are Pro. The app does not follow system dark mode — `.preferredColorScheme(.light)` stays locked — but `midnight` is the single intentional dark palette.
- **Three-tab `TabView`** (Brews, Bags, Shop) — center "+" presents `NewBrewSheet` rather than navigating.

### Brew log flow (recent rework)

`NewBrewSheet` is a 3-step flow: **Context** (method + bag) → **Shot** (dose, yield, time, grind) → **Outcome** (rating, notes, save-as-recipe).

- Cold start lands on Context. Hot start (`prefill: Brew?`) lands on Shot with values prefilled.
- Hot-start surfaces: `RecentShotsStrip` on the Brews tab, `.contextMenu` on each brew row, `BrewDetailView`'s "Brew this again," and `RecipesView` preset-launch — all converge on the same `prefill:` parameter.
- `prefillSnapshot` captures the prefill values; per-field `DeltaCaption` ("was 18 g") renders under any field that diverges.
- Bag pinning: `Bag.isPinned` + `BagStore.pin(_:)` (single-pin invariant). Pinned bag wins over recency; a "Recent: [bag]" swap chip surfaces if pin and most-recent diverge.

## Conventions

- **Swift 6**, strict concurrency. Stores/services are `@MainActor @Observable`.
- **iOS 18+ APIs**: `Tab` initializer in `TabView`, `NavigationStack` with `NavigationLink(value:)`, `.task()` over `.onAppear`.
- **`@Environment` injection** for shared state — never singletons.
- **SwiftData defaults.** Every stored property gets a default value (CloudKit-compatible schemas + lightweight migration). Preserve this when adding fields.
- **Manual theme only.** Don't add system dark-mode variants. `midnight` is the one intentional dark palette, while the app remains locked to `.preferredColorScheme(.light)` — see `branding.md`.
- **Theme tokens, not hex literals.** If a value isn't in the palette, the design needs review, not a hardcoded color.
- **Swift Testing** for unit tests (`BeanBookTests`); **XCTest** only for UI tests (`BeanBookUITests`).
- Treat repo docs as the system of record. If a task changes architecture, brand rules, design patterns, commands, or recurring workflow, update the relevant doc in the same change.

### List rows

Both `BrewListView` and `BagListView` use `ScrollView` + `VStack` for editorial styling, **not `List`**. As a result `.swipeActions` is a no-op there — use `.contextMenu` for row-level actions instead. If you need actual swipe, that's a per-screen list-conversion conversation, not a one-line modifier.

## Pro positioning

The app's commercial model is a **one-time purchase**. This message must lead wherever Pro is mentioned:

- "One-time purchase," "Pay once," "Yours forever."
- Always pair price with "once" — `Unlock Pro · $X once`, not `Unlock for $X`.
- Mention Family Sharing.
- Future Pro features are included with the existing one-time purchase. There is no "premium plus" tier and there will not be.

Don't add Pro mentions to onboarding — `branding.md` explains why.

## Sensitive files — do not commit

- `functions/config/serviceAccountKey.json`
- Anything under `functions/node_modules/`
