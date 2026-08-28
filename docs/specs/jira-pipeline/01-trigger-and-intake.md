# Trigger and intake

How a JIRA ticket becomes a piece of tracked work in GitHub, with no hosted receiver.

## 1. JIRA-side: Automation rule

A JIRA Automation rule, scoped to the project(s) this pipeline covers:

- **Trigger:** issue transitions to a specific status — e.g. `Ready for Agent`. Using a status
  transition (not a generic field-changed trigger) makes the entry point visible and reversible in
  JIRA's own UI: a ticket only enters the pipeline when someone deliberately moves it there.
- **Condition:** issue type is one this pipeline handles (e.g. `Story`, `Task` — exclude `Bug`
  initially; bug fixes are a brownfield workflow this pipeline doesn't cover, see
  `agentic-feature-development-2026.md` §8 for why that's a materially different methodology).
- **Action:** "Send web request" to
  `https://api.github.com/repos/{org}/{control-repo}/dispatches`, method `POST`, with:
  - Header `Authorization: Bearer {{github_pat}}` — a fine-grained GitHub PAT, scoped to
    `Contents: write` + `Issues: write` on the control repo only, stored in JIRA Automation's own
    secret store (never in this repo).
  - Header `Accept: application/vnd.github+json`.
  - Body:
    ```json
    {
      "event_type": "jira-ticket-ready",
      "client_payload": {
        "ticket_key": "{{issue.key}}",
        "summary": "{{issue.summary}}",
        "description": "{{issue.description}}",
        "acceptance_criteria": "{{issue.customfield_XXXXX}}",
        "issue_type": "{{issue.issuetype.name}}",
        "reporter": "{{issue.reporter.emailAddress}}",
        "jira_url": "{{issue.url}}"
      }
    }
    ```
    `acceptance_criteria` should be its own JIRA field (custom field or a required section of the
    description) rather than parsed out of free text — `feature-spec` needs structured acceptance
    criteria as input, and asking the agent to infer them from prose is exactly the ungrounded
    "vibe coding" failure mode `agentic-feature-development-2026.md` §2 warns about.

No separate webhook receiver is needed: GitHub's `repository_dispatch` endpoint *is* the receiver,
and it's already authenticated by the PAT.

- [GitHub docs: Creating a repository dispatch event](https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event)

## 2. GitHub-side: intake workflow

`.github/workflows/intake.yml` in the control repo, triggered on:

```yaml
on:
  repository_dispatch:
    types: [jira-ticket-ready]
```

Steps:

1. Validate the payload has the required fields (`ticket_key`, `summary`,
   `acceptance_criteria`) — fail loudly and do not proceed if not, rather than letting a malformed
   payload reach the agent.
2. Check for an existing open tracking issue with the same `ticket_key` (search by title prefix or
   a hidden marker in the issue body) to make re-delivery idempotent — JIRA Automation and GitHub
   webhooks both retry on transient failures, and a duplicate tracking issue would fork the
   pipeline state for one ticket into two.
3. Create the **tracking issue** (see `02-orchestrator-and-state.md` for why an issue is the state
   object) with:
   - Title: `[{{ticket_key}}] {{summary}}`.
   - Body: the full `client_payload`, formatted, plus a link back to the JIRA ticket.
   - Labels: `pipeline`, `ticket:{{ticket_key}}`, `stage:spec`.
4. This issue creation is what the spec workflow in `04-agent-execution.md` listens for
   (`issues: [labeled]` on `stage:spec`).

## 3. Security notes

- The PAT is the only credential trusting inbound requests — anyone with it can create arbitrary
  tracking issues and trigger agent runs, so it must be scoped to the minimum (`Contents: write`,
  `Issues: write`, single repo) and rotated on the same cadence as other CI secrets.
- `repository_dispatch` has no signature verification of its own (unlike GitHub's inbound webhooks
  to third parties); the PAT *is* the auth. Do not widen its scope "for convenience."
- The intake workflow should not trust `client_payload` content as safe to interpolate directly
  into shell commands in later steps (a malicious or malformed JIRA summary could contain shell
  metacharacters) — treat it as untrusted input downstream, same as any external webhook body.
