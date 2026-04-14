#!/usr/bin/env bash
# Stop hook — warn if files were modified but session wasn't closed
# Does NOT block (exit 0) — warns only via additionalContext.

set -euo pipefail

SESSION_ID="${SESSION_ID:-default}"
TRACKING_FILE="/tmp/.claude-modified-files-${SESSION_ID}"
CLOSE_MARKER="/tmp/.claude-session-closed-${SESSION_ID}"

if [[ -f "$TRACKING_FILE" && ! -f "$CLOSE_MARKER" ]]; then
  MODIFIED_COUNT=$(sort -u "$TRACKING_FILE" | wc -l | tr -d ' ')
  echo "{\"additionalContext\": \"⚠️ Session close warning: $MODIFIED_COUNT file(s) were modified but /close was not run. Run /close to update HANDOFF.json, CURRENT-SPRINT.md, and the work changelog.\"}"
else
  echo "{}"
fi

exit 0
