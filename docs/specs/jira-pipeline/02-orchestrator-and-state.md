# Orchestrator and state

The "GitHub Actions only" hosting decision means there's no database and no long-running process.
Everything the orchestrator needs to track has to live in a GitHub-native object. This doc is the
mapping from orchestration concepts to those objects.

## 1. Why a tracking issue is the state object

Each ticket gets exactly one open GitHub issue in the control repo for its entire lifetime in the
pipeline. It plays the role a row in an orchestrator's database would play elsewhere:

| Orchestration need | GitHub-native mechanism |
|---|---|
| Current stage (spec / awaiting-approval / implement / blocked / done) | A single `stage:*` label, swapped as the ticket moves — only one `stage:*` label present at a time |
| Ticket identity / lookup | `ticket:{{ticket_key}}` label + title prefix, searchable via `gh issue list --label` |
| History / audit trail | Issue comments and label-change timeline — free, visible, already searchable in GitHub's UI |
| Human decision point | Issue comments (`/approve`, `/request-changes`) — see `03-plan-approval-gate.md` |
| Link to the work | A comment linking the draft PR once the spec workflow opens one |
| Link to the source ticket | The JIRA URL in the issue body from intake |

This also means anyone can inspect pipeline state with `gh issue list --label pipeline` — no
separate dashboard needed for a first version.

## 2. Stage labels and transitions

```
stage:spec  →  stage:awaiting-approval  →  stage:implement  →  stage:in-review  →  stage:done
                     │                            │
                     ├─(reject)→ stage:spec        ├─(agent stuck / CI red after N retries)→ stage:blocked
                     │                                              │
                     └───────────(approval timeout)→ stage:blocked  └─(human intervenes, relabels)→ stage:implement
```

Each workflow in `04-agent-execution.md` and `05-review-merge-and-sync.md` is triggered by an
`issues: [labeled]` event matching the stage it owns, and its last step swaps the label to the next
stage (or to `stage:blocked` on failure). This makes the label the only synchronization primitive
needed — no polling, no external queue.

`stage:blocked` is a deliberate terminal-until-human-acts state: workflows never auto-retry out of
it. A comment explaining what failed (CI failure, agent hit `--max-turns`, approval timeout) is
posted before the relabel, so a human can act without digging through Actions logs.

## 3. Concurrency

Two concurrency concerns, both handled with GitHub Actions' native `concurrency` key — no separate
queue needed:

- **Per-ticket:** only one workflow should touch a given ticket's branch/PR at a time (e.g. an
  approval arriving while the spec workflow is still finishing shouldn't race the implement
  workflow's checkout). Every workflow that acts on a ticket sets:
  ```yaml
  concurrency:
    group: ticket-${{ github.event.client_payload.ticket_key || <parsed from issue labels> }}
    cancel-in-progress: false
  ```
  `cancel-in-progress: false` because a half-finished agent commit is worse than a queued wait.
- **Global:** a repo-level or org-level cap on concurrent `claude-code-action` runs, to bound cost
  and avoid overwhelming Actions runners if many tickets are dispatched at once. Start with GitHub
  Actions' own concurrent-job limits (plan-dependent) rather than building a custom limiter; revisit
  only if tickets queue for longer than acceptable.

## 4. What this design deliberately does not do

- **No cross-ticket prioritization/scheduling logic.** Tickets are processed as their triggering
  events arrive; there's no priority queue. Add one only if ticket volume makes FIFO-via-Actions
  actually insufficient — don't build it speculatively.
- **No persistent metrics store.** GitHub's own Actions run history and issue/label state are the
  only reporting surface for a first version. If dashboarding becomes a real need, that's an
  additive workflow (e.g. exporting issue/label state to a sheet on a schedule), not a redesign of
  the state model above.
