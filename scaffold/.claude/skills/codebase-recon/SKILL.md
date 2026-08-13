---
name: codebase-recon
description: Read-only exploration of an unfamiliar module or subsystem before making changes to it. Produces a knowledge doc with an explicit unknowns/tribal-knowledge-gaps section, and proposes (never applies) CLAUDE.md additions. Use when entering a new area of the codebase, or at the start of a session touching a subsystem not yet documented locally.
---

# Codebase recon

The riskiest failure mode when working in a poorly-documented legacy codebase is not
hallucination — it's a tribal-knowledge gap that both the agent and the human reviewer share,
so neither can catch what neither knows. This skill exists to surface that gap explicitly instead
of writing a confident-sounding summary that papers over it.

This is the manually-invoked counterpart to the automatic stop hook
(`hooks/stop-propose-doc-updates.sh`): use it deliberately when you're about to work somewhere
unfamiliar, rather than waiting for session end.

## Procedure

1. **Read-only exploration only** — file search, file read, grep. Do not edit or execute anything.
   This pairs naturally with Plan Mode and the `legacy-explorer` subagent for the exploration
   itself.
2. Identify: the module's purpose, its entry points, what it depends on and what depends on it,
   and any invariants you can infer from the code (e.g., "always called inside a transaction",
   "assumes input is already validated upstream").
3. Write a knowledge doc to `docs/agent-notes/<module>.md` in the target repo (not in this
   scaffold) covering the above.
4. **Mandatory: include an explicit "Unknowns / tribal-knowledge gaps found" section.** List
   anything you could not determine from the code alone — undocumented external behavior, unclear
   intent behind an odd pattern, missing tests for a path you can't otherwise verify. An empty
   section here is a red flag, not a good sign — it usually means the recon wasn't thorough enough,
   not that the module has no gaps.
5. Propose (do not apply) any additions to the nearest `CLAUDE.md` — root or subdirectory — that
   would help a future session. Follow the same propose-only convention as the stop hook: write the
   proposal, don't edit `CLAUDE.md` directly.

## Guardrails

- No edits, no command execution, no test runs — recon is read-only by design.
- Don't infer behavior from naming or comments alone when the implementation is available to read.
- Surface uncertainty rather than resolving it with a guess.
