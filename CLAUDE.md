# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

BeanBook — iOS app for tracking coffee bags and brews. SwiftUI + SwiftData on the client, Firebase Cloud Functions (TypeScript) on the backend.

## Build & Run

```bash
# Build for simulator (default to iPhone 16 Pro per workspace convention)
xcodebuild -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Tests (BeanBookTests uses Swift Testing; BeanBookUITests uses XCTest)
xcodebuild test -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Single test (Swift Testing)
xcodebuild test -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:BeanBookTests/<SuiteName>/<testName>
```

Cloud Functions (`functions/`, Node 18, TypeScript):

```bash
cd functions
npm run build         # tsc → lib/
npm run serve         # build + firebase emulators:start --only functions
npm run deploy        # firebase deploy --only functions
npm run logs
```

`functions/config/serviceAccountKey.json` is required at runtime and must not be committed.

## Architecture

### iOS client — SwiftData is the source of truth

`BeanBookApp.swift` constructs a single `ModelContainer` with the schema `[Bag, Brew, BrewPreset]` and injects it via `.modelContainer(...)`. There is **no Firebase SDK in the iOS target** today — the Cloud Functions code (Firestore triggers, FCM) is not yet wired to the client. Don't assume reads/writes propagate to Firestore.

Layering (`BeanBook/`):

- `App/RootTabView.swift` — three-tab `TabView` (Brews, Bags, Shop) using iOS 18 `Tab` API, each wrapped in its own `NavigationStack`.
- `Core/Models/` — `@Model` types: `Bag`, `Brew` (with `bag: Bag?` back-reference; `Bag.brews` declares the inverse via `@Relationship(deleteRule: .nullify, inverse: \Brew.bag)`), plus enums `BrewMethod`, `RoastLevel`, `ProcessMethod`, and `BrewPreset`. `CatalogBean` is a non-`@Model` Codable type used only for the bundled catalog.
- `Core/Stores/` — `@MainActor @Observable` thin wrappers over `ModelContext` (`BagStore`, `BrewStore`). Stores are constructed from a `ModelContext` rather than injected as singletons.
- `Core/Services/CatalogService.swift` — `@Observable` service that loads `Resources/beans_catalog.json` at init. Injected app-wide via `.environment(catalog)`. The Shop tab browses this static catalog and imports entries into SwiftData via `BagStore.import(from:)`.
- `Features/{Bags,Brews,Settings,Shop}/` — feature views and sheets. `Features/Brews/Components/` holds composable brew-entry inputs (`MethodPicker`, `MethodParametersSection`, `TimerInputField`).
- `Shared/Theme.swift` — single source for color palette, spacing, radius, shadow, and gradients. New UI should pull from `Theme.*` rather than hardcoding values. App is locked to `.preferredColorScheme(.light)` and `.tint(Theme.primary)` at the root.
- `Shared/SharedViews/` — reusable UI primitives (`GlassCard`, `GradientButtonStyle`, `LabeledField`, `SectionHeader`, `StarRating`, `TastingNotesEditor`).
- `Managers/NotificationManager.swift` — local notification handling.

### Backend — Cloud Functions (`functions/src/index.ts`)

Single deployed function: `notifyBrewOwnerOnFavorite`, an `onDocumentUpdated` Firestore trigger on `coffeeBrews/{brewId}` that diffs `saveCount` and sends an FCM push to the brew creator's `fcmToken` from their `users/{uid}` doc. The collection names (`coffeeBrews`, `users`) and the `fcmToken` field are the contract for any future iOS sync work.

## Conventions

- Swift 6, strict concurrency. Stores/services are `@MainActor @Observable`.
- iOS 18+ APIs: `Tab` initializer in `TabView`, `NavigationStack`, `.task()` over `.onAppear`.
- `@Environment` injection (e.g. `CatalogService`) — no singletons.
- SwiftData models give every stored property a default value (required for CloudKit-compatible schemas and lightweight migration); preserve that pattern when adding fields.
- Swift Testing for unit tests (`BeanBookTests`), XCTest only for UI tests (`BeanBookUITests`).

## Sensitive files — do not commit

- `functions/config/serviceAccountKey.json`
- Anything under `functions/node_modules/`
