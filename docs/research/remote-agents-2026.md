# Remote Agents for Coding Tasks: 2026 Research Summary

Reference notes for running Claude Code as a **remote, CI-triggered agent** — as opposed to a
local interactive session — and for deciding when to reach for the scaffold's custom skills versus
a bare/generic invocation. Each section is grounded in a specific, cited source; the closing table
maps each finding to the corresponding artifact in `scaffold/`.

## 1. Executive summary

A remote agent extends the same spec→plan→TDD loop documented in
`agentic-feature-development-2026.md` into a headless context: same `CLAUDE.md`, same skills, same
underlying agent. What actually changes is mechanical, not methodological — how tool permissions
get scoped when there's no human to click "approve," and whether the trigger hands Claude a
structured spec or a bare mention. Get those two things right and the rest of the methodology
carries over unchanged.

## 2. What "remote agent" means here

This doc covers Claude Code's GitHub Action (`anthropics/claude-code-action`) — a GitHub Action
that runs Claude Code inside repository workflows, triggered by `@claude` mentions or by explicit
automation. It's built on the Claude Agent SDK, and by default executes in Anthropic-managed cloud
infrastructure (self-hosted sandboxes are available for keeping code/filesystem/network egress
in-house, but are out of scope here since the setup below uses the default path).

This is a different product from Anthropic's broader Managed Agents APIs (sandboxing, long-running
sessions, tracing infrastructure for building custom agent products) — worth knowing the name
exists, not something this repo's scaffold needs to configure directly.

