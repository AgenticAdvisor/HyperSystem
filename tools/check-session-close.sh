#!/bin/bash
# check-session-close.sh — Post-session close validator
# Verifies all session close checklist steps were completed.
# Run manually or as a scheduled task after each session.
#
# Exit codes:
#   0 = all checks pass
#   1 = one or more checks failed
#
# Usage: bash tools/check-session-close.sh [YYYY-MM-DD]
#   If no date given, uses today's date.

set -euo pipefail

# --- Config ---
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG="$REPO_ROOT/executive-summary/work-changelog.md"
HANDOFF="$REPO_ROOT/HANDOFF.json"
SPRINT="$REPO_ROOT/CURRENT-SPRINT.md"

CHECK_DATE="${1:-$(date +%Y-%m-%d)}"
FAILURES=0
CHECKS=0

# --- Helpers ---
pass() { CHECKS=$((CHECKS + 1)); echo "  ✓ $1"; }
fail() { CHECKS=$((CHECKS + 1)); FAILURES=$((FAILURES + 1)); echo "  ✗ $1"; }

echo "Session Close Validator — checking $CHECK_DATE"
echo "================================================"

# --- Check 1: Changelog has entry for this date ---
echo ""
echo "Step 1: Work changelog"
if [ -f "$CHANGELOG" ]; then
    if grep -q "$CHECK_DATE" "$CHANGELOG" 2>/dev/null; then
        pass "Changelog has entry for $CHECK_DATE"
    else
        fail "No changelog entry found for $CHECK_DATE"
    fi
else
    fail "work-changelog.md not found"
fi

# --- Check 2: Per-project changelog (advisory) ---
echo ""
echo "Step 2: Per-project changelog"
echo "  ℹ  Advisory only — verify manually that Projects/[Name]/CHANGELOG.md was updated for meaningful project work"

# --- Check 3a: HANDOFF.json date matches ---
echo ""
echo "Step 3a: HANDOFF.json date"
HANDOFF_DATE=""
if [ -f "$HANDOFF" ]; then
    HANDOFF_DATE=$(python3 -c "import json; print(json.load(open('$HANDOFF'))['last_session']['date'])" 2>/dev/null || echo "PARSE_ERROR")
    if [ "$HANDOFF_DATE" = "$CHECK_DATE" ]; then
        pass "HANDOFF.json last_session.date = $CHECK_DATE"
    else
        fail "HANDOFF.json last_session.date = $HANDOFF_DATE (expected $CHECK_DATE)"
    fi
else
    fail "HANDOFF.json not found"
fi

# --- Check 3b: CURRENT-SPRINT.md last updated matches ---
echo ""
echo "Step 3b: CURRENT-SPRINT.md freshness"
SPRINT_DATE=""
if [ -f "$SPRINT" ]; then
    SPRINT_DATE=$(grep -o "Last updated: [0-9-]*" "$SPRINT" | head -1 | sed 's/Last updated: //')
    if [ -z "$SPRINT_DATE" ]; then
        fail "Could not parse 'Last updated' from CURRENT-SPRINT.md"
    elif [ "$SPRINT_DATE" = "$CHECK_DATE" ]; then
        pass "CURRENT-SPRINT.md Last updated = $CHECK_DATE"
    else
        fail "CURRENT-SPRINT.md Last updated = $SPRINT_DATE (expected $CHECK_DATE)"
    fi
else
    fail "CURRENT-SPRINT.md not found"
fi

# --- Check 3c: Rule 7 — HANDOFF.json and CURRENT-SPRINT.md dates agree ---
echo ""
echo "Step 3c: Rule 7 sync (HANDOFF ↔ SPRINT)"
if [ -n "$HANDOFF_DATE" ] && [ "$HANDOFF_DATE" != "PARSE_ERROR" ] && [ -n "$SPRINT_DATE" ]; then
    if [ "$HANDOFF_DATE" = "$SPRINT_DATE" ]; then
        pass "HANDOFF.json and CURRENT-SPRINT.md dates match ($HANDOFF_DATE)"
    else
        fail "Date mismatch: HANDOFF=$HANDOFF_DATE vs SPRINT=$SPRINT_DATE (Rule 7 violation)"
    fi
else
    fail "Cannot compare — one or both dates missing"
fi

# --- Check 4: Git-based recovery ---
echo ""
echo "Step 4: Git-based recovery"
if command -v git &>/dev/null && [ -d "$REPO_ROOT/.git" ]; then
    COMMIT_COUNT=$(cd "$REPO_ROOT" && git rev-list --count HEAD 2>/dev/null || echo "0")
    if [ "$COMMIT_COUNT" -gt 0 ]; then
        pass "Git history available ($COMMIT_COUNT commits — recovery via git checkout)"
    else
        fail "No git commits — recovery not possible"
    fi
else
    fail "Git not initialized — recovery not available"
fi

# --- Check 5: Lesson coverage ---
echo ""
echo "Step 5: Lesson coverage"
if command -v git &>/dev/null && [ -d "$REPO_ROOT/.git" ]; then
    PROJECT_COMMITS=$(cd "$REPO_ROOT" && git log --since="$CHECK_DATE" --name-only --pretty=format: -- "Projects/" 2>/dev/null | grep -c "." || true)
    PROJECT_COMMITS=${PROJECT_COMMITS:-0}
    LESSON_COMMITS=$(cd "$REPO_ROOT" && git log --since="$CHECK_DATE" --name-only --pretty=format: -- "tasks/lessons/" 2>/dev/null | grep -c "." || true)
    LESSON_COMMITS=${LESSON_COMMITS:-0}
    if [ "$PROJECT_COMMITS" -gt 0 ] && [ "$LESSON_COMMITS" -eq 0 ]; then
        fail "Project files changed ($PROJECT_COMMITS files) but no lessons were updated"
    elif [ "$PROJECT_COMMITS" -gt 0 ]; then
        pass "Lesson coverage OK (project files: $PROJECT_COMMITS, lesson files: $LESSON_COMMITS)"
    else
        pass "No project files changed — lesson check not applicable"
    fi
else
    echo "  ℹ  Git not available — cannot check lesson coverage"
fi

# --- Check 6: Project context (advisory) ---
echo ""
echo "Step 6: Project context updates"
echo "  ℹ  Advisory only — verify manually that PROJECT-CONTEXT.md was updated if project state changed"

# --- Check 7: Git commit recency (optional — only if git is available) ---
echo ""
echo "Bonus: Git commit (optional)"
if command -v git &>/dev/null && [ -d "$REPO_ROOT/.git" ]; then
    LAST_COMMIT_DATE=$(cd "$REPO_ROOT" && git log -1 --format="%ad" --date=short 2>/dev/null || echo "NO_COMMITS")
    if [ "$LAST_COMMIT_DATE" = "$CHECK_DATE" ]; then
        pass "Git has commit from $CHECK_DATE"
    else
        fail "Last git commit is from $LAST_COMMIT_DATE (expected $CHECK_DATE)"
    fi
else
    echo "  ℹ  Git not initialized — skip (this is fine for non-git workspaces)"
fi

# --- Summary ---
echo ""
echo "================================================"
PASSED=$((CHECKS - FAILURES))
if [ "$FAILURES" -eq 0 ]; then
    echo "RESULT: ALL $CHECKS CHECKS PASSED ✓"
else
    echo "RESULT: $PASSED/$CHECKS passed, $FAILURES FAILED ✗"
    echo ""
    echo "Action: Fix the failed items before ending the session."
fi

exit "$FAILURES"
