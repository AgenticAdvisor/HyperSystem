#!/usr/bin/env bash
# SessionStart hook — health check + context injection
# Runs before Claude processes anything. Injects session state via stdout JSON.

set -euo pipefail

# WORKSPACE_OVERRIDE allows the test suite to point at a synthetic repo.
# Default: derive from script location (parent of .claude/hooks/).
WORKSPACE="${WORKSPACE_OVERRIDE:-$(cd "$(dirname "$0")/../.." && pwd)}"
WARNINGS=()

# Three-date sentinel: changelog, handoff, sprint dates should match
if [[ -f "$WORKSPACE/HANDOFF.json" ]]; then
  HANDOFF_DATE=$(grep -o '"date": *"[^"]*"' "$WORKSPACE/HANDOFF.json" | head -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}')
fi

if [[ -f "$WORKSPACE/CURRENT-SPRINT.md" ]]; then
  SPRINT_DATE=$(grep -o 'Last updated: [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' "$WORKSPACE/CURRENT-SPRINT.md" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}')
fi

if [[ -f "$WORKSPACE/executive-summary/work-changelog.md" ]]; then
  CHANGELOG_DATE=$(grep -o '## [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' "$WORKSPACE/executive-summary/work-changelog.md" | head -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}')
fi

if [[ -n "${HANDOFF_DATE:-}" && -n "${SPRINT_DATE:-}" && "$HANDOFF_DATE" != "$SPRINT_DATE" ]]; then
  WARNINGS+=("Three-date sentinel: HANDOFF.json ($HANDOFF_DATE) and CURRENT-SPRINT.md ($SPRINT_DATE) dates differ. Run /close to reconcile.")
fi

if [[ -n "${HANDOFF_DATE:-}" && -n "${CHANGELOG_DATE:-}" && "$HANDOFF_DATE" != "$CHANGELOG_DATE" ]]; then
  WARNINGS+=("Three-date sentinel: HANDOFF.json ($HANDOFF_DATE) and work-changelog.md ($CHANGELOG_DATE) dates differ. Run /close to reconcile.")
fi

# File budget: sprint under 120 lines
if [[ -f "$WORKSPACE/CURRENT-SPRINT.md" ]]; then
  SPRINT_LINES=$(wc -l < "$WORKSPACE/CURRENT-SPRINT.md" | tr -d ' ')
  if (( SPRINT_LINES > 120 )); then
    WARNINGS+=("CURRENT-SPRINT.md is $SPRINT_LINES lines (budget: 120). Archive completed items.")
  fi
fi

# File budget: handoff summary under 6 items
if [[ -f "$WORKSPACE/HANDOFF.json" ]]; then
  SUMMARY_COUNT=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get("last_session",{}).get("summary",[])))' "$WORKSPACE/HANDOFF.json" 2>/dev/null || echo 0)
  if (( SUMMARY_COUNT > 6 )); then
    WARNINGS+=("HANDOFF.json summary has $SUMMARY_COUNT items (budget: 6). Consolidate before next session.")
  fi
fi

# Lesson coverage audit: check if previous session's project work had lessons captured
if [[ -f "$WORKSPACE/HANDOFF.json" ]]; then
  TOUCHED_PROJECTS=$(python3 -c '
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
    ls = d.get("last_session", {})
    files = ls.get("files_modified", []) + ls.get("files_created", [])
    projects = set()
    for f in files:
        m = re.match(r"Projects/([^/]+)/", f)
        if m:
            projects.add(m.group(1))
    for p in sorted(projects):
        print(p)
except Exception:
    pass
' "$WORKSPACE/HANDOFF.json" 2>/dev/null || true)

  if [[ -n "$TOUCHED_PROJECTS" && -n "${HANDOFF_DATE:-}" ]]; then
    while IFS= read -r PROJECT_NAME; do
      SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
      LESSONS_FILE="tasks/lessons/${SLUG}.md"
      if [[ -f "$WORKSPACE/$LESSONS_FILE" ]]; then
        LESSON_COMMITS=$(cd "$WORKSPACE" && git log --since="$HANDOFF_DATE" --oneline -- "$LESSONS_FILE" 2>/dev/null | wc -l | tr -d ' ')
        if (( LESSON_COMMITS == 0 )); then
          WARNINGS+=("Lesson gap: Previous session touched Projects/$PROJECT_NAME/ but $LESSONS_FILE was not updated. Review for missed lessons before proceeding.")
        fi
      fi
    done <<< "$TOUCHED_PROJECTS"
  fi
fi

# Outcome verification (OWASP ASI09): verify previous session's claims against reality
if [[ -f "$WORKSPACE/HANDOFF.json" ]]; then
  MISSING_FILES=$(python3 -c '
import json, os, sys
try:
    handoff_path = sys.argv[1]
    workspace = sys.argv[2]
    d = json.load(open(handoff_path))
    created = d.get("last_session", {}).get("files_created", [])
    for f in created:
        full = os.path.join(workspace, f)
        if not os.path.exists(full):
            print(f)
except Exception:
    pass
' "$WORKSPACE/HANDOFF.json" "$WORKSPACE" 2>/dev/null || true)

  if [[ -n "$MISSING_FILES" ]]; then
    while IFS= read -r MISSING; do
      WARNINGS+=("Outcome mismatch (ASI09): HANDOFF.json claims '$MISSING' was created, but file does not exist. Previous session's self-report may be inaccurate.")
    done <<< "$MISSING_FILES"
  fi
fi

# Extract handoff label for context
HANDOFF_LABEL=""
if [[ -f "$WORKSPACE/HANDOFF.json" ]]; then
  HANDOFF_LABEL=$(grep -o '"label": *"[^"]*"' "$WORKSPACE/HANDOFF.json" | sed 's/"label": *"//;s/"//')
fi

# Build output
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  WARNING_TEXT=$(printf '\\n- %s' "${WARNINGS[@]}")
  echo "{\"additionalContext\": \"Session health check:\\n⚠️ WARNINGS:$WARNING_TEXT\\n\\nLast session: $HANDOFF_LABEL\\nReminder: Read tasks/lessons/_shared.md and route the session per CLAUDE.md.\"}"
else
  echo "{\"additionalContext\": \"Session health check: ✅ All clear.\\nLast session: $HANDOFF_LABEL\\nReminder: Read tasks/lessons/_shared.md and route the session per CLAUDE.md.\"}"
fi
