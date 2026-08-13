# Legacy/recon workflow: working safely in unfamiliar code

The decision flow for touching an existing module on a large, poorly tested/documented codebase —
the scaffold's core defense against the tribal-knowledge gap that both the agent and a human
reviewer can share.

```mermaid
flowchart TD
    A["About to edit code in an unfamiliar\n/ legacy area"] --> B{"Does a docs/agent-notes/<module>.md\n(codebase-recon output) or local\nCLAUDE.md already cover this area?"}

    B -- no --> C["Run codebase-recon skill\n(read-only: file search / read / grep only)\noften delegated to the legacy-explorer subagent"]
    C --> D["Produces docs/agent-notes/<module>.md:\npurpose, entry points, dependencies,\ninferred invariants"]
    D --> E["MANDATORY: 'Unknowns / tribal-knowledge\ngaps found' section — an empty section\nis a red flag, not a good sign"]
    E --> F["Proposes (does not apply) CLAUDE.md\nadditions for this module"]
    F --> G

    B -- yes --> G{"Is the code path you're about\nto change weakly tested?\n(coverage % is not a reliable signal)"}

    G -- yes --> H["Run characterization-test skill\n(read target + call sites, enumerate\nbranches/edge cases, draft golden-master tests)"]
    H --> I["Run drafted tests against UNMODIFIED\ncode to confirm they pass as baseline"]
    I --> J["Report to human: coverage achieved,\nopen uncertainties, explicit 'draft, not\nyet trusted' status"]
    J --> K["Human executes and reviews the tests\nthemselves — do not trust the agent's\nclaim that they pass"]
    K --> L["Proceed to refactor/change,\npreferring strangler-fig rollout\nfor larger migrations"]

    G -- no --> L

    L --> M["Session ends → Stop hook may propose\nCLAUDE.md updates (see trigger-map.md)"]
    M --> N["DRI reviews .claude/proposed-updates/\nand merges useful entries into CLAUDE.md"]
    N -.->|"closes the loop:\nfuture sessions start\nwith better coverage"| B
```

## Notes

- **The riskiest failure mode here is a shared blind spot**, not hallucination: a reviewer often
  lacks the same tribal knowledge the agent lacks, so neither can catch what neither knows. That's
  why `codebase-recon`'s "unknowns" section and `characterization-test`'s human-execution
  requirement are both non-negotiable steps in this flow, not optional polish.
- **`codebase-recon` and `characterization-test` are separate, sequential skills**, not one
  combined step — recon establishes *what the code does and what's unknown*; characterization
  pins *current behavior* before it changes. Running characterization first without recon risks
  missing an invariant recon would have surfaced (e.g., "always called inside a transaction").
- **Nothing in this flow edits `CLAUDE.md` directly.** Every proposed addition — from recon or from
  the Stop hook — lands in `.claude/proposed-updates/` for a human to merge deliberately.

See also: `docs/research/ai-agents-legacy-codebases-2026.md` §3, §6, §8–9 (the research this flow
operationalizes); `scaffold/.claude/skills/codebase-recon/SKILL.md`;
`scaffold/.claude/skills/characterization-test/SKILL.md`; `scaffold/.claude/agents/legacy-explorer.md`.
