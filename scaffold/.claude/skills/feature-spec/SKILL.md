---
name: feature-spec
description: Write a version-controlled spec for a new feature before any code is written — what it does, why, explicit out-of-scope, interfaces/files touched, acceptance criteria. Use at the start of any new feature, on greenfield or legacy code. On legacy code, also checks for existing codebase-recon/CLAUDE.md coverage of the touched area and flags the gap if missing.
---

# Feature spec

The core failure mode this skill guards against is drift: an agent producing plausible code that
quietly solves the wrong problem because nobody grounded the work in a real specification first.
Spec-driven development treats the spec as the source of truth — the plan, task breakdown, and
implementation are all derived from it, not the other way around.

## Procedure

1. **Capture the spec** by asking (or inferring from the user's request, confirming before
   proceeding if anything is ambiguous):
   - What the feature does, in concrete behavioral terms.
   - Why — the problem or need it addresses.
   - Explicit **out-of-scope** items — what this feature deliberately does not do.
   - Interfaces/files involved — what's touched, what's new, what existing code it calls into.
   - Acceptance criteria — a concrete, testable list. These become the basis for the failing
     tests the `tdd-implement` skill writes first.
2. **On legacy code (skip this step for a genuinely new project/module):** check whether the
   touched area has a `codebase-recon` knowledge doc (`docs/agent-notes/<module>.md`) or a local
   `CLAUDE.md`. If neither exists, **say so explicitly to the user** rather than proceeding as if
   the area is understood — recommend running `codebase-recon` first. Do not silently skip this
   check; an unflagged gap here is exactly the tribal-knowledge risk this scaffold exists to avoid.
3. **Write the spec** to `docs/specs/<feature-name>.md` in the target repo (not in this scaffold).
4. **Break the spec into a small task list** — prefer several independently-verifiable vertical
   slices over one large task. Hand this off to `tdd-implement` for implementation, one task at a
   time.

## Guardrails

- Do not proceed to implementation in the same invocation — spec-writing and implementation are
  separate steps, so the human can review the spec before code exists.
- Do not silently assume scope. If the request is ambiguous about what's in vs. out of scope, ask.
- On legacy code, do not skip the recon-coverage check even if the user seems confident the area is
  well understood — the check costs one file lookup and the risk of skipping it is a shared
  blind spot between the agent and the reviewer.
