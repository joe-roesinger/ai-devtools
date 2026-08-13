#!/usr/bin/env bash
# SessionStart hook: surface known gotchas and any pending, unreviewed documentation
# proposals at the top of every session. Read-only — no side effects.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
claude_md="$repo_root/CLAUDE.md"
proposals_dir="$repo_root/.claude/proposed-updates"

if [ -f "$claude_md" ]; then
  echo "## Known landmines (from CLAUDE.md)"
  awk '/^## Known landmines/{flag=1; next} /^## /{flag=0} flag' "$claude_md"
fi

if [ -d "$proposals_dir" ] && [ -n "$(ls -A "$proposals_dir" 2>/dev/null)" ]; then
  echo
  echo "## Pending documentation proposals (not yet reviewed)"
  ls -1 "$proposals_dir"
  echo "Review these with the DRI before they go stale; see CLAUDE.md governance section."
fi
