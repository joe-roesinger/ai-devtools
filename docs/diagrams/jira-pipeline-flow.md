# JIRA pipeline flow: ticket → tracking issue → merged PR

The state machine a single JIRA ticket moves through under `docs/specs/jira-pipeline/`. Composes
with `trigger-map.md` (this adds a new trigger branch alongside the existing `@claude`-mention
trigger) and `feature-development-workflow.md` (unchanged — this pipeline hands off into it
unmodified at the spec/implement steps).

```mermaid
flowchart TD
    A["JIRA ticket moved to 'Ready for Agent'"] --> B["JIRA Automation: Send web request\nrepos/{control-repo}/dispatches\nevent_type=jira-ticket-ready"]
    B --> C["intake.yml: validate payload,\ncheck for duplicate tracking issue"]
    C --> D["Create tracking issue\nlabels: pipeline, ticket:KEY, stage:spec"]

    D --> E["pipeline-spec.yml (stage:spec)\nruns feature-spec via claude-code-action\n--allowed-tools Read,Grep,Glob,Edit,Write,Bash(git *)"]
    E --> F["Commit docs/specs/<feature>.md,\nopen DRAFT PR, post spec on tracking issue"]
    F --> G["Relabel stage:awaiting-approval"]

    G --> H{"Human comments on tracking issue"}
    H -- "/approve or /approve with:" --> I["Permission check: write access?"]
    H -- "/request-changes" --> J["Relabel stage:spec\n(feedback appended to next spec prompt)"]
    J --> E
    H -- "timeout (5 business days)" --> K["Relabel stage:blocked"]

    I -- no --> L["Ignore comment"]
    I -- yes --> M["Relabel stage:implement"]

    M --> N["pipeline-implement.yml (stage:implement)\nruns tdd-implement via claude-code-action\ntask-by-task on the spec's task list"]
    N --> O{"All tasks green,\nCI passing?"}
    O -- "no, retries exhausted / max-turns hit" --> K
    O -- yes --> P["Mark PR ready for review,\nrelabel stage:in-review"]

    P --> Q["Standard CI + optional /code-review pass\n(auto-fixable findings applied before human review)"]
    Q --> R["Human reviews and merges PR"]

    R --> S["pipeline-sync-jira.yml (pull_request closed, merged)\nJIRA: transition to Done + comment PR link"]
    S --> T["Relabel stage:done, close tracking issue"]

    R -.->|"closed without merging"| K
    K -.->|"human relabels manually after resolving"| M
```

## Notes

- **The tracking issue is the only state object** — see `docs/specs/jira-pipeline/02-orchestrator-and-state.md`
  for why a database/hosted service was deliberately avoided given the "GitHub Actions only"
  hosting decision.
- **`stage:blocked` is terminal until a human acts.** No workflow auto-retries out of it — a
  comment explaining the failure is always posted before the relabel, consistent with
  `03-plan-approval-gate.md`'s approach to timeouts and rejection limits.
- **The permission check at `/approve` mirrors the one `claude-code-action` itself already applies**
  to who can trigger a run (`remote-agents-2026.md` §3) — approval to spend agent budget and merge
  code downstream needs the same bar.
- **Everything right of "runs feature-spec" / "runs tdd-implement" is unchanged scaffold behavior.**
  This diagram's only new contribution is everything left of and around those two boxes — getting a
  ticket into the existing loop and getting the result back out to JIRA.

See also: `docs/specs/jira-pipeline/00-overview.md` (full spec), `docs/diagrams/trigger-map.md`,
`docs/diagrams/feature-development-workflow.md`.
