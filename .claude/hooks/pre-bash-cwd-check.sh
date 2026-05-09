#!/usr/bin/env bash
# PreToolUse hook — warn when running git commands from inside a nested git
# repo whose toplevel differs from the workspace root.
#
# Why: workspaces sometimes nest private repos (e.g., Projects/<Name>/.git)
# whose HEAD intentionally diverges from the workspace branch HEAD for weeks
# at a time. A `git status` from inside the nested dir reads the WRONG HEAD
# and reports phantom modifications. Worse, a `git push` runs against the
# WRONG remote silently. Both repos share one working tree, so commands
# "succeed" without error.
#
# Behavior: informational warning via additionalContext; exit 0 (never
# blocks). Skips commands that already use `git -C <path>` or chain a
# `cd <workspace>` (operator anchored explicitly). Covers read-state
# subcommands AND write/mutate subcommands (push/fetch/pull/commit/checkout
# /switch/merge/rebase/reset/tag/cherry-pick).

set -euo pipefail

PAYLOAD=$(cat)
[[ -z "$PAYLOAD" ]] && exit 0

COMMAND=$(echo "$PAYLOAD" | grep -o '"command": *"[^"]*"' | head -1 | sed 's/"command": *"//;s/"$//' 2>/dev/null || true)
[[ -z "$COMMAND" ]] && exit 0

# Only check git subcommands that read or mutate repo state.
if ! echo "$COMMAND" | grep -qE '(^|[[:space:]&;|()])git[[:space:]]+(status|diff|log|branch|show|stash[[:space:]]+list|push|fetch|pull|commit|checkout|switch|merge|rebase|reset|tag|cherry-pick)([[:space:]]|$)'; then
  exit 0
fi

# Skip if already anchored via `git -C <path>` form.
if echo "$COMMAND" | grep -qE 'git[[:space:]]+-C[[:space:]]'; then
  exit 0
fi

# CLAUDE_PROJECT_DIR is required — Claude Code sets it; if absent, can't
# determine workspace root, so skip silently rather than warn-by-mistake.
WORKSPACE_ROOT="${CLAUDE_PROJECT_DIR:-}"
[[ -z "$WORKSPACE_ROOT" ]] && exit 0

# Skip if command chains a `cd` to the workspace root before the git call.
if echo "$COMMAND" | grep -qE "cd[[:space:]]+(\"|')?${WORKSPACE_ROOT}"; then
  exit 0
fi

# Compare cwd's git toplevel against workspace root.
CWD_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "$CWD_TOPLEVEL" ]] && exit 0  # cwd not inside any git repo

WORKSPACE_REAL=$(cd "$WORKSPACE_ROOT" 2>/dev/null && pwd -P || echo "$WORKSPACE_ROOT")
CWD_TOPLEVEL_REAL=$(cd "$CWD_TOPLEVEL" 2>/dev/null && pwd -P || echo "$CWD_TOPLEVEL")

if [[ "$CWD_TOPLEVEL_REAL" != "$WORKSPACE_REAL" ]]; then
  CURRENT_PWD=$(pwd)
  MSG="cwd-drift warning: current dir ${CURRENT_PWD} resolves to git repo ${CWD_TOPLEVEL_REAL}, NOT workspace root ${WORKSPACE_REAL}. The git command will operate against the NESTED repo. If you intended workspace state, prefer: git -C ${WORKSPACE_REAL} <subcommand>  OR  cd ${WORKSPACE_REAL} && <command>. Informational only — proceeding."
  # Emit as JSON additionalContext (matches pre-tool-bash-guard.sh convention).
  printf '{"additionalContext": "⚠️ %s"}\n' "$MSG"
fi

exit 0
