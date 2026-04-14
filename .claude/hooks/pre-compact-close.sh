#!/usr/bin/env bash
# PreCompact hook — enforce close-before-compact
# If files were modified and session wasn't closed, inject a reminder.

set -euo pipefail

SESSION_ID="${SESSION_ID:-default}"
TRACKING_FILE="/tmp/.claude-modified-files-${SESSION_ID}"
CLOSE_MARKER="/tmp/.claude-session-closed-${SESSION_ID}"

if [[ -f "$TRACKING_FILE" && ! -f "$CLOSE_MARKER" ]]; then
  echo "{\"additionalContext\": \"⚠️ Run /close before compacting. Files were modified this session and governance state needs updating.\"}"
else
  echo "{}"
fi

exit 0
