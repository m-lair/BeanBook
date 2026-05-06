# BeanBook — Quality and guardrails

Agent velocity is useful only if the repo stays legible. This file records the invariants and verification loops that should be easy for agents to run and improve.

## Current quality bar

| Area | Bar | Current harness |
|---|---|---|
| Swift build | The app target builds from a clean checkout. | `./scripts/agent-verify.sh build` |
| Swift tests | Unit tests use Swift Testing; UI tests use XCTest only. | `./scripts/agent-verify.sh test` |
| Functions build | TypeScript compiles without generated output drift. | `./scripts/agent-verify.sh functions` |
| Repo preflight | Agent-facing docs, sensitive-file rules, and core design guardrails are present. | `./scripts/agent-preflight.sh` |
| Design consistency | UI uses `Theme.*`, shared components, and light-mode-only assumptions. | `./scripts/agent-preflight.sh` blocks hardcoded `Color(hex:)` outside approved theme/shared semantic files; deeper review remains manual. |
| Brand consistency | Product copy is restrained and Pro is one-time-purchase first. | Documented in `docs/branding.md`; manual review. |

## Verification ladder

Pick the lowest rung that meaningfully covers the change. Move up when touching shared behavior, persistence, purchases, navigation, or release surfaces.

1. **Docs-only:** `./scripts/agent-verify.sh preflight`
2. **Swift compile:** `./scripts/agent-verify.sh build`
3. **Swift tests:** `./scripts/agent-verify.sh test`
4. **Functions:** `./scripts/agent-verify.sh functions`
5. **Manual app smoke:** launch on the default simulator and exercise the changed flow.
6. **Release-sensitive:** include StoreKit, onboarding, data persistence, and App Store copy checks as applicable.

If verification cannot run, report the exact blocker and the command that failed.

## Structural invariants

- SwiftData remains the iOS source of truth until architecture docs say otherwise.
- Stores are `@MainActor @Observable` wrappers over `ModelContext`, injected through environment.
- No singleton stores or hidden global state for app data.
- Every SwiftData stored property has a default value.
- The iOS target does not silently depend on Firebase SDKs.
- Pro quotas are enforced at the store boundary.
- Theme access goes through `Theme.*`; no new hex literals in feature views.
- Light mode remains locked at the app root.
- `BrewListView` and `BagListView` use `ScrollView` + `VStack`; row actions use context menus unless the screen is intentionally converted to `List`.

## Known harness gaps

- There is no Swift formatter or linter committed yet.
- There is no broad SwiftUI style linter for feature-view layout patterns.
- There is no simulator UI smoke script for the core brew-log path.
- CI runs preflight, app build, and functions build through `scripts/agent-verify.sh`; local test runs remain the stronger signal.
- Documentation freshness is manual except for `scripts/agent-preflight.sh`.

Promote a gap into tooling when it causes a real miss or repeated review comment.
