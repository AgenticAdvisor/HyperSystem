#!/usr/bin/env bash
# PostToolUse hook — track files modified by Write|Edit tools
# Appends file paths to a temp file for session close tracking.

set -euo pipefail

# shellcheck disable=SC1090
source "$(dirname "$0")/../../tools/_hook_payload.sh"

# Claude Code passes hook payload as JSON on stdin
PAYLOAD=$(cat)
SESSION_ID="${SESSION_ID:-default}"
TRACKING_FILE="/tmp/.claude-modified-files-${SESSION_ID}"

if [[ -n "$PAYLOAD" ]]; then
  FILE_PATH=$(echo "$PAYLOAD" | extract_field tool_input.file_path)
  if [[ -n "$FILE_PATH" ]]; then
    echo "$FILE_PATH" >> "$TRACKING_FILE"
  fi
fi
