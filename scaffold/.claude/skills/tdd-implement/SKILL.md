---
name: tdd-implement
description: Implement a task from a feature spec using a red-green-refactor TDD loop — write failing tests from the acceptance criteria, confirm they fail, implement to green without modifying the tests, refactor. Use after feature-spec has produced a spec and task list. On legacy code, if the task modifies existing weakly-tested behavior rather than adding new isolated code, run characterization-test first.
---

# TDD implementation

Test-driven development gives the tightest feedback loop for agentic implementation: each
red-to-green cycle is an unambiguous, executable signal, and committing the tests before
implementation creates a safety net against the agent quietly editing a test to make it pass
instead of fixing the implementation.

## Procedure

1. **Check whether this task modifies existing behavior or only adds new code.** If it modifies an
   existing, weakly-tested code path, run the `characterization-test` skill on that path first —
   this skill is not a safety net for pre-existing behavior, only for the new behavior being added.
2. **Write failing tests** derived directly from the relevant acceptance criteria in the spec
   (`docs/specs/<feature-name>.md`). Cover the behavior described, not implementation detail.
3. **Confirm the tests fail** by running them against the current code. A test that passes before
   any implementation exists is not testing what you think it is.
4. **Commit the failing tests** as a checkpoint, if working in a git repo, before writing any
   implementation. This is what makes the next step's guardrail enforceable — any later edit to
   these tests will show up as a diff against a known-good baseline.
5. **Implement until green, without modifying the committed tests.** If a test seems wrong once
   you're implementing against it, stop and flag this to the human rather than editing the test
   yourself — do not silently "fix" a test you wrote against ambiguous acceptance criteria.
6. **Refactor** only after the tests are green, and only as long as they stay green throughout.

## Guardrails

- Never edit a committed test to make it pass. If a test looks wrong, stop and ask.
- Never skip step 1's characterization check on legacy code that's being modified rather than
  purely added to — this is the seam where this skill and `characterization-test` must compose,
  not compete.
- Report explicitly what was implemented, which acceptance criteria are covered, and anything left
  unverified (e.g. a path that requires infrastructure not available in this environment).
