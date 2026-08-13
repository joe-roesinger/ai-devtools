#!/usr/bin/env bash
# Stop hook: prompts the agent to propose CLAUDE.md updates based on what this session
# learned. This script itself does NOT write to CLAUDE.md and does NOT commit anything —
# it only ensures the proposals directory exists and prints instructions for the model to
# follow. The actual proposal content is written by the agent, as a new file under
# .claude/proposed-updates/, never as a direct edit to any CLAUDE.md.
#
# Guardrails (enforced by convention here, not by this script alone — review actual
# behavior against these before trusting the hook):
#   - Never edit CLAUDE.md or any subdirectory CLAUDE.md directly.
#   - Never run `git commit` or any write outside .claude/proposed-updates/.
#   - Avoid proposing the same update repeatedly across sessions (known open tuning
#     concern — see SCAFFOLD-README.md).
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
proposals_dir="$repo_root/.claude/proposed-updates"
mkdir -p "$proposals_dir"

cat <<'EOF'
Session ending. If this session surfaced anything worth documenting — a new gotcha, a
correction to existing CLAUDE.md content, a local convention encountered for the first
time — write a proposal file to .claude/proposed-updates/<timestamp>-<topic>.md
describing the suggested change as a diff-style note.

Do NOT edit CLAUDE.md or any subdirectory CLAUDE.md directly.
Do NOT commit anything.
If nothing new was learned this session, do nothing — do not manufacture a proposal just
to have output.
EOF
