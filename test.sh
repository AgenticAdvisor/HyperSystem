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
  "pre-bash-cwd-check.sh"
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
  "worktree"
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
  "tools/check-handoff-budget.py"
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
  for hook in session-start stop-guard pre-compact-close track-modified pre-tool-bash-guard pre-commit-secrets pre-bash-cwd-check; do
    if grep -q "$hook" "$SETTINGS"; then
      pass "$hook wired in settings.json"
    else
      fail "$hook NOT wired in settings.json"
    fi
  done
else
  fail "settings.json MISSING"
fi

# --- 9. Control Count Consistency ---
echo ""
echo "9. Control count consistency (113)"
for f in docs/SECURITY-MODEL.md tools/SECURITY-GATEWAY.md README.md; do
  if grep -q "113" "$REPO_ROOT/$f"; then
    pass "$f references 113"
  else
    fail "$f does NOT reference 113"
  fi
done

# --- 10. Regression tests (v0.2.1) ---
echo ""
echo "10. Regression tests (v0.2.1 patch)"

# 10.1: JSON helper extracts fields containing escaped quotes
HELPER="$REPO_ROOT/tools/_hook_payload.sh"
if [[ -f "$HELPER" ]]; then
  # shellcheck disable=SC1090
  source "$HELPER"
  EXTRACTED=$(printf '%s' '{"tool_input":{"command":"echo \"hi\""}}' | extract_field tool_input.command)
  if [[ "$EXTRACTED" == 'echo "hi"' ]]; then
    pass "JSON helper extracts field with embedded escaped quotes"
  else
    fail "JSON helper extraction wrong: got [$EXTRACTED], expected [echo \"hi\"]"
  fi
else
  fail "JSON helper tools/_hook_payload.sh MISSING"
fi

# 10.2: pre-commit-secrets catches single-quoted assignments
TEST_REPO=$(mktemp -d -t v021-secrets-XXXX)
git -C "$TEST_REPO" init -q -b main >/dev/null 2>&1
echo "PASSWORD = 'my_secret_value_here'" > "$TEST_REPO/leak.py"
git -C "$TEST_REPO" add leak.py
PAYLOAD='{"tool_input":{"command":"git commit -m test"}}'
HOOK_EXIT=0
HOOK_OUT=$(echo "$PAYLOAD" | WORKSPACE_OVERRIDE="$TEST_REPO" bash "$REPO_ROOT/.claude/hooks/pre-commit-secrets.sh" 2>&1) || HOOK_EXIT=$?
rm -rf "$TEST_REPO"
if [[ $HOOK_EXIT -eq 2 && "$HOOK_OUT" == *"Password"* ]]; then
  pass "pre-commit-secrets blocks single-quoted PASSWORD assignment"
else
  fail "pre-commit-secrets MISSED single-quoted PASSWORD (exit=$HOOK_EXIT)"
fi

# 10.3: session-start handles workspace paths with apostrophes
APOS_DIR=$(mktemp -d -t "v021-apos-XXXX")
APOS_WS="$APOS_DIR/has'apostrophe"
mkdir -p "$APOS_WS"
cat > "$APOS_WS/HANDOFF.json" <<'EOF'
{"date": "2026-05-09", "label": "test", "last_session": {"summary": ["one","two","three","four","five","six","seven"], "files_created": [], "files_modified": []}}
EOF
SESSION_EXIT=0
SESSION_OUT=$(WORKSPACE_OVERRIDE="$APOS_WS" bash "$REPO_ROOT/.claude/hooks/session-start.sh" 2>&1) || SESSION_EXIT=$?
rm -rf "$APOS_DIR"
if [[ $SESSION_EXIT -eq 0 && "$SESSION_OUT" == *"additionalContext"* && "$SESSION_OUT" != *"SyntaxError"* && "$SESSION_OUT" == *"summary has 7 items"* ]]; then
  pass "session-start handles workspace path with apostrophe"
else
  fail "session-start broke on apostrophe path (exit=$SESSION_EXIT, out=${SESSION_OUT:0:200})"
fi

# 10.4: audit-log rotation writes a marker entry
ROTATION_TEST=$(WORKSPACE_ROOT="$REPO_ROOT" python3 - <<'PYEOF'
import json, os, sys, tempfile
sys.path.insert(0, os.path.join(os.environ["WORKSPACE_ROOT"], "tools"))
import secure_writer as sw

with tempfile.TemporaryDirectory() as tmp:
    sw.SECURITY_LOG = type(sw.SECURITY_LOG)(os.path.join(tmp, "log.jsonl"))
    sw.MAX_LOG_ENTRIES = 100  # smaller for test speed
    # Write 201 fake entries so rotation drops ~100 oldest
    with open(sw.SECURITY_LOG, "w") as f:
        for i in range(201):
            f.write(json.dumps({"timestamp": f"t{i}", "prev_hash": "abc", "n": i}) + "\n")
    sw._rotate_log_if_needed()
    with open(sw.SECURITY_LOG) as f:
        lines = f.readlines()
    first = json.loads(lines[0])
    if first.get("type") == "rotation_marker" and first.get("dropped_count", 0) > 0:
        print("OK")
    else:
        print(f"FAIL first_line={first}")
PYEOF
)
if [[ "$ROTATION_TEST" == "OK" ]]; then
  pass "audit-log rotation writes rotation_marker entry"
else
  fail "audit-log rotation marker missing: $ROTATION_TEST"
fi

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
