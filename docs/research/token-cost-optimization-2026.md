# Token & Cost Optimization for Agentic Coding: 2026 Research Summary

Reference notes on reducing token spend when running Claude Code (CLI and JetBrains/IntelliJ
plugin) against this repo, without giving up the safety/quality practices in the other two
research docs — cost control and correctness are treated as compounding, not competing, goals
here. Each section is grounded in a cited source; the closing table maps each finding to the
corresponding artifact in `scaffold/`.

## 1. Executive summary

Token spend on agentic coding is dominated by a small number of structural choices made once, not
by prompting discipline applied every turn: whether stable content is organized to be cache-hit
rather than cache-miss, whether exploration happens in an isolated subagent or bloats the main
loop, and whether cheap tasks are routed to a cheap model. Stacked together, these levers are
reported to bring typical unoptimized agentic workloads down to roughly 20–30% of their original
cost — with prompt caching alone typically accounting for 50–90% of that on repeated-context
workloads. None of this trades against the legacy-codebase safety practices in
`ai-agents-legacy-codebases-2026.md`; if anything it reinforces them, since `codebase-recon` and
`legacy-explorer` were already justified there as isolating expensive exploration into a
disposable subagent context rather than the persistent main one.

- [Lessons from building Claude Code: Prompt caching is everything — Claude by Anthropic](https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything)

## 2. Prompt caching is the highest-leverage single lever

Cached input tokens are billed at roughly 10% of normal input cost, and on workloads with a
stable, repeated prefix (system prompt, `CLAUDE.md`, skill/tool definitions) this typically nets
50–90% savings on the cached portion. The lever is structural, not something invoked per-request:
Claude Code already organizes its own system prompt so the stable pieces stay cached while only
the growing conversation tail is new each turn. The practical implication for a repo's own
configuration is that anything read on every session (`CLAUDE.md`, skill frontmatter/descriptions,
subagent definitions) should be treated as **cache-prefix content** — worth keeping stable and
front-loaded, because churn there invalidates the cache for the whole session, and bloat there is
paid (even if only at the 10% cache-read rate) on every single request of every session, not once.

