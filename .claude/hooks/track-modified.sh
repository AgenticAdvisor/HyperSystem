#!/usr/bin/env bash
# PostToolUse hook — track files modified by Write|Edit tools
# Appends file paths to a temp file for session close tracking.

set -euo pipefail

TOOL_INPUT="${1:-}"
SESSION_ID="${SESSION_ID:-default}"
TRACKING_FILE="/tmp/.claude-modified-files-${SESSION_ID}"

# Extract file_path from tool input (JSON)
if [[ -n "$TOOL_INPUT" ]]; then
  FILE_PATH=$(echo "$TOOL_INPUT" | grep -o '"file_path": *"[^"]*"' | sed 's/"file_path": *"//;s/"$//' || true)
  if [[ -n "$FILE_PATH" ]]; then
    echo "$FILE_PATH" >> "$TRACKING_FILE"
  fi
fi
