# AI Coding Agents on Legacy Codebases: 2026 Research Summary

Reference notes for using Claude Code (CLI and JetBrains/IntelliJ plugin) against a large, poorly tested and poorly documented legacy application. Each section below is grounded in a specific, cited source; the closing table maps each finding to the corresponding artifact in `scaffold/`.

## 1. Executive summary

AI coding agents are strong on greenfield work and measurably weaker on brownfield/legacy work. The gap isn't primarily a model-capability problem — it's that legacy codebases weren't built to be "agent readable" (or even human-readable), and the tests that exist often don't actually describe behavior. Closing the gap means engineering readability and safety nets deliberately, not prompting harder.

## 2. The brownfield performance gap

AI tools deliver roughly 35–40% productivity gains on clean, greenfield tasks, but on brownfield/legacy systems the same tools achieve around 10% or less — a roughly 4x gap.

- [AI Coding Agent Productivity Debates: The 2026 Paradox](https://blog.exceeds.ai/ai-coding-agents-productivity-paradox/)
- [AI Coding Agents on Legacy Codebases: Why They Fail Where You Need Them Most — TianPan.co](https://tianpan.co/blog/2026-04-19-ai-coding-agents-legacy-codebases)
- [We Ran 5 AI Coding Agents on the Same Legacy Codebase — 200oksolutions](https://www.200oksolutions.com/blog/5-ai-coding-agents-tested-on-legacy-codebase/)

## 3. Why legacy code fools both agents and humans

Legacy code frequently carries 60–80% line coverage that means almost nothing, because the tests were written to hit lines rather than pin behavior. This creates a false sense of safety that both agents and reviewers can be lulled by.

The deeper issue is a **tribal-knowledge gap**, not hallucination: code review breaks down on AI-generated changes to legacy systems because reviewers depend on context they don't have either — the same missing tribal knowledge that's absent from the agent's inputs is also absent from the reviewer's mental model of what to check. This is the highest-risk failure mode in practice, because neither party can catch what neither party knows.

- [Legacy Code Modernization with AI Agents (2026) — Tembo.io](https://www.tembo.io/blog/legacy-code-modernization)
- [AI Coding Agents on Legacy Codebases: What Works and What Backfires — TianPan.co](https://tianpan.co/blog/2026-04-19-ai-coding-agents-brownfield-legacy-code)
- [Why AI Coding Tools Fail in Legacy Codebases and How to Fix It](https://youmind.com/landing/x-viral-articles/ai-coding-failure-legacy-codebase)

## 4. The integration tax

Generative AI excels at drafting isolated snippets but incurs a high "integration tax" once that code has to fit into a real brownfield, compliance-heavy system — this tax erodes much of the apparent speed gain. This is part of why the greenfield/brownfield gap in §2 is so large: the drafting speed is real, but it's not where the time goes on legacy systems.

- [Legacy Code Modernization with AI Agents (2026) — Tembo.io](https://www.tembo.io/blog/legacy-code-modernization)

## 5. Agent readability as an engineering property

Legacy codebases were not designed for AI agents to read. Teams that succeed treat "agent readability" as something to build explicitly (CLAUDE.md files, LSP setup, docs-as-context) rather than assume the codebase already has.

- [AI Coding Agents on Legacy Codebases: Why They Fail Where You Need Them Most — TianPan.co](https://tianpan.co/blog/2026-04-19-ai-coding-agents-legacy-codebases)

## 6. Anthropic's May 2026 guidance for large/legacy codebases

Anthropic published official guidance (May 14, 2026) on deploying Claude Code in enterprise codebases at real-world scale, including monorepos with tens of millions of lines and legacy systems spanning decades.

Core recommendations:

- **Hierarchical CLAUDE.md**: a lean root file with big-picture gotchas, plus subdirectory-level CLAUDE.md files for local conventions. Claude loads these additively as it traverses the codebase.
- **Scope test/lint commands per subdirectory** rather than only at the root.
- **Skills** for progressive disclosure — offload specialized workflows and domain knowledge so they don't permanently compete for context space.
- **Hooks**: start hooks load team/session context dynamically; stop hooks propose CLAUDE.md updates based on what the session learned — an incremental documentation feedback loop.
- **LSP integration** for symbol-level precision, so Claude distinguishes identically-named symbols instead of pattern-matching on text.
- **MCP servers** to connect internal tools, documentation, and structured search.
- **Subagents**: read-only exploration instances report findings back to a coordinating agent (the built-in Explore subagent runs on Haiku by default — cheaper and faster for this).
- **Governance**: assign a DRI (or small team) with ownership of Claude Code configuration; review configuration every 3–6 months as models evolve; start with approved skills, required code review, and limited access, then expand as confidence builds.

- [How Claude Code works in large codebases: Best practices and where to start — Claude by Anthropic](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start)
- [Best practices for Claude Code — Claude Code Docs](https://code.claude.com/docs/en/best-practices)
- [Steering Claude Code: when to use CLAUDE.md, skills, hooks, and subagents — Claude by Anthropic](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)

## 7. Plan Mode for unfamiliar codebases

Plan Mode is a read-only mode (file search, file read, repo-wide grep — no edits, no execution) explicitly recommended for working in an unfamiliar or legacy codebase before making changes. It's a natural fit for medium-to-high complexity tasks and initial exploration of a system you don't yet trust yourself (or the agent) to safely modify.

- [Claude Code Plan Mode: The Complete Guide (2026)](https://www.vibecodingacademy.ai/blog/claude-code-plan-mode-complete-guide)
- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents)

## 8. Characterization/golden-master testing as the core legacy-safety pattern

Characterization tests (golden-master tests) capture the current behavior of code, whatever it is, as a safety net: if a refactor accidentally changes behavior, a test fails. The core insight is that the biggest risk in legacy work isn't "messy code" — it's **silent behavior change** — so the priority is baselining current behavior before touching it.

AI can draft characterization tests quickly by reading a function or module, enumerating branches, and generating cases that exercise them — work that used to take a human days or weeks. But AI-generated tests must be executed and understood by a human before being trusted; they should never be trusted blindly. The recommended pairing for actual migration work is: characterization tests first, then the strangler-fig pattern to shift traffic piece by piece with easy rollbacks, treating AI output as a draft that must pass characterization tests, human review, and differential validation before shipping.

- [Refactoring Legacy Code Without Fear — The Boomerang IC](https://christiecosky.com/posts/2026/01/ai-refactor/)
- [Refactoring Legacy Code with AI: How to Use LLMs to Modernize Old Codebases Safely](https://veduis.com/blog/refactoring-legacy-code-with-ai/)
- [AI Legacy Code Modernization: The Enterprise Guide (2026)](https://www.entrans.ai/blog/ai-legacy-code-modernization-guide)

## 9. Coverage-guided context routing (tool-specific implementation detail)

JetBrains introduced a `finding-tests` agent skill (Rider 2026.2 EAP, also usable via MCP with Claude Code/Codex) that uses dotCover coverage data to route an agent directly to the test file that already covers a given piece of code, instead of having it manually explore the project. Routing directly to the right file cuts token consumption by up to ~50%, reduces misplaced tests in multi-tested codebases, and keeps new tests consistent with existing patterns — at the cost of upfront coverage-analysis time (30 seconds to hours depending on codebase size).

This specific implementation is dotCover/Rider-flavored, but the underlying pattern — **use coverage data as context to route the agent, rather than free-form exploration** — generalizes to any language/coverage-tool combination. `scaffold/.claude/skills/coverage-guided-routing/SKILL.md` scaffolds this pattern generically rather than reproducing the JetBrains-specific implementation.

- [What Happens When You Give AI Agents the Map of Your Code's Coverage? — The JetBrains Blog](https://blog.jetbrains.com/dotnet/2026/05/22/claude-codex-ai-agent-skill-for-writing-tests/)

## 10. JetBrains/IntelliJ plugin specifics

Claude Code integrates with JetBrains IDEs (IntelliJ IDEA, PyCharm, Android Studio, WebStorm, PhpStorm, GoLand) via a dedicated plugin (JetBrains Marketplace, plugin ID 27310, currently beta). The plugin does **not** bundle the CLI — `claude` must be installed and on PATH separately; the plugin runs it in the IDE's integrated terminal and connects to it (or via `/ide` from an external terminal).

Features:

- Inline diff viewer instead of terminal diffs (configurable via `/config` → Diff tool).
- Automatic **selection/open-file context sharing** — whatever is selected or open in the IDE is shared with Claude as context (blockable per-file via `Read` deny rules, e.g. for `.env`).
- `@file#Lstart-Lend` file-reference shortcut (Cmd+Option+K / Alt+Ctrl+K).
- **IDE diagnostics auto-shared**: lint/syntax errors from the IDE are sent to Claude as you work, via a local MCP server (`ide`, hidden from `/mcp`) that exposes exactly one tool to the model — `mcp__ide__getDiagnostics` (read-only). The plugin does not expose any code-execution tool to the model.
- Transport is unencrypted `ws://`, listening on loopback (`127.0.0.1`) by default with a fresh random auth token per IDE session. It's only exposed to the local network if "accept connections from all network interfaces" is explicitly enabled (relevant mainly for WSL2 without mirrored networking) — avoid enabling this unless required, since it puts both traffic and the auth token in cleartext on the LAN.
- **Security note specific to legacy/enterprise work**: in `acceptEdits` auto-approve mode, Claude could modify IDE configuration files that IntelliJ automatically executes, which increases risk beyond Claude Code's normal permission prompts. Manual approval mode is the safer default, especially for context-poor agents working on unfamiliar legacy code.

- [JetBrains IDEs — Claude Code Docs](https://code.claude.com/docs/en/jetbrains)

## 11. Prioritization: tests, documentation, or decomposition?

When deciding where to invest first on a legacy codebase, three levers are commonly proposed:
writing more tests, writing more documentation/context, and breaking the codebase into smaller
services or sub-projects. 2026 research supports a clear priority order, and pushes back on the
third option specifically.

**Tests first, but coverage % is the wrong target.** An ICSE 2026 systematic review (101 sources)
found QA is the most-neglected dimension of AI coding workflows. Meta's engineering data shows
change-aware test generation catches ~4x more real bugs than traditional "hardening" tests and
~20x more than tests that pass coincidentally — coverage percentage measures which lines execute,
not whether a test would actually catch a regression. This reinforces §8: characterization tests
that pin real behavior are worth more than chasing a coverage number.

**Documentation/context second, and it matters more as the codebase grows.** Long-context models
match local retrieval up to roughly 4MB of code; past that, structured context (CLAUDE.md-style
layering, retrieval, LSP) becomes necessary rather than optional. Done well, this drops cost per
task ~30%, improves execution speed ~38%, and improves retrieval accuracy 2–3x. This validates the
hierarchical CLAUDE.md approach in §6 as an investment that compounds with codebase size rather
than a one-time setup cost.

**Decomposition into microservices is a contested, potentially counterproductive lever —
specifically for AI-tooling effectiveness.** The intuitive assumption is that smaller services are
easier for an agent (and a human) to reason about. Research says the opposite in practice: AI
agents reason better when business logic, transactions, and dependencies are co-located, and
distributing logic across service boundaries fragments an agent's limited context window rather
than shrinking the problem. Notably, ~42% of organizations are actively consolidating microservices
back into larger units in 2026, partly because AI agents have changed the economics of "cost of
change" that microservice splits were originally meant to solve. The better-supported architectural
move for AI-enablement specifically is a **modular monolith** — clear internal module boundaries
without a network/service split — which is exactly what the subdirectory-CLAUDE.md pattern in §6
already assumes.

**Recommended priority order: tests → documentation/context → architecture**, and if architecture
work is warranted at all, prefer modularizing in place over splitting into services. Treat a
proposal to decompose the legacy app into microservices as motivated by something other than
"it'll make AI tooling work better" — that specific justification isn't well supported.

- [Do AI Coding Agents Reason Better in Modular Monoliths Than Microservices?](https://medium.com/@visrow/do-ai-coding-agents-reason-better-in-modular-monoliths-than-microservices-b2549e1c1ab3)
- [Modular Monolith Instead of Microservices — What Changed When the AI Agent Started Reading Code](https://medium.com/@wasowski.jarek/modular-monolith-instead-of-microservices-what-changed-when-the-ai-agent-started-reading-code-c586d9f63fd7)
- [AI Test Generation and Code Quality Trends for 2026](https://laracopilot.com/blog/ai-test-generation-2026/)
- [AI Code Generation in 2026: How It Works, Tools, and Best Practices — Sourcegraph](https://sourcegraph.com/blog/ai-code-generation)

## 12. Findings-to-scaffold map

| Finding | Addressed by |
|---|---|
| Brownfield performance gap / integration tax | Plan Mode + `codebase-recon` skill as mandatory first step before editing |
| Shallow coverage is a false safety net | `characterization-test` skill (behavior-based, not line-based) |
| Silent behavior change is the real refactor risk | `characterization-test` skill + human-execution requirement |
| Tribal-knowledge gap (agent and reviewer both blind) | `codebase-recon` skill's mandatory "unknowns" section; `legacy-explorer` subagent's structured output contract |
| Agent readability must be engineered | Hierarchical `CLAUDE.md` (root + subdirectory example) |
| Documentation goes stale / needs to grow from real sessions | `session-start-context.sh` + `stop-propose-doc-updates.sh` hooks (propose-only, human-gated) |
| Context-poor agents have outsized blast radius on legacy code; IDE auto-execute risk | `settings.json` manual-approval default, narrow tool allowlist |
| Coverage-guided routing cuts token cost | `coverage-guided-routing` skill (generic stub, tool-specific in the field) |
| Governance drift as models evolve | DRI + 3–6 month review cadence noted in `CLAUDE.md` and `settings.json` |
| Decomposition into microservices is contested/risky as an AI-enablement move | `CLAUDE.md` "Architecture guidance" section steers toward modularizing in place |
