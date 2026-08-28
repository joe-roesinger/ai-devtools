# Review, merge, and JIRA sync-back

The last leg: getting a completed PR through review and closing the loop back to JIRA so ticket
status stays truthful.

## 1. CI and automated review

Once the implement workflow marks the PR ready for review (`04-agent-execution.md` §2):

1. **Standard CI** runs exactly as it would for a human-authored PR — no special-casing for
   agent-authored PRs. This is the primary automated quality gate; nothing here should be treated as
   "trusted because an agent wrote it."
2. **Optional automated review pass** before human eyes: trigger the repo's `/code-review` skill
   (see the top-level skill listing) against the PR diff, at `medium` or `high` effort, as a required
   check or a bot-posted review comment. The goal is that a human reviewer only sees a PR that
   already cleared an automated correctness/simplification pass — not a replacement for human
   review, a pre-filter on it.
3. Findings from the automated pass that are auto-fixable can be applied via `--fix` in the same
   workflow run, committed back to the branch, before the PR is handed to a human — reduces review
   round-trips for mechanical issues.

## 2. Human review and merge

Standard PR review — this pipeline doesn't change who reviews or the repo's existing merge/branch
protection rules. The only pipeline-specific addition: relabel the tracking issue to `stage:done`
in the same workflow that reacts to the merge (step 1 below), not before, so the tracking issue's
stage always reflects reality even if a PR sits open for a while after CI passes.

## 3. JIRA status sync

Two sync points, both via JIRA's REST API (`POST /rest/api/3/issue/{key}/transitions`) using a JIRA
API token stored as a GitHub Actions secret (`JIRA_API_TOKEN`, `JIRA_BASE_URL`):

- **PR opened / marked ready for review** (`pull_request: [ready_for_review]`) → transition the
  JIRA ticket to `In Review`, comment the PR link on the JIRA ticket via
  `POST /rest/api/3/issue/{key}/comment`.
- **PR merged** (`pull_request: [closed]` with `merged == true`) → transition the JIRA ticket to
  `Done`, comment the merge commit / PR link on the JIRA ticket, relabel the tracking issue
  `stage:done`, and close the tracking issue.

Both are handled by one workflow, `.github/workflows/pipeline-sync-jira.yml`, keyed off the
`ticket:{{ticket_key}}` label already on the tracking issue (looked up from the PR's linked issue,
or from a `Ticket: {{ticket_key}}` trailer the spec workflow adds to the PR description when it's
first opened — needed either way since the PR itself doesn't carry the label).

## 4. Failure paths

- **JIRA API call fails** (auth expired, ticket status doesn't allow the transition, network
  error): comment the failure on the tracking issue and leave it in its current stage rather than
  marking `stage:done` on a sync that didn't actually happen — the tracking issue's stage should
  never claim more than what's verified.
- **PR closed without merging** (abandoned): relabel tracking issue `stage:blocked` with a comment,
  don't touch JIRA status — a human closed it for a reason that needs a human decision on the
  ticket, not an automated status change.

## 5. What "feature completion" means here

End state for a successful run: PR merged, JIRA ticket `Done` with a comment linking the PR, tracking
issue closed. Nothing beyond that (e.g. deployment) is in scope for this pipeline — deploy is a
separate concern with its own approval/rollback requirements and shouldn't be folded into a
JIRA-to-PR pipeline without its own dedicated design.
