# Plan approval gate

Where the spec is surfaced to a human, how approval is given, and why this is a comment command
rather than a label click or a JIRA-side action.

## 1. Why gate here, not fully autonomous

Per `00-overview.md` §2: greenfield scope is easy to misjudge, and catching a wrong-scope spec
before implementation starts is far cheaper than catching it at PR review, after an agent has spent
a full `tdd-implement` loop building the wrong thing. This is the single required human checkpoint
between ticket intake and PR review.

## 2. Where the spec is posted

The spec workflow (`04-agent-execution.md`) runs `feature-spec`, which writes
`docs/specs/<feature>.md` in the target repo/branch per the existing skill convention. The
orchestrator then:

1. Opens a **draft PR** with that commit (draft, not ready-for-review — it isn't reviewable code
   yet, just a spec).
2. Posts the full rendered spec as a comment on the **tracking issue** (not the PR) — the tracking
   issue is the single place a human watching the pipeline looks, per `02-orchestrator-and-state.md`
   §1. The comment includes a link to the draft PR.
3. Relabels the tracking issue `stage:awaiting-approval`.

## 3. Approval mechanism

A human reviews the spec comment and responds **on the tracking issue** with one of:

- `/approve` — proceed to implementation as spec'd.
- `/approve with: <note>` — proceed, but pass `<note>` into the implement phase's context as an
  addendum (e.g. a small scope clarification not worth a full spec rewrite).
- `/request-changes <feedback>` — send back to the spec workflow with `<feedback>` appended to the
  spec prompt's context; label returns to `stage:spec`, spec workflow re-runs, new spec version
  posted as a new comment (old spec comment left in place for history, not edited).

These are plain comment commands, not a GitHub PR "Approve" review and not a label a bot applies on
click, because:

- A comment is naturally logged with author and timestamp in the issue timeline — the audit trail
  `02-orchestrator-and-state.md` relies on comes for free.
- It keeps the approval surface consistent regardless of whether the underlying work is a new repo,
  a new branch, or (later) multiple PRs per ticket — the tracking issue is the stable anchor.

## 4. Permission check

`.github/workflows/approval-gate.yml`, triggered on `issue_comment: [created]`, must verify **before
acting on the command**:

1. The issue has label `stage:awaiting-approval` (ignore comments on issues in any other stage —
   avoids acting on stale or misdirected commands).
2. The comment body matches `/approve`, `/approve with:`, or `/request-changes` exactly at the start
   of the comment (avoid false-triggering on a comment that merely mentions the word).
3. **The commenter has write access to the repo.** This mirrors the exact check
   `remote-agents-2026.md` §3 documents for `claude-code-action` itself — approval to spend agent
   budget and merge code downstream is exactly the kind of action that must not be triggerable by an
   arbitrary GitHub account. Use the same `repos.checkCollaborator`-style API check the Action
   itself relies on.

A comment failing check 2 or 3 is silently ignored (or reacted to with a clarifying comment if it
looked like an attempted command from a non-privileged user) — never acted on.

## 5. Timeout

If a ticket sits in `stage:awaiting-approval` longer than a configured window (start at 5 business
days — tune from real usage), a scheduled workflow relabels it `stage:blocked` with a comment noting
the timeout, rather than leaving agent-authored draft PRs open indefinitely. This is a stale-state
cleanup, not a rejection — a human can still comment `/approve` later and manually relabel.

## 6. Open question

Round-trip limit on `/request-changes` is listed as open in `00-overview.md` §5 — without one, a
ticket could cycle spec revisions indefinitely. A reasonable default to validate: after 3 rejected
spec versions, force `stage:blocked` with a comment suggesting the ticket needs synchronous
discussion rather than more async spec iterations.
