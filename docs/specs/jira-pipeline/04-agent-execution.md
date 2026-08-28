# Agent execution

How the orchestrator actually invokes Claude Code for the spec and implement phases. This
deliberately reuses `scaffold/.github/workflows/claude.yml` and the existing skills rather than
inventing a new invocation path — per `remote-agents-2026.md` §5, the Action reads `CLAUDE.md` and
`.claude/skills/` identically whether it's triggered by an `@claude` mention or by this pipeline's
own workflow.

## 1. Spec workflow

`.github/workflows/pipeline-spec.yml`, triggered on `issues: [labeled]` where the label is
`stage:spec`:

1. Determine target: new repo or existing repo/branch (see §4 below).
2. Check out (or create) the target, on a new branch named `pipeline/{{ticket_key}}`.
3. Run `claude-code-action` in **automation mode** (a `prompt` input is set, so it runs
   unconditionally rather than waiting for a mention — see `remote-agents-2026.md` §3):
   ```yaml
   - uses: anthropics/claude-code-action@v1
     with:
       prompt: |
         Run the `feature-spec` skill for this ticket. Do not implement anything yet.
         Ticket: {{ticket_key}} — {{summary}}
         Description: {{description}}
         Acceptance criteria: {{acceptance_criteria}}
         ${{ if request-changes feedback exists: include it here }}
       claude_args: "--allowed-tools 'Read,Grep,Glob,Edit,Write,Bash(git *)' --max-turns 30"
   ```
   Tool scope is deliberately narrow: no arbitrary `Bash`, no network tools — spec-writing needs
   file read/write and git, nothing else. This is the CI-equivalent narrow-allowlist principle from
   `remote-agents-2026.md` §4.
4. Commit `docs/specs/<feature>.md`, push the branch, open a **draft PR**.
5. Post the spec content as a tracking-issue comment, relabel `stage:awaiting-approval`
   (`03-plan-approval-gate.md`).

## 2. Implement workflow

`.github/workflows/pipeline-implement.yml`, triggered on `issues: [labeled]` where the label is
`stage:implement`:

1. Check out the existing `pipeline/{{ticket_key}}` branch (spec commit already on it).
2. Run `claude-code-action` invoking `tdd-implement` against the spec's task list:
   ```yaml
   - uses: anthropics/claude-code-action@v1
     with:
       prompt: |
         Run `tdd-implement` for each task in docs/specs/<feature>.md's task list, in order.
         ${{ approval note from /approve with:, if any }}
       claude_args: "--allowed-tools 'Read,Grep,Glob,Edit,Write,Bash' --max-turns 120"
   ```
   Wider `Bash` access than the spec phase is justified here (tests/build tooling need to run) but
   still no network/deploy tools — implementation shouldn't need them.
3. Since this is greenfield work (per `00-overview.md` §1), no `characterization-test` detour is
   invoked — `tdd-implement` runs its default red-green-refactor loop per task directly, per
   `feature-development-workflow.md`'s greenfield branch.
4. On all tasks complete and tests green: mark the PR ready for review, relabel tracking issue
   `stage:in-review`.
5. On CI failure that doesn't resolve within the agent's own retry attempts, or `--max-turns`
   exhausted: relabel `stage:blocked`, comment with the failure summary and a link to the run log —
   never loop indefinitely.

## 3. Delegating to `feature-implementer`

Per the existing scaffold, `tdd-implement` may delegate individual tasks to the `feature-implementer`
subagent (Read/Grep/Glob/Edit/Write/Bash, pinned to a mid-tier model). No change needed here — this
pipeline's workflow just needs to invoke `tdd-implement`; which subagent it delegates to internally
is the skill's own concern, unchanged from local usage.

## 4. Greenfield target: new repo vs. new branch

This is flagged as an open question in `00-overview.md` §5. Two supported shapes, chosen per-ticket
by a `target_repo` field in the JIRA payload (empty = create new):

- **New branch in an existing repo:** the common case for "new module in an existing project."
  Steps 1–2 above operate directly on that repo.
- **New repo from a template:** for a genuinely new project. An extra step before spec workflow
  step 2: `gh repo create {{org}}/{{derived-name}} --template {{org}}/project-template --private`,
  where `project-template` is a repo already carrying `scaffold/`'s `CLAUDE.md` + `.claude/`
  contents (see `scaffold/SCAFFOLD-README.md` for how the scaffold is meant to be copied in) so the
  new repo has the same skills available from commit one. Requires the intake PAT (or a separate
  repo-creation PAT) to have `Administration: write` at the org level — a materially wider scope
  than the `Contents`/`Issues` write used elsewhere, worth a separate credential rather than widening
  the intake PAT.

## 5. Cost controls

`--max-turns` above are placeholders — tune from real runs. Combine with a workflow-level
`timeout-minutes` so a hung Action job doesn't run indefinitely on the runner even if the agent
itself is still within its turn budget. This is the concrete mechanism for the "cost/runaway
controls" open question in `00-overview.md` §5.
