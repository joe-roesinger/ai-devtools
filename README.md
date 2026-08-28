# AI-Assisted Development Tooling for Legacy Codebases

Research and a reusable Claude Code configuration scaffold for using Claude (CLI and the
JetBrains/IntelliJ plugin) effectively against a large, poorly tested and poorly documented legacy
application.

- [`docs/research/ai-agents-legacy-codebases-2026.md`](docs/research/ai-agents-legacy-codebases-2026.md) —
  2026 research summary: the brownfield performance gap, why legacy code fools both agents and
  reviewers, characterization testing, Anthropic's official large-codebase guidance, and
  JetBrains/IntelliJ plugin specifics. Each finding is cited and mapped to a scaffold artifact.
- [`docs/research/agentic-feature-development-2026.md`](docs/research/agentic-feature-development-2026.md) —
  2026 research summary on writing new features with agents: spec-driven development, TDD as the
  implementation loop, context engineering, and multi-agent orchestration, with the methodology
  split between greenfield and legacy work. Each finding is cited and mapped to a scaffold artifact.
- [`docs/research/remote-agents-2026.md`](docs/research/remote-agents-2026.md) — 2026 research
  summary on running Claude Code as a remote, GitHub-triggered agent: setup mechanics, permission
  scoping without a human in the loop, and a research-backed answer to whether custom subagents
  beat a generic agent. Each finding is cited and mapped to a scaffold artifact.
- [`docs/research/token-cost-optimization-2026.md`](docs/research/token-cost-optimization-2026.md) —
  2026 research summary on reducing token spend: prompt caching as the highest-leverage lever,
  keeping `CLAUDE.md`/skills cache-prefix-lean, subagent context isolation, and model routing.
  Each finding is cited and mapped to a scaffold artifact.
- [`scaffold/`](scaffold/) — a portable `CLAUDE.md` + `.claude/` (skills, hooks, subagent, settings)
  that operationalizes those findings. See `scaffold/SCAFFOLD-README.md` for how to copy it into a
  real repo and validate it end-to-end.

## Specs

- [`docs/specs/jira-pipeline/`](docs/specs/jira-pipeline/) — technical spec for taking a JIRA
  ticket to a merged PR with minimal human touch: JIRA Automation → `repository_dispatch` →
  GitHub-Actions-only orchestrator (tracking issues + labels as state) → `feature-spec` with a
  human approval gate → `tdd-implement` → CI/review → JIRA status sync-back. Builds on the scaffold
  and remote-agent research above rather than replacing them; start at
  [`00-overview.md`](docs/specs/jira-pipeline/00-overview.md).

## Diagrams

Visual walkthroughs of the scaffold's control flow — what triggers what, and why — one diagram per
file:

- [`docs/diagrams/trigger-map.md`](docs/diagrams/trigger-map.md) — how a session starts (local
  hooks vs. remote `@claude` GitHub trigger) and what fires automatically.
- [`docs/diagrams/legacy-recon-workflow.md`](docs/diagrams/legacy-recon-workflow.md) — the decision
  flow for touching unfamiliar/legacy code: recon → characterization → refactor → doc feedback loop.
- [`docs/diagrams/feature-development-workflow.md`](docs/diagrams/feature-development-workflow.md) —
  greenfield vs. legacy feature development: spec → TDD loop.
- [`docs/diagrams/subagent-model-routing.md`](docs/diagrams/subagent-model-routing.md) — context
  isolation and model routing across the two subagents.
- [`docs/diagrams/jira-pipeline-flow.md`](docs/diagrams/jira-pipeline-flow.md) — the JIRA-to-PR
  pipeline's state machine: tracking issue, approval gate, and JIRA sync-back.