- [Claude Code GitHub Actions — Claude Code Docs](https://code.claude.com/docs/en/github-actions)
- [Anthropic's Code with Claude Announces Managed Agents — InfoQ](https://www.infoq.com/news/2026/05/code-with-claude/)

## 3. Setup mechanics

Two install paths, both requiring repo admin access:

- **Quick setup**: run `/install-github-app` from Claude Code locally. It installs the Claude
  GitHub App, sets an authentication secret (`ANTHROPIC_API_KEY` for an API key or
  `CLAUDE_CODE_OAUTH_TOKEN` for a subscription token), and opens a PR with the workflow file ready
  to merge.
- **Manual setup**: install the [Claude GitHub App](https://github.com/apps/claude) yourself, add
  the secret, copy `examples/claude.yml` from the `claude-code-action` repo into
  `.github/workflows/`. Use this path when you want full control of the workflow file or don't run
  Claude Code locally.

The Action detects its own mode from the workflow config:

- **Interactive mode** — no `prompt` input. Claude waits for `@claude` (or a custom
  `trigger_phrase`) in an issue/PR comment, a PR review, or a newly opened issue's title/body, then
  responds as a comment on that issue/PR.
- **Automation mode** — a `prompt` input is set. Claude runs unconditionally on whatever event
  triggers the workflow (e.g. a cron schedule), with results in the workflow run log rather than a
  comment.

Two checks gate who can trigger a run in either mode: the triggering user needs write access to the
repo (events with no human author, like `schedule`, skip this), and bot actors are rejected unless
explicitly allow-listed — this prevents a Claude-authored comment from re-triggering itself in a
loop.

- [Claude Code GitHub Actions — Claude Code Docs](https://code.claude.com/docs/en/github-actions)

## 4. Permission scoping without a human in the loop

The scaffold's local `settings.json` defaults to `defaultMode: "default"` (manual approval) — every
edit needs a human to click approve. That mechanism doesn't exist in CI. The equivalent control is
explicit tool scoping at the workflow level:

- `--allowedTools` (or the `--allowed-tools` alias) passed via `claude_args`, or a `settings` input
  (JSON string or path) — same `permissions.allow` rule syntax as the local `settings.json`.
- If the prompt invokes a skill instead of running free-form, the skill's own `allowed-tools`
  frontmatter grants scope directly — one more reason the scaffold's skills are worth invoking
  remotely rather than sending Claude a bare prompt with full tool access.
- `--max-turns` and workflow-level timeouts cap runaway jobs, since there's no human watching a
  session to notice it's gone off the rails.

This is the CI-equivalent of the local narrow-allowlist principle already in
`scaffold/.claude/settings.json` — automation removes the click-to-approve step, it doesn't remove
the need to scope tools narrowly to start.

- [Claude Code GitHub Actions — Claude Code Docs](https://code.claude.com/docs/en/github-actions)

## 5. Composing with the existing scaffold

The Action checks out the repository before running Claude, so `CLAUDE.md` and `.claude/skills/`
load exactly as they would locally — no separate remote configuration needed for Claude to know
about `feature-spec`, `tdd-implement`, or the project's gotchas. The official docs' own best-practice
guidance ("define project standards in CLAUDE.md... Claude follows these guidelines when creating
PRs") is the same mechanism this scaffold already relies on for local sessions.

Practically: a `@claude`-tagged issue that matches the feature-request template (Deliverable 2) can
be steered, via an instruction already in `CLAUDE.md`, to run `feature-spec` before implementing —
so a remote trigger gets the same spec-first discipline as a local session, without the workflow
file itself needing feature-specific logic.

- [Claude Code GitHub Actions — Claude Code Docs](https://code.claude.com/docs/en/github-actions)

## 6. Custom vs. generic agents — what the research shows

The honest answer is conditional, not a blanket "custom is better":

**Generic agents get most of the way there, cheaply.** Small, domain-agnostic agents of a few
hundred lines consistently reach 70-95% of the performance of much larger specialized systems on
software-engineering benchmarks. Concretely: the specialized SWE-Agent scores 67% against the
generic Mini SWE-Agent's 65%, while Mini SWE-Agent is roughly 30x smaller and 7x cheaper per run.
For a one-off remote task — a single `@claude implement this` on an issue — that 2-point gap isn't
worth engineering a custom subagent for.

**Specialized agents win in production at scale, on cost/latency/reliability, not raw
capability.** 2026 enterprise data shows specialized multi-agent orchestration delivering ~31%
lower inference cost and 40-60% lower latency than a single large generic model handling the same
range of tasks, and enterprises are investing accordingly for high-value, *repeated* workflows.
Specialization is best understood as a context-engineering pattern — a narrow, purpose-built agent
reduces decision noise for a task shape that recurs — not as a capability upgrade per run.

**Applied to this repo:** the scaffold's `feature-spec`/`tdd-implement`/`feature-implementer`
artifacts already exist because feature work here is a *repeated* pattern, not a one-off — that's
exactly the condition under which the enterprise data favors specialization. Wiring the remote
trigger to invoke those same skills (§5) extends that payoff to CI; it isn't a new argument, it's
the same one that justified building the skills locally, now applied to a headless context. For a
genuinely one-off remote request unrelated to the feature workflow, a bare `@claude` mention with
no skill invocation is a reasonable, cheaper default — don't build custom scaffolding for traffic
that doesn't repeat.

- [Ready For General Agents? Let's Test It. — ICLR Blogposts 2026](https://iclr-blogposts.github.io/2026/blog/2026/general-agent-evaluation/)
- [Why Specialized Multi-Agent Workflows Outperform Generalized AI in 2026 — TechBullion](https://techbullion.com/why-specialized-multi-agent-workflows-outperform-generalized-ai-in-2026/)

## 7. Findings-to-scaffold map

| Finding | Addressed by |
|---|---|
| No manual-approval mechanism exists in CI | `scaffold/.github/workflows/claude.yml` comment block documenting explicit `--allowedTools`/`settings` scoping as the CI-equivalent of `settings.json`'s local allowlist |
| A bare `@claude` mention gets a vague, unscoped request | `scaffold/.github/ISSUE_TEMPLATE/feature-request.md`, fields matching `feature-spec`'s spec shape |
| Remote runs should get the same spec-first discipline as local sessions, without extra workflow logic | `scaffold/CLAUDE.md`'s "Before starting a new feature" section, which the Action reads identically to a local session |
| Specialization pays off for repeated task shapes, not one-off requests | This doc's §6 verdict — reuse the existing `feature-spec`/`tdd-implement`/`feature-implementer` artifacts for feature work; don't build new custom agents for non-repeating remote requests |
| Bot-authored comments could re-trigger a run in a loop | Documented in `claude.yml`'s comments (`allowed_bots` is intentionally left unset — default rejects bot actors) |
