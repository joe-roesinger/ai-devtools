---
name: coverage-guided-routing
description: Generic stub for routing to the right existing test file via code coverage data instead of manual exploration, before writing a new test. Adapt the coverage-tool detection/invocation to this repo before relying on it. See docs/research/ai-agents-legacy-codebases-2026.md section 9 for the reference implementation this generalizes from.
---

# Coverage-guided routing (generic stub — adapt per repo)

This is **not** a working generic implementation. It's a scaffold describing a pattern that has a
verified reference implementation for one specific toolchain (JetBrains dotCover, Rider 2026.2 EAP,
usable via MCP with Claude Code) which cut token consumption by up to ~50% by routing an agent
directly to the test file that already covers a given piece of code, instead of manual exploration.
The underlying pattern generalizes; the tooling to run it does not, without adaptation.

## Pattern

1. Detect what coverage tool (if any) this repo already uses — look for config such as `.nycrc`,
   `coverage.xml`, `jacoco.xml`, `.coveragerc`, a dotCover config, or an equivalent for this repo's
   language.
2. Run it (or reuse a recent report) to produce coverage data.
3. Parse that data into a mapping from source file/function → existing test file(s) that exercise
   it.
4. Before writing a new test or exploring the codebase manually to find where a test belongs, check
   this mapping first — if a test already exists for the target code, read it and match its style
   and location rather than creating a new, possibly duplicate test file elsewhere.

## To make this real for your repo

Replace the detection/invocation step above with the actual command for your coverage tool, e.g.:

```
<fill in: your repo's coverage command, e.g. `pytest --cov=src --cov-report=xml` or `mvn jacoco:report`>
```

and a small script or inline instruction for parsing that report's file→test mapping.

## Guardrail

If no coverage tool is configured, or the report is stale/missing, say so explicitly and fall back
to the `codebase-recon` skill rather than guessing at test placement.
