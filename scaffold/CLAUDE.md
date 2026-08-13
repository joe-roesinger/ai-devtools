# CLAUDE.md (root)

This file gives Claude big-picture orientation for this repository. It is deliberately lean — subdirectory `CLAUDE.md` files add local convention detail as Claude traverses into them (see `examples/subdir-CLAUDE.md.example`), and Claude loads them additively. Don't inline subsystem-specific detail here; put it in the relevant subdirectory instead.

See `docs/research/ai-agents-legacy-codebases-2026.md` in the tooling repo this scaffold came from for the research this file operationalizes.

## Repo map

<!-- Fill in for your actual repo. Example shape: -->
- `<fill in>` — <what it is, why it exists>
- `<fill in>` — <what it is, why it exists>

## Known landmines

<!-- Seeded manually at first, then grown over time by the `codebase-recon` skill and the
     stop-hook documentation feedback loop. Keep entries short and specific: what breaks,
     why, and what to do instead. -->
- `<fill in>`

## Running tests and lint (global)

<!-- Top-level commands only. Subdirectories may define narrower/faster commands that
     override these — check for a local CLAUDE.md before assuming these apply. -->
- Test: `<fill in>`
- Lint: `<fill in>`

## Before you edit anything unfamiliar

- Prefer **Plan Mode** or the `codebase-recon` skill first. This codebase's test coverage is not a reliable signal of behavior coverage — treat passing tests as necessary, not sufficient, evidence that something works.
- Before refactoring behavior in code that is weakly tested, run the `characterization-test` skill first to pin current behavior. Do not trust AI-drafted characterization tests until you've executed and reviewed them yourself.

## Before starting a new feature

- **Greenfield** (new project, or a genuinely new module with no existing behavior to protect): go
  straight to `feature-spec` then `tdd-implement`. No recon or characterization step is needed —
  there's no tribal-knowledge gap or existing-behavior risk on code that doesn't exist yet.
- **Legacy** (feature touches an existing module): run `feature-spec` first — it checks for
  existing `codebase-recon`/local-`CLAUDE.md` coverage of the touched area and flags the gap if
  missing. If the task modifies existing weakly-tested behavior (not just adds new code),
  `tdd-implement` hands off to `characterization-test` first. Prefer incremental rollout (feature
  flags / strangler-fig) over a single big-bang merge.

See `docs/research/agentic-feature-development-2026.md` (in the tooling repo this scaffold came
from) for the research behind this split.

This applies identically when you're triggered remotely via `@claude` on a GitHub issue matching
`.github/ISSUE_TEMPLATE/feature-request.md` — run `feature-spec` first, then `tdd-implement`,
rather than implementing directly from the issue body. See
`docs/research/remote-agents-2026.md` for why this composes without any extra workflow-level
logic (the GitHub Action reads this file the same way a local session does).

## Skills available

- `characterization-test` — draft golden-master tests that pin current behavior before a refactor.
- `codebase-recon` — read-only exploration of an unfamiliar module; produces a knowledge doc and surfaces unknowns explicitly.
- `coverage-guided-routing` — generic stub for routing to existing tests via coverage data instead of manual exploration (adapt to your repo's coverage tool).
- `feature-spec` — write a version-controlled spec for a new feature before any code is written.
- `tdd-implement` — implement a spec'd task via a red-green-refactor TDD loop.

## Subagents available

- `legacy-explorer` — read-only exploration subagent (Read/Grep/Glob only) for delegated recon tasks.
- `feature-implementer` — write-capable subagent (Read/Grep/Glob/Edit/Write/Bash) that implements one spec'd task at a time via `tdd-implement`.

## Model & token-budget guidance

See `docs/research/token-cost-optimization-2026.md` (in the tooling repo this scaffold came from)
for the research behind this section.

- **Route down, not up, for delegated work.** `legacy-explorer` runs on `haiku` because recon is
  high-volume, low-reasoning search/read work; `feature-implementer` is pinned to a mid-tier model
  rather than inheriting whatever model is driving the main session, so a heavier orchestrator
  model never gets used for routine TDD-loop grunt work by accident.
- **This file is cache-prefix content, not a one-time cost.** It (and every skill's frontmatter
  description) is re-sent on every request of every session. Keep it to roughly one to two pages;
  push anything longer into a subdirectory `CLAUDE.md` or a skill body, which only loads when
  actually relevant.
- **Prefer subagent delegation over manual exploration in the main thread** for anything that would
  read many files — not only for context cleanliness (the original reason `legacy-explorer` exists)
  but because a subagent's context is isolated and discarded on exit, so exploration tokens don't
  accumulate in the persistent, cache-relevant main session.
- **Compact long sessions before switching tasks.** A session that ran a full multi-iteration
  `tdd-implement` loop and is about to move to an unrelated task benefits from `/compact` first
  rather than carrying dead context (and its token cost) forward.

## Documentation feedback loop

At session end, a stop hook may propose additions to this file or to a subdirectory `CLAUDE.md`, based on what was learned during the session. These are **suggestions only** — they land in `.claude/proposed-updates/`, are never auto-applied, and never auto-committed. Review and merge them deliberately.

## Architecture guidance

If a change to this codebase's structure comes up (e.g. "should we split this into
microservices to make it easier to work with"), be skeptical of decomposition as an
AI-tooling improvement specifically. Research indicates agents reason better when business
logic, transactions, and dependencies are co-located — splitting logic across service
boundaries tends to fragment context rather than shrink the problem, and can make AI-assisted
work on this codebase *harder*, not easier. Prefer modularizing in place (clear internal
module boundaries, one subdirectory `CLAUDE.md` per module — see
`examples/subdir-CLAUDE.md.example`) over a network/service split, unless the decomposition is
justified by something other than AI-tooling ergonomics.

## Governance

- DRI: `<fill in — name/contact of whoever owns Claude Code configuration for this repo>`
- Review this file and `.claude/settings.json` every 3–6 months, or sooner if the model or Claude Code version changes materially.
