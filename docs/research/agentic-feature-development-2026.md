# Agentic Feature Development: 2026 Research Summary

Reference notes for using Claude Code to build *new* features — as opposed to
`ai-agents-legacy-codebases-2026.md`'s focus on safely modifying existing, poorly-documented
behavior. Each section below is grounded in a specific, cited source; the closing table maps each
finding to the corresponding artifact in `scaffold/`.

## 1. Executive summary

Feature development with agents succeeds when specification and verification are engineered as
deliberately as generation itself — the failure mode isn't slow output, it's confident, plausible
code that quietly drifts from intent. The methodology below is the same core loop
(spec → plan → TDD implement) for both brand-new and legacy codebases; what differs is which
additional safety nets that loop must compose with. On a fresh project there's no existing
behavior to accidentally break, so the loop runs directly. On legacy code it must run alongside
the safety nets already documented in `ai-agents-legacy-codebases-2026.md`
(`codebase-recon`, `characterization-test`) rather than replace them.

## 2. Spec-driven development as the core methodology

Spec-driven development (SDD) emerged in 2025 as a direct response to "vibe coding" — agents
producing plausible code that drifts from intent, hallucinates APIs, and decays as projects scale.
By 2026 it is mainstream: every major AI coding tool (GitHub Spec Kit, AWS Kiro, Claude Code,
Cursor, OpenSpec, BMAD, Tessl, Google Antigravity) ships its own flavor, and DeepLearning.AI's
dedicated short course is a signal the methodology has crossed from experimental to standard
practice.

The workflow that has solidified in 2026 is four phases: **specify → plan → task → implement**. An
executable, version-controlled specification is the single source of truth; the implementation
plan and atomic task breakdown are derived from it, and code generation happens last, not first.

An ICSE 2026 systematic finding reinforces why: feeding architectural documentation into
LLM-assisted code generation produced measurable gains in functional correctness and spec
conformance, compared to generation without that grounding.

