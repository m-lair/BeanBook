# BeanBook — Agent workflow

How to work on BeanBook in an agent-first loop. This is the operating layer: `AGENTS.md` stays short, and this file explains how agents should gather context, plan, verify, and feed lessons back into the repo.

## Principles

- **Humans steer, agents execute.** Convert requests into concrete acceptance criteria, then let the agent inspect, edit, test, and report.
- **The repo is the system of record.** If a decision matters after this task, capture it in `docs/`, a checked-in plan, or executable tooling.
- **Progressive disclosure beats giant prompts.** Start from `AGENTS.md`, then read the specific doc for the change: brand, design, architecture, quality, or an active plan.
- **Make failures legible.** When an agent gets stuck, improve the harness: add a command, doc, test, or invariant that makes the next run less dependent on memory.
- **Prefer mechanical guardrails.** If a rule can be checked by a script, test, or CI job, encode it there instead of only writing it as prose.

## Context map

Use this order unless the task clearly points elsewhere:

1. `AGENTS.md` — entry point, build commands, high-signal project rules.
2. `docs/architecture.md` — source of truth for data flow, stores, models, navigation, and backend status.
3. `docs/design.md` — UI tokens, layout patterns, component rules.
4. `docs/branding.md` — copy, naming, Pro positioning.
5. `docs/quality.md` — invariants, verification ladder, known harness gaps.
6. `docs/superpowers/plans/active/` — checked-in execution plans for larger work.
7. `docs/superpowers/specs/` — product or design specs that back plans.

## Task loop

For small changes, keep the loop lightweight:

1. Inspect the relevant files and docs.
2. State the acceptance criteria in the working notes or PR summary.
3. Make the smallest coherent change.
4. Run the narrowest useful verification from the ladder in `docs/quality.md`.
5. Update docs only if behavior, architecture, commands, or user-facing copy changed.

For larger or ambiguous work, create an active plan under `docs/superpowers/plans/active/YYYY-MM-DD-short-name.md` with:

- Goal and non-goals.
- Files or modules expected to change.
- Step-by-step checklist.
- Verification plan.
- Open questions and decisions.

Move completed plans to `docs/superpowers/plans/completed/` only when the implementation and verification are done.

## Reviews

Review with a bug-first posture:

- Prioritize correctness, regressions, missing verification, data loss, concurrency issues, and user-visible behavior.
- Do not invent style findings. If the issue is taste, encode the taste in `docs/design.md` or leave it out.
- For SwiftUI changes, verify parent layout constraints before restyling child components.
- For stale data bugs, inspect refresh and cache paths before changing loading copy.
- For Pro copy, re-read `docs/branding.md` and preserve one-time-purchase positioning.

## Feedback capture

When a task reveals reusable knowledge:

- Update `docs/architecture.md` for system shape or source-of-truth changes.
- Update `docs/design.md` for UI patterns or token decisions.
- Update `docs/branding.md` for copy rules or Pro positioning.
- Update `docs/quality.md` for new invariants, verification commands, or recurring failure modes.
- Add or update a script when repeated manual checks can become executable.

Do not duplicate the same rule across every file. Put it in the narrowest source of truth and link to it from `AGENTS.md` only when it is needed in the default context.