- [Lessons from building Claude Code: Prompt caching is everything — Claude by Anthropic](https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything)
- [Prompt Caching for Claude: Cut Your API Bill 60% in Production — AI Magicx](https://www.aimagicx.com/blog/prompt-caching-claude-api-cost-optimization-2026)
- [Claude Cost Optimization 2026: Batch API and Prompt Caching — PE Collective](https://pecollective.com/tools/claude-pricing-guide/)

## 3. Keep `CLAUDE.md` and skills lean — it's cache-prefix content, not a one-time cost

This reinforces, from a cost angle, a claim `ai-agents-legacy-codebases-2026.md` §6 already makes
on a readability basis: a lean root `CLAUDE.md` with hierarchical subdirectory files beats one
large file. The cost framing sharpens *why*: a bloated root file is re-sent (at cache-read
pricing, but non-zero) on every request of every session for every contributor, while a
subdirectory file only enters context when that subdirectory is actually touched. Practical
target: keep the root file to roughly one to two pages; anything longer is a sign detail belongs
in a subdirectory file or a skill instead. Skills compound the same win via progressive
disclosure — a skill's frontmatter description is the only piece paid on every turn; the full
`SKILL.md` body is loaded into context only when the skill actually fires.

- [Claude Code Cost Optimization: Cut Tokens 2026 — LOW/CODE](https://www.lowcode.agency/blog/claude-code-cost-optimization)
- [How Claude Code works in large codebases — Claude by Anthropic](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start)

## 4. Context editing and compaction

Anthropic's context-editing tooling (clearing stale tool results/context rather than letting them
accumulate) is reported to deliver a 29% performance lift on its own, 39% combined with a memory
tool, and up to 84% token-consumption reduction on long-running tasks — the kind of task that would
otherwise fail outright from context exhaustion, not just cost more. In Claude Code specifically,
`/compact` (manual or automatic) is the user-facing form of this: sessions that run long — a full
`tdd-implement` loop with several failed-test iterations, for instance — benefit from compacting
before starting the next unrelated task rather than carrying dead context forward. This is a
session-hygiene practice for whoever is driving Claude Code, not something a repo's config can
force, but it's worth stating explicitly rather than leaving it undiscovered.

- [Claude Code Cost Optimization: Cut Your Token Spend — Claude Directory](https://www.claudedirectory.org/blog/claude-code-cost-optimization)

## 5. Subagent context isolation compounds with model routing

Anthropic's own multi-agent research architecture isolates each subagent's context window and has
it report back a condensed summary (1,000–2,000 tokens) rather than letting the coordinating agent
absorb everything the subagent read. This is exactly the shape `legacy-explorer` and
`feature-implementer` already take in this scaffold — the win these subagents produce is not just
"cleaner main-thread context" (the framing used when they were introduced) but a direct token-cost
reduction, since exploration that could dump dozens of files' worth of tokens into the main loop
instead gets discarded when the subagent exits, leaving only its structured report.

Model routing compounds this further: route light, high-volume, low-reasoning work (search,
classification, extraction — i.e. exactly what `legacy-explorer` does) to a small/cheap model, keep
a mid-tier model on workhorse implementation work, and reserve the largest model for genuinely hard
planning or long autonomous loops. A common production pattern is a frontier model on the main
orchestrating loop with small-model subagents for cheap sub-tasks specifically so the expensive
model's context and cache stay intact — i.e. route down, not up, for delegated grunt work.

- [Context Engineering: Agent Reliability Playbook 2026 — Digital Applied](https://www.digitalapplied.com/blog/context-engineering-agent-reliability-playbook-2026)
- [Best AI Model for Coding Agents in 2026: A Routing Guide — Augment Code](https://www.augmentcode.com/guides/ai-model-routing-guide)
- [Specialized agents win on cost/latency/reliability — see also `remote-agents-2026.md` §on production economics]

## 6. Coverage-guided routing, revisited as a token lever

`ai-agents-legacy-codebases-2026.md` §9 already documents this (routing an agent directly to the
test file that covers a given piece of code, instead of free-form exploration, cuts token
consumption up to ~50%) as a legacy-codebase pattern. It belongs in this doc too because the
mechanism is a token-cost lever first and a code-quality lever second: any technique that replaces
"read N files to find where something lives" with "look up a pre-computed mapping" is doing the
same thing structurally as subagent isolation in §5 — cutting exploration tokens out of the loop
that eventually produces code, rather than trying to make that exploration cheaper per-token.

## 7. Output-token budgets and response verbosity

Every token generated is billed regardless of whether it's read closely, and verbose intermediate
narration (restating a plan before executing it, summarizing a diff that's already visible, padding
a report with hedged caveats) is pure output-token cost with no retrieval benefit the way cached
*input* tokens have. This is a discipline point more than a config point: subagent output
contracts that require a fixed, bounded structure (as `legacy-explorer` and `feature-implementer`
already do) cap this by construction, since the agent isn't free to pad a report of unbounded
length — the contract already says exactly what sections must appear.

- [How to Reduce Token Usage in AI Agents: 10 MCP Optimization Techniques — MindStudio](https://www.mindstudio.ai/blog/reduce-token-usage-ai-agents-mcp-optimization)
- [Token Reduction Strategies for AI Agents — MindStudio](https://www.mindstudio.ai/blog/token-reduction-strategies-ai-agents-cut-costs)

## 8. A design choice this scaffold already gets right (validated, not new)

The `session-start-context.sh` hook was designed (per `ai-agents-legacy-codebases-2026.md`) as a
tribal-knowledge/readability feature — it surfaces `CLAUDE.md`'s "Known landmines" section and
*lists the filenames* of pending proposals under `.claude/proposed-updates/`, without dumping their
full content into every session's opening context. Re-examined through a cost lens, that filename-
only choice is also the cache/token-efficient one: full proposal content only enters context on the
session where a human or agent actually opens a specific file, not on every session start
regardless of relevance. No change is needed here — this is called out so the rationale is explicit
and the pattern isn't accidentally "fixed" into something more verbose later.

## 9. Findings-to-scaffold map

| Finding | Addressed by |
|---|---|
| Prompt caching is the single highest-leverage lever; stable content should be cache-prefix-friendly | `CLAUDE.md` kept lean and structurally stable; skill frontmatter as the only always-loaded skill cost |
| Bloated `CLAUDE.md`/skills are paid on every request of every session | `CLAUDE.md` "Model & token-budget guidance" section; skills' progressive-disclosure design (body loads only when invoked) |
| Long-running sessions benefit from context editing / `/compact` | `CLAUDE.md` "Model & token-budget guidance" section (session-hygiene note) |
| Subagent context isolation cuts tokens, not just context clutter | `legacy-explorer` / `feature-implementer` subagents (existing), reframed and cross-referenced here |
| Route cheap/high-volume work to a small model; reserve large models for hard reasoning | `legacy-explorer` pinned to `haiku` (existing); `feature-implementer` explicitly pinned rather than inheriting the orchestrator's model |
| Coverage-guided routing cuts exploration tokens | `coverage-guided-routing` skill (existing, cross-referenced from §6) |
| Unbounded output narration is pure cost with no caching benefit | Subagents' fixed, bounded output contracts (existing) |
| Session-start context should stay reference-only, not dump full content | `session-start-context.sh` (existing design, validated here rather than changed) |