- [Spec-Driven Development with AI Coding Agents (2026) — zeroshot.ghost.io](https://zeroshot.ghost.io/spec-driven-development-with-ai-coding-agents/)
- [Spec-Driven Development (SDD): The Definitive 2026 Guide — thebcms](https://www.thebcms.com/blog/spec-driven-development/)
- [From Prompt to Process: a Process Taxonomy and Comparative Assessment of Frameworks Supporting AI Software Development Agents — arXiv](https://arxiv.org/pdf/2606.04967)

## 3. TDD as the implementation feedback loop

Test-driven development is the strongest pattern for the "implement" phase of the spec→plan→task
loop: each red-to-green cycle gives the agent unambiguous, executable feedback, and it can iterate
against the suite without a human re-explaining intent after every step.

Anthropic's recommended sequence: write tests first from the spec's acceptance criteria, confirm
they fail, commit the failing tests as a checkpoint, then implement until green **without
modifying the tests**. This ordering matters as a safeguard specifically: agents will sometimes
edit a test to make it pass rather than fixing the implementation. Committing the tests first means
any such edit shows up as a diff against a known-good baseline, so it's caught rather than silently
accepted.

- [Claude Code Best Practices: Planning, Context Transfer, TDD — DataCamp](https://www.datacamp.com/tutorial/claude-code-best-practices)
- [Claude Code and the Art of Test-Driven Development — The New Stack](https://thenewstack.io/claude-code-and-the-art-of-test-driven-development/)

## 4. Context engineering and task decomposition

A self-contained spec that names the files and interfaces involved, states what's explicitly out
of scope, and ends with verification steps produces more reliable implementation than a vague
prompt. In multi-agent setups, supervisor agents decompose a feature into focused subtasks and hand
each to a worker with context scoped narrowly to its piece — workers don't see each other's
information noise, which keeps each task's context small and relevant.

The "Agentic Context Engineering" (ACE) paper (ICLR 2026) frames context as an evolving, curated
document rather than something to maximize: default to less context, and add back only what
measurably improves task success. This is the same discipline the existing legacy scaffold applies
via lean root `CLAUDE.md` + additive subdirectory files — it generalizes to spec/task sizing for
new feature work too.

- [Context Engineering: A Practical Guide for AI Agents (2026) — Sourcegraph](https://sourcegraph.com/blog/context-engineering)
- [Context Engineering Research: Papers & Benchmarks (2026)](https://www.iwoszapar.com/p/context-engineering-research-2026)

## 5. Multi-agent orchestration for larger features

Anthropic shipped Dynamic Workflows (Opus 4.8, May 2026): Claude writes a JavaScript orchestration
script for the described task, and a runtime executes tens to hundreds of parallel subagents
(capped at 16 concurrent, 1,000 total per run) in the background, with the plan living in script
variables rather than the coordinating agent's context window. Separately, Outcomes (public beta)
adds a second-agent quality gate, and multi-agent orchestration lets a lead agent fan work out to
parallel specialists sharing a filesystem — each subagent can read outputs the others produced, so
a final assembly step sees the full picture instead of isolated fragments.

This is worth reaching for only on features that genuinely decompose into independent pieces (e.g.
parallel work across unrelated modules). For a typical single-developer feature, a single-agent
spec→plan→TDD loop is simpler and easier to review; orchestration overhead isn't free.

- [Anthropic Ships Claude Opus 4.8 Alongside Dynamic Workflows — MarkTechPost](https://www.marktechpost.com/2026/05/28/anthropic-ships-claude-opus-4-8-alongside-dynamic-workflows-and-cheaper-fast-mode-with-workflows-capped-at-1000-subagents/)
- [Code with Claude SF 2026: Anthropic Ships Outcomes and Multi-Agent Orchestration — ClaudeAINews](https://www.claudeainews.com/news/code-with-claude-sf-2026-outcomes-multi-agent)

## 6. The greenfield/brownfield gap, revisited for feature work

`ai-agents-legacy-codebases-2026.md` §2 already documents the headline gap: ~35-40% productivity
gains on greenfield work vs. ~10% or less on brownfield/legacy. For feature work specifically, the
picture is more granular: gains concentrate in **low-complexity greenfield tasks (30-40%)**, and
fall to a more modest **10-15% on high-complexity greenfield work** — complexity matters even
before legacy status enters the picture. On existing/legacy systems, the same generative strength
at drafting isolated snippets runs into a high "integration tax" once that code has to fit a real,
compliance-heavy system, eroding much of the apparent speed gain. Notably, this tax hits
*experienced* developers hardest — AI helps junior developers most on isolated tasks, while senior
engineers face the brunt of the integration cost on legacy work.

This is the empirical reason the methodology below is split rather than unified: the same
spec→plan→TDD loop needs different composition depending on which side of the gap the work falls
on.

- [AI Productivity Gains in Different Situations — Markus Harrer](https://markusharrer.de/blog/2026/02/18/ai-productivity-gains-in-different-situations/)
- [Analyzing coding agent transcripts to upper bound productivity gains — METR](https://metr.org/notes/2026-02-17-exploratory-transcript-analysis-for-estimating-time-savings-from-coding-agents/)

## 7. Methodology A: greenfield feature development

On a new project or a genuinely new module with no existing behavior to protect:

1. **Specify** — write a spec: what the feature does, why, explicit out-of-scope, interfaces/files
   involved, acceptance criteria. (`feature-spec` skill.)
2. **Plan** — break the spec into small, independently-verifiable tasks. Prefer several small
   vertical slices over one large task; each slice should be reviewable on its own.
3. **Implement via TDD** — for each task: write failing tests from the acceptance criteria, confirm
   they fail, implement to green without touching the tests, refactor. (`tdd-implement` skill.)
4. **Reach for multi-agent orchestration only if the plan genuinely decomposes into independent
   parallel pieces** (§5) — not as a default.

No `codebase-recon` or `characterization-test` step is needed here — there's no tribal-knowledge
gap or existing-behavior risk to guard against on code that doesn't exist yet.

## 8. Methodology B: adding features to legacy code

Same spec→plan→TDD loop, composed with the existing scaffold's safety nets rather than replacing
them:

1. **Specify** — same as greenfield, but the `feature-spec` skill additionally checks whether the
   touched area already has a `codebase-recon` knowledge doc or local `CLAUDE.md`. If not, that gap
   is flagged explicitly rather than silently skipped — see the tribal-knowledge-gap finding in
   `ai-agents-legacy-codebases-2026.md` §3.
2. **Recon first if unfamiliar** — run `codebase-recon` on the touched module before planning, per
   the existing scaffold's "before you edit anything unfamiliar" guidance.
3. **Characterize before changing, not before adding** — if the feature requires modifying
   *existing* weakly-tested behavior (not just adding new, isolated code), run
   `characterization-test` first to pin current behavior. Purely additive changes (a new endpoint,
   a new function with no existing caller) don't need this step; changes that alter an existing
   code path do.
4. **Implement via TDD** — same as greenfield for the new code being added.
5. **Roll out incrementally** — prefer feature flags or a strangler-fig-style incremental cutover
   over a single big-bang merge, consistent with the migration pairing already recommended in
   `ai-agents-legacy-codebases-2026.md` §8 (characterization tests + strangler-fig + human review +
   differential validation before shipping).

No single agent safely modernizes or extends a legacy codebase alone — agents don't see the
business context behind the code, which is why legacy feature work still needs a human-led
strategy, not just a longer prompt.

- [Legacy Code Modernization with AI Agents (2026) — Tembo.io](https://www.tembo.io/blog/legacy-code-modernization)
- [AI Agents Don't Modernize Legacy Code on Their Own — isaqb](https://www.isaqb.org/blog/ai-agents-dont-modernize-legacy-code-on-their-own/)

## 9. Findings-to-scaffold map

| Finding | Addressed by |
|---|---|
| Ungrounded "vibe coding" causes drift from intent | `feature-spec` skill (specify phase, before any code is written) |
| Architectural grounding improves functional correctness (ICSE 2026) | `feature-spec` skill writes the spec to `docs/specs/`, referenced during implementation |
| Agents may edit tests to force a pass | `tdd-implement` skill's commit-tests-before-implementing step |
| Narrow, scoped context outperforms vague prompts | `feature-spec` skill's explicit scope/out-of-scope/interfaces fields |
| Multi-agent orchestration only pays off for genuinely parallel work | §5 guidance in this doc; not scaffolded as a default skill/agent (single-agent TDD loop is the default path) |
| Greenfield/legacy productivity gap requires different composition | Methodology split (§7 vs §8) in this doc; `feature-spec` skill's recon-doc check gates which path applies |
| Legacy feature work must not silently skip the tribal-knowledge check | `feature-spec` skill flags missing `codebase-recon`/`CLAUDE.md` coverage instead of proceeding silently |
| Modifying existing weakly-tested behavior risks silent breakage | `tdd-implement` skill's explicit hand-off to `characterization-test` when behavior (not just new code) is touched |
| A write-capable subagent is needed but must stay clearly distinct from the read-only legacy explorer | `feature-implementer` subagent (Read/Grep/Glob/Edit/Write/test-Bash), documented in contrast to `legacy-explorer` |
| Incremental rollout beats big-bang merges on legacy systems | §8 guidance, consistent with existing strangler-fig recommendation in `ai-agents-legacy-codebases-2026.md` §8 |
