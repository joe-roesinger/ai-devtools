---
name: characterization-test
description: Draft golden-master tests that pin the CURRENT behavior of a function or module before refactoring it. Use before any refactor touching code that is weakly tested or where existing coverage might be shallow (lines covered, not behavior). Use when the user asks to refactor, clean up, or modernize legacy code that lacks reliable tests.
---

# Characterization testing

Legacy code's biggest refactoring risk is silent behavior change, not messy code. This skill
produces a safety net by pinning down what the code *actually does* — including any existing
bugs — before anything is changed. It does not judge whether the behavior is correct.

## Procedure

1. **Read the target** — the function/module to be characterized, and all its call sites. Do not
   guess at behavior from the name or a docstring; read the implementation.
2. **Enumerate branches and inputs** by reading the code: every conditional, loop boundary, error
   path, and edge case you can find. If the code calls into something you can't see (external
   service, another poorly-documented module), note that as an open question rather than assuming
   its behavior.
3. **Draft golden-master tests** that pin the current actual behavior for each case enumerated in
   step 2. Include tests for behavior that looks like a bug — characterization tests capture "what
   it does," not "what it should do." If you believe something is a bug, say so in a comment next
   to the test, but still pin the current behavior.
4. **Run the drafted tests against the unmodified code** to confirm they pass as a baseline. A
   characterization test that doesn't pass against current code is worthless as a safety net.
5. **Report explicitly to the human**: list what was covered, list anything you were unsure about
   (see step 2), and state clearly that these tests are a draft — they must be reviewed and
   executed by a human before being trusted as a refactor safety net.

## Guardrails

- Never modify or delete existing tests as part of this skill.
- Never proceed to refactor the code in the same invocation. Characterization is a separate, prior
  step — the human decides when to move on to the actual change, ideally using the strangler-fig
  pattern for larger migrations.
- Do not claim coverage you don't have. If you couldn't exercise a path (e.g., it requires
  infrastructure not available in this environment), say so instead of fabricating a passing test.
