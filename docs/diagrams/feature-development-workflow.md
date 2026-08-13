# Feature-development workflow: spec → TDD

How a new feature gets built under this scaffold, split by greenfield vs. legacy — and why the
split matters (see `docs/research/agentic-feature-development-2026.md` §7–8 for the research
behind the branch).

```mermaid
flowchart TD
    A["New feature requested\n(locally, or via @claude on a\nfeature-request.md-shaped issue)"] --> B{"Greenfield (new project/module,\nno existing behavior to protect)\nor legacy (touches an existing module)?"}

    B -- greenfield --> C1["Run feature-spec directly —\nno recon/characterization needed:\nnothing existing to be blind to"]
    B -- legacy --> C2["Run feature-spec"]
    C2 --> C3{"Does the touched area already have\na codebase-recon doc or local CLAUDE.md?"}
    C3 -- no --> C4["feature-spec flags the gap explicitly\nto the user — does not proceed as if\nthe area is understood"]
    C4 --> C5["Recommend running codebase-recon first\n(see legacy-recon-workflow.md)"]
    C3 -- yes --> D

    C1 --> D["feature-spec writes docs/specs/<feature>.md:\nwhat / why / explicit out-of-scope /\ninterfaces touched / acceptance criteria"]
    D --> E["Break spec into a small task list —\nindependently-verifiable vertical slices"]
    E --> F["Hand off to tdd-implement,\none task at a time\n(often delegated to feature-implementer subagent)"]

    F --> G{"Does this task modify existing,\nweakly-tested behavior — or only\nadd new, isolated code?"}
    G -- modifies existing --> H["Run characterization-test first\n(see legacy-recon-workflow.md)"]
    H --> I
    G -- new code only --> I["Write failing tests from the\nspec's acceptance criteria"]

    I --> J["Confirm tests fail against current code"]
    J --> K["Commit failing tests as a checkpoint"]
    K --> L["Implement until green —\nNEVER edit the committed tests"]
    L --> M{"Test looks wrong once\nimplementing against it?"}
    M -- yes --> N["Stop and flag to the human —\ndo not silently 'fix' the test"]
    M -- no --> O["Refactor only once green,\nstaying green throughout"]

    O --> P{"More tasks in the spec's list?"}
    P -- yes --> F
    P -- no --> Q["Feature complete:\nreport what was implemented,\nwhich acceptance criteria are covered,\nanything left unverified"]
```

## Notes

- **`feature-spec` always runs first, on both branches.** The greenfield/legacy split changes
  *what else* runs before implementation (nothing extra vs. a recon-coverage check), not whether a
  spec exists — this guards against the core failure mode the skill targets: an agent producing
  plausible code that quietly solves the wrong problem because nobody grounded it in a real spec.
- **The recon-coverage check in step `C3` cannot be skipped even if the user seems confident the
  area is well understood** — per `feature-spec/SKILL.md`'s own guardrail, the check costs one file
  lookup and the risk of skipping it is a shared blind spot between the agent and the reviewer.
- **This composes identically for remote/GitHub-triggered work.** `CLAUDE.md`'s "Before starting a
  new feature" section is read the same way by a local session and by the GitHub Action, so no
  extra workflow-level logic is needed to route an `@claude`-tagged issue through this same flow.

See also: `docs/research/agentic-feature-development-2026.md`;
`scaffold/.claude/skills/feature-spec/SKILL.md`; `scaffold/.claude/skills/tdd-implement/SKILL.md`;
`scaffold/.claude/agents/feature-implementer.md`; `scaffold/.github/ISSUE_TEMPLATE/feature-request.md`.
