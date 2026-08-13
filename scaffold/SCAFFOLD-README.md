# Scaffold: Claude Code config for a legacy codebase

Copy this into a real repo:

```
cp -r scaffold/.claude <target-repo>/
cp scaffold/CLAUDE.md <target-repo>/CLAUDE.md
```

Then fill in the `<fill in>` placeholders in `CLAUDE.md` (repo map, gotchas, test/lint commands,
DRI) and in `.claude/skills/coverage-guided-routing/SKILL.md` (your actual coverage command). See
`docs/research/ai-agents-legacy-codebases-2026.md` (in this tooling repo, not the target repo) for
the research each piece of this scaffold is grounded in.

**Optional — remote/GitHub-triggered agent:**

```
cp -r scaffold/.github <target-repo>/
```

This needs GitHub-side setup beyond copying files: install the Claude GitHub App (run
`/install-github-app` from Claude Code in the target repo, or install
[github.com/apps/claude](https://github.com/apps/claude) manually), add the `ANTHROPIC_API_KEY` or
`CLAUDE_CODE_OAUTH_TOKEN` repo secret, then merge the workflow. See
`docs/research/remote-agents-2026.md` for the research this piece is grounded in.

## What's in here

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Lean root file: repo map, gotchas, test/lint commands, when to use Plan Mode/skills, model/token-budget guidance, governance |
| `examples/subdir-CLAUDE.md.example` | Example of a subdirectory-level CLAUDE.md (additive-loading pattern) |
| `.claude/skills/characterization-test/` | Draft golden-master tests before refactoring weakly-tested code |
| `.claude/skills/codebase-recon/` | Read-only exploration that surfaces tribal-knowledge gaps explicitly |
| `.claude/skills/coverage-guided-routing/` | Generic stub for coverage-as-context test routing — adapt per repo |
| `.claude/skills/feature-spec/` | Write a version-controlled spec before any new-feature code is written |
| `.claude/skills/tdd-implement/` | Implement a spec'd task via a red-green-refactor TDD loop |
| `.claude/agents/legacy-explorer.md` | Read-only exploration subagent (Read/Grep/Glob only) |
| `.claude/agents/feature-implementer.md` | Write-capable subagent that implements one spec'd task at a time via `tdd-implement`; pinned to a mid-tier model rather than inheriting the orchestrator's |
| `.github/workflows/claude.yml` | Claude Code GitHub Action (interactive mode) — responds to `@claude` mentions on issues/PRs |
| `.github/ISSUE_TEMPLATE/feature-request.md` | Issue template matching `feature-spec`'s fields, so a `@claude`-tagged issue arrives as a structured spec |
| `.claude/hooks/session-start-context.sh` | Surfaces gotchas + pending doc proposals at session start |
| `.claude/hooks/stop-propose-doc-updates.sh` | Prompts a proposed (never auto-applied) CLAUDE.md update at session end |
| `.claude/settings.json` | Manual-approval default, narrow tool allowlist, hook registration, token-budget note |

## Diagrams

The table above is prose; `../docs/diagrams/` has the same information as one Mermaid diagram per
workflow — `trigger-map.md`, `legacy-recon-workflow.md`, `feature-development-workflow.md`, and
`subagent-model-routing.md`. Worth a look before copying the scaffold into a real repo if prose
control-flow descriptions are hard to hold in your head at once.

## CLI vs. JetBrains/IntelliJ plugin usage

Everything above works identically whether you drive it from the plain `claude` CLI or from the
JetBrains plugin (which runs the same CLI inside the IDE terminal) — the plugin just adds a few
conveniences worth using deliberately on legacy code:

- **Diagnostics auto-share**: the plugin sends IDE lint/syntax errors to Claude automatically via a
  read-only `mcp__ide__getDiagnostics` tool. Useful for surfacing problems a stale or misleading
  test suite wouldn't catch — but it's not a substitute for `characterization-test`; a clean lint
  pass says nothing about behavior.
- **Selection context + `@file#Lstart-Lend`**: when doing recon on a specific legacy function,
  select just that region before invoking `codebase-recon` rather than the whole file — this keeps
  the agent from over-generalizing from unfamiliar surrounding code it wasn't asked about.
- **Manual approval stays the default even with the plugin's inline diff viewer.** The diff viewer
  makes manual review low-friction — that's a reason to keep manual approval, not a reason to switch
  to `acceptEdits`. In `acceptEdits` mode, Claude could modify IDE config files IntelliJ auto-executes,
  which is a real risk specific to running inside the IDE.
- **CLI-only sessions** (no plugin) don't get diagnostics or selection auto-share, so lean more on
  explicit file/grep instructions when invoking `codebase-recon` outside the IDE.
- **Network**: the plugin's local MCP server listens on loopback by default; leave "accept
  connections from all network interfaces" off unless you're on WSL2 without mirrored networking —
  enabling it exposes the (unencrypted) session and its auth token on the LAN.

## Validating the scaffold

Once copied into a real legacy repo and the placeholders are filled in:

1. **Session-start check**: start a session; confirm the gotchas section and any pending proposals
   actually appear in context (ask "what do you already know about this repo's gotchas" and check
   it cites `CLAUDE.md`).
2. **Recon check**: run `codebase-recon` against one real unfamiliar module. Confirm it produces a
   knowledge doc with a genuinely populated "unknowns" section — not just a confident summary.
3. **Characterization check**: pick one small, low-risk, poorly-tested function; run
   `characterization-test`; then **manually execute** the generated tests against the current code
   yourself and confirm they pass. Don't just trust the agent's claim that they pass — that's the
   whole point of the "human must verify" guardrail.
4. **Feature workflow check**: pick one small real feature; run `feature-spec` then
   `tdd-implement` (or delegate the latter to `feature-implementer`). Confirm the spec landed in
   `docs/specs/`, that tests were committed before implementation, and that the agent did not edit
   those tests to force a pass. If the feature touches legacy code, confirm `feature-spec` actually
   flagged missing `codebase-recon`/`CLAUDE.md` coverage when the touched area lacked it.
5. **Stop-hook check**: end that session; confirm a proposal file appears under
   `.claude/proposed-updates/` and that no `CLAUDE.md` file changed on disk and nothing was
   committed.
6. **Permission-mode check**: confirm at least one edit required explicit approval during the
   session (not `acceptEdits`); if using the JetBrains plugin, confirm this still holds.
7. **JetBrains-specific check** (if applicable): select a specific region in the IDE, confirm the
   agent references exactly that selection; trigger a lint error and confirm
   `mcp__ide__getDiagnostics` surfaces it unprompted.
8. **Remote-agent check** (if `.github` was copied and the App/secret are installed): open a test
   issue using the feature-request template, comment `@claude implement this feature`, and confirm
   in the Actions log that it runs `feature-spec` before implementing rather than going straight to
   code — and that it opens a PR rather than pushing directly to a protected branch. This is the
   one check that can't be validated from this tooling repo alone, since it needs a real GitHub App
   install and repo secret; budget for that when copying this piece.
9. **Iterate**: after a few real sessions, review `.claude/proposed-updates/` with the DRI, merge
   the useful entries into `CLAUDE.md`, and treat that convergence as evidence the feedback loop is
   working — not a one-off scaffold going stale. Revisit on the 3–6 month cadence noted in
   `CLAUDE.md`.
10. **Token-budget check**: run `claude --verbose` (or check session cost output) across a
    `codebase-recon` delegated to `legacy-explorer` and confirm it actually ran on the pinned cheap
    model rather than silently inheriting the main session's model; confirm root `CLAUDE.md` stays
    within roughly one to two pages as it grows. See
    `docs/research/token-cost-optimization-2026.md`.

## Known open concern

The stop hook has no built-in de-duplication — nothing currently stops it from proposing the same
update every session if the underlying gotcha keeps coming up. This is left as a tuning concern for
whoever adopts the scaffold (e.g., have the agent check `.claude/proposed-updates/` for a similar
existing proposal before writing a new one) rather than solved here with an unverified mechanism.
