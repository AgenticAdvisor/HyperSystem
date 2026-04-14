#!/usr/bin/env bash
# test.sh — Run all verification checks for The System
# Usage: bash test.sh
# Exit codes: 0 = all pass, 1 = failures

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PASSED=0
FAILED=0
TOTAL=0

pass() { TOTAL=$((TOTAL + 1)); PASSED=$((PASSED + 1)); echo "  ✓ $1"; }
fail() { TOTAL=$((TOTAL + 1)); FAILED=$((FAILED + 1)); echo "  ✗ $1"; }

echo "============================================================"
echo "  The System — Test Suite"
echo "============================================================"

# --- 1. Content Security Tests ---
echo ""
echo "1. Content Security (content_security.py)"
RESULT=$(cd "$REPO_ROOT" && python3 tools/content_security.py 2>&1)
BLOCKED=$(echo "$RESULT" | grep -o '[0-9]*/[0-9]* blocked' | head -1)
if echo "$RESULT" | grep -q "ALL VECTORS BLOCKED"; then
  pass "Content security: $BLOCKED"
else
  fail "Content security: $BLOCKED"
  echo "$RESULT" | grep "MISSED" | head -5
fi

# --- 2. Secure Writer Gateway Tests ---
echo ""
echo "2. Secure Writer Gateway (secure_writer.py)"
RESULT=$(cd "$REPO_ROOT" && python3 tools/secure_writer.py 2>&1)
SW_PASSED=$(echo "$RESULT" | grep -o '[0-9]*/[0-9]* passed' | head -1)
if echo "$RESULT" | grep -q "ALL GATEWAY TESTS PASSED"; then
  pass "Gateway tests: $SW_PASSED"
else
  fail "Gateway tests: $SW_PASSED"
  echo "$RESULT" | grep "FAIL" | head -5
fi

# --- 3. Hook Existence & Permissions ---
echo ""
echo "3. Hooks (existence + executable)"
EXPECTED_HOOKS=(
  "pre-commit-secrets.sh"
  "pre-compact-close.sh"
  "pre-tool-bash-guard.sh"
  "session-start.sh"
  "stop-guard.sh"
  "track-modified.sh"
)
for hook in "${EXPECTED_HOOKS[@]}"; do
  HOOK_PATH="$REPO_ROOT/.claude/hooks/$hook"
  if [[ -f "$HOOK_PATH" && -x "$HOOK_PATH" ]]; then
    pass "$hook exists and is executable"
  elif [[ -f "$HOOK_PATH" ]]; then
    fail "$hook exists but is NOT executable"
  else
    fail "$hook is MISSING"
  fi
done

# --- 4. Skill Existence ---
echo ""
echo "4. Skills (existence)"
EXPECTED_SKILLS=(
  "archive-project"
  "close"
  "health-check"
  "new-project"
  "reload"
)
for skill in "${EXPECTED_SKILLS[@]}"; do
  SKILL_PATH="$REPO_ROOT/.claude/skills/$skill/SKILL.md"
  if [[ -f "$SKILL_PATH" ]]; then
    pass "/$(echo $skill) skill exists"
  else
    fail "/$(echo $skill) skill MISSING"
  fi
done

# --- 5. Governance File Existence ---
echo ""
echo "5. Governance files (existence)"
EXPECTED_FILES=(
  "ARCHITECTURE.md"
  "BOOTSTRAP.md"
  "CLAUDE.md"
  "FOLDER-STRUCTURE.md"
  "LICENSE"
  "README.md"
  "TEMPLATES.md"
)
for f in "${EXPECTED_FILES[@]}"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    pass "$f"
  else
    fail "$f MISSING"
  fi
done

# --- 6. Security Tools Existence ---
echo ""
echo "6. Security tools (existence)"
EXPECTED_TOOLS=(
  "tools/_sanitize_bridge.py"
  "tools/check-session-close.sh"
  "tools/content_security.py"
  "tools/sanitize.js"
  "tools/secure_writer.py"
  "tools/SECURITY-GATEWAY.md"
)
for f in "${EXPECTED_TOOLS[@]}"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    pass "$f"
  else
    fail "$f MISSING"
  fi
done

# --- 7. Documentation Existence ---
echo ""
echo "7. Documentation (existence)"
EXPECTED_DOCS=(
  "docs/CUSTOMIZATION.md"
  "docs/DESIGN-PHILOSOPHY.md"
  "docs/RECOMMENDED-USER-CONFIG.md"
  "docs/SECURITY-MODEL.md"
)
for f in "${EXPECTED_DOCS[@]}"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    pass "$f"
  else
    fail "$f MISSING"
  fi
done

# --- 8. Settings.json Hook Wiring ---
echo ""
echo "8. Hook wiring (settings.json)"
SETTINGS="$REPO_ROOT/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  for hook in session-start stop-guard pre-compact-close track-modified pre-tool-bash-guard pre-commit-secrets; do
    if grep -q "$hook" "$SETTINGS"; then
      pass "$hook wired in settings.json"
    else
      fail "$hook NOT wired in settings.json"
    fi
  done
else
  fail "settings.json MISSING"
fi

# --- 9. Defense Count Consistency ---
echo ""
echo "9. Defense count consistency (132)"
for f in docs/SECURITY-MODEL.md tools/SECURITY-GATEWAY.md; do
  if grep -q "132" "$REPO_ROOT/$f"; then
    pass "$f references 132"
  else
    fail "$f does NOT reference 132"
  fi
done

# --- Summary ---
echo ""
echo "============================================================"
if [[ $FAILED -eq 0 ]]; then
  echo "  ALL $TOTAL CHECKS PASSED"
else
  echo "  $PASSED/$TOTAL passed, $FAILED FAILED"
fi
echo "============================================================"

exit "$FAILED"
