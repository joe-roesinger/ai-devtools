# JIRA-to-Feature-Completion Pipeline: High-Level Spec

Status: draft. Owner: `<fill in>`. Last updated: 2026-08-26.

## 1. Goal

Take a JIRA ticket describing a new (greenfield) feature or project and carry it, with minimal
human touch, to a merged, tested pull request — using Claude Code remote/cloud agent sessions to do
the actual spec-writing and implementation, and a human only at the points where judgment calls
matter: approving scope before code is written, and reviewing the final PR.

This builds directly on top of the existing scaffold in this repo (`scaffold/`) rather than
replacing it:

- The **spec → plan → TDD loop** (`feature-spec` → `tdd-implement`) is unchanged — see
  `docs/research/agentic-feature-development-2026.md` and
  `docs/diagrams/feature-development-workflow.md`. This pipeline's only job is to get a ticket into
  that loop correctly and get the result back out to JIRA.
- The **remote-agent mechanics** (`anthropics/claude-code-action`, tool scoping, permission checks
  on who can trigger a run) are unchanged — see `docs/research/remote-agents-2026.md` and
  `docs/diagrams/trigger-map.md`. This pipeline adds a new trigger source (JIRA, via
  `repository_dispatch`) alongside the existing `@claude`-mention trigger; it doesn't change how
  the Action itself runs once triggered.

Since the target is greenfield work, Methodology A in `agentic-feature-development-2026.md` §7
applies throughout: no `codebase-recon`/`characterization-test` detour, straight to
`feature-spec` → `tdd-implement`.

## 2. Decisions made

These were settled up front and shape every sub-document; revisit only if a constraint below turns
out to be wrong in practice.

| Decision | Choice | Why |
|---|---|---|
| Trigger source | JIRA Automation webhook, not polling | Near-instant, and JIRA Automation can call GitHub's `repository_dispatch` API directly with no separate receiver to host |
| Orchestration | A custom orchestrator, not bare per-ticket cloud-agent calls | Multiple tickets need queueing, per-ticket state, retries, and a place to park human approval — more than a single stateless Action invocation can hold |
| Human checkpoint | Approve the **plan/spec** before implementation starts, not fully autonomous | Greenfield scope is easy to misjudge; catching it before the (expensive, harder-to-undo) implementation phase is cheaper than catching it at PR review |
| Hosting | GitHub Actions only — no separate server | Avoids standing up and operating infrastructure; state lives in GitHub-native objects (issues, labels, branches) instead of a database |

## 3. Components

```
JIRA ticket
   │  (1) status → "Ready for Agent" fires a JIRA Automation rule
   ▼
JIRA Automation "Send web request" action
   │  POST repos/{org}/{control-repo}/dispatches, event_type=jira-ticket-ready
   ▼
GitHub Actions: intake workflow  ──creates──▶  Tracking issue (state object for this ticket)
   │
   ▼
GitHub Actions: spec workflow  ──runs feature-spec via claude-code-action──▶  Draft PR + spec
   │  posts spec back onto the tracking issue, labels it stage:awaiting-approval
   ▼
Human comments /approve on the tracking issue  ──permission-checked──▶  label → stage:implement
   │
   ▼
GitHub Actions: implement workflow  ──runs tdd-implement via claude-code-action──▶  commits on the PR
   │  marks PR ready for review once the spec's task list is complete
   ▼
CI + automated code review (existing repo checks, optionally /code-review)
   │
   ▼
Human reviews and merges the PR
   │
   ▼
GitHub Actions: sync workflow  ──JIRA REST API──▶  ticket transitioned to Done, PR link commented
```

## 4. Sub-documents

- [`01-trigger-and-intake.md`](01-trigger-and-intake.md) — JIRA Automation rule config, the
  `repository_dispatch` payload contract, and how a tracking issue gets created.
- [`02-orchestrator-and-state.md`](02-orchestrator-and-state.md) — how ticket state, queueing, and
  concurrency are represented using only GitHub-native primitives (issues, labels, concurrency
  groups) — the "custom orchestrator" without a hosted service.
- [`03-plan-approval-gate.md`](03-plan-approval-gate.md) — where the spec is posted, how a human
  approves or requests changes, and the permission check that guards it.
- [`04-agent-execution.md`](04-agent-execution.md) — how the orchestrator invokes
  `claude-code-action` for the spec and implement phases, tool scoping, and greenfield
  repo/branch creation.
- [`05-review-merge-and-sync.md`](05-review-merge-and-sync.md) — CI, optional automated review,
  merge criteria, and the JIRA status sync-back.

A new diagram, [`docs/diagrams/jira-pipeline-flow.md`](../../diagrams/jira-pipeline-flow.md), gives
the full state-machine view; it composes with the existing `trigger-map.md` (adds a new trigger
branch) and `feature-development-workflow.md` (unchanged — this pipeline hands off into it
unmodified at the spec/implement steps).

## 5. Open questions

These are unresolved and should be settled (or explicitly deferred with a reason) before building:

1. **One control repo vs. a new repo per feature.** "Greenfield features/projects" could mean a new
   module in an existing repo, or a brand-new repo per project. §4 of `04-agent-execution.md`
   assumes a template-based `gh repo create` step for the latter case; if every ticket instead
   targets one existing repo, that step is unnecessary and should be dropped rather than left as
   dead complexity.
2. **JIRA field mapping.** Which JIRA fields map to the spec's required inputs (what/why/scope) —
   summary + description may not be enough structure; a ticket template or required custom fields
   may be needed on the JIRA side.
3. **Cost/runaway controls.** Per-ticket budget (max Claude Code turns, wall-clock timeout,
   Actions-minutes budget) is not yet defined — needed before this runs unattended on real tickets.
4. **Approval-loop limits.** How many `/request-changes` round trips are allowed on one ticket
   before a human is pulled in synchronously instead of iterating async.
5. **Secrets ownership.** Who holds the JIRA API token and the GitHub PAT used by JIRA Automation,
   and how they're rotated — not a technical design question, but a blocking prerequisite.
