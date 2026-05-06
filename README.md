# BeanBook

A quiet logbook for the coffee you brew at home.

> No streaks. No social. No scoring algorithm.

iOS app for tracking coffee bags and shots — built for the home espresso enthusiast pulling one or two shots a day, with first-class support for dialing in a new bag.

## What it does

- **Log a brew in three steps.** Method + bag → dose, yield, time, grind → rating + notes. Every value prefilled from your last shot — change only what you changed.
- **Track your beans.** Origin, roast date, tasting notes, process. Linked to every shot.
- **Brew it again.** Tap a recent shot to log it again with the same dose, yield, time, and grind.
- **Dial in a new bag.** All four shot variables on one screen with "was 18 g" hints under any field that diverged from your last brew.

## Pro

A one-time purchase. No subscription, ever.

- Unlimited bags, brews, recipes (free-tier caps lifted).
- Future Pro features included when they ship — stats, export, themes.
- Family Sharing supported.

## Stack

- **iOS client** — Swift 6, SwiftUI, SwiftData. iOS 18+. Light mode only.
- **Backend** — Firebase Cloud Functions (TypeScript / Node 18) under `functions/`. Currently a single FCM trigger; not yet wired to the iOS client.

## Build

```bash
xcodebuild -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' build
```

```bash
xcodebuild test -project BeanBook.xcodeproj -scheme BeanBook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

Cloud Functions:

```bash
cd functions
npm run build
npm run serve   # firebase emulators:start --only functions
npm run deploy
```

## Documentation

- [`docs/branding.md`](docs/branding.md) — voice, tone, naming, Pro positioning. Read before writing copy.
- [`docs/design.md`](docs/design.md) — design system: palette, type, spacing, components, motion, accessibility. Read before adding UI.
- [`docs/architecture.md`](docs/architecture.md) — what lives where, current state. Read before adding features.
- [`docs/agent-workflow.md`](docs/agent-workflow.md) — agent-first task loop, plans, reviews, feedback capture.
- [`docs/quality.md`](docs/quality.md) — verification ladder, structural invariants, known harness gaps.
- [`CLAUDE.md`](CLAUDE.md) — agent-facing project guide (build commands, conventions, sensitive files).

Quick agent preflight:

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

## Website

The marketing landing lives at `docs/index.html` and is served via **GitHub Pages from the `/docs` folder on `main`**. To preview locally:

```bash
cd docs && python3 -m http.server 8000
# open http://localhost:8000
```

Enable Pages: GitHub repo → Settings → Pages → **Source: Deploy from a branch** → **Branch: main · Folder: /docs**.

`.nojekyll` is included so the markdown docs aren't Jekyll-themed.

## Sensitive files — do not commit

- `functions/config/serviceAccountKey.json` — Firebase service account.
- Anything under `functions/node_modules/`.

## Repo layout

```
BeanBook/                 iOS target
├── App/                  RootTabView, app entry
├── Core/                 Models, Stores, Services
├── Features/             Brews, Bags, Shop, Onboarding, Recipes, Settings
├── Pro/                  ProEntitlement, PaywallSheet
└── Shared/               Theme, palettes, primitives, extensions

functions/                Firebase Cloud Functions (TypeScript)
docs/                     Brand + design + architecture docs, GitHub Pages site
                          (index.html, styles.css, logo.svg, wordmark.svg)
```
