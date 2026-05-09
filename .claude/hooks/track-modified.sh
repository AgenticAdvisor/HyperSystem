#!/usr/bin/env bash
# PostToolUse hook — track files modified by Write|Edit tools
# Appends file paths to a temp file for session close tracking.

set -euo pipefail

# Claude Code passes hook payload as JSON on stdin
PAYLOAD=$(cat)
SESSION_ID="${SESSION_ID:-default}"
TRACKING_FILE="/tmp/.claude-modified-files-${SESSION_ID}"

if [[ -n "$PAYLOAD" ]]; then
  FILE_PATH=$(echo "$PAYLOAD" | grep -o '"file_path": *"[^"]*"' | head -1 | sed 's/"file_path": *"//;s/"$//' || true)
  if [[ -n "$FILE_PATH" ]]; then
    echo "$FILE_PATH" >> "$TRACKING_FILE"
  fi
fi
