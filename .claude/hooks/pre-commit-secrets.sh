#!/usr/bin/env bash
# Pre-commit hook — scan staged files for secrets before they hit git history
# Blocks commits that contain API keys, tokens, passwords, or private keys.
# Exit 2 = block commit (PreToolUse convention; exit 1 does NOT block), Exit 0 = allow.
#
# Invoked from PreToolUse(Bash). Reads the JSON payload on stdin and only
# proceeds when the command being run is a `git commit`. For any other Bash
# invocation, exits silently with 0. When stdin is empty (manual/test
# invocation), proceeds with the scan against currently-staged files.

set -euo pipefail

# Filter: only run on `git commit` invocations when called via PreToolUse
PAYLOAD=$(cat 2>/dev/null || true)
if [[ -n "$PAYLOAD" ]]; then
  COMMAND=$(echo "$PAYLOAD" | grep -o '"command": *"[^"]*"' | head -1 | sed 's/"command": *"//;s/"$//' 2>/dev/null || true)
  if [[ -n "$COMMAND" ]] && ! echo "$COMMAND" | grep -qE '(^|[[:space:]&;|()])git[[:space:]]+commit([[:space:]]|$)'; then
    exit 0
  fi
fi

# WORKSPACE_OVERRIDE allows the test suite to point at a synthetic repo.
# Default: derive from script location (parent of .claude/hooks/).
WORKSPACE="${WORKSPACE_OVERRIDE:-$(cd "$(dirname "$0")/../.." && pwd)}"
VIOLATIONS=()

# Only run if git is available and we're in a repo
if ! command -v git &>/dev/null || ! [ -d "$WORKSPACE/.git" ]; then
  exit 0
fi

# Get staged files (only added/modified, not deleted)
STAGED_FILES=$(cd "$WORKSPACE" && git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)

if [[ -z "$STAGED_FILES" ]]; then
  exit 0
fi

# --- Pattern definitions ---
# Each pattern: regex|description
# Quoting: use '...' for plain patterns; use $'...' when the pattern needs
# apostrophe in a character class or \x hex escapes (interpreted before grep).
PATTERNS=(
  # API keys
  'sk-ant-[a-zA-Z0-9_-]{20,}|Anthropic API key'
  'sk-[a-zA-Z0-9]{20,}|OpenAI API key'
  'AIza[0-9A-Za-z_-]{35}|Google API key'
  'AKIA[0-9A-Z]{16}|AWS Access Key ID'
  # GitHub tokens
  'ghp_[a-zA-Z0-9]{36}|GitHub personal access token'
  'gho_[a-zA-Z0-9]{36}|GitHub OAuth token'
  'ghs_[a-zA-Z0-9]{36}|GitHub server token'
  'github_pat_[a-zA-Z0-9_]{22,}|GitHub fine-grained PAT'
  # Private keys
  '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----|Private key'
  '-----BEGIN PGP PRIVATE KEY BLOCK-----|PGP private key'
  # Generic secrets (apostrophe character class via $'...' ANSI-C quoting)
  # \x27 = literal apostrophe; [^[:space:]] used inside char class (BSD grep
  # treats [^\s] as "not backslash-or-s", so any credential containing 's'
  # anywhere evades the pattern — silent false negative on macOS).
  $'PRIVATE_KEY\\s*=\\s*["\x27][^[:space:]]{10,}|Private key assignment'
  $'SECRET_KEY\\s*=\\s*["\x27][^[:space:]]{10,}|Secret key assignment'
  $'PASSWORD\\s*=\\s*["\x27][^[:space:]]{6,}|Password assignment'
  $'DB_PASSWORD\\s*=\\s*["\x27][^[:space:]]{6,}|Database password'
  $'API_KEY\\s*=\\s*["\x27][^[:space:]]{10,}|API key assignment'
  $'AUTH_TOKEN\\s*=\\s*["\x27][^[:space:]]{10,}|Auth token assignment'
  $'ACCESS_TOKEN\\s*=\\s*["\x27][^[:space:]]{10,}|Access token assignment'
  # Connection strings
  'mongodb(\+srv)?://[^[:space:]]+@|MongoDB connection string'
  'postgres(ql)?://[^[:space:]]+@|PostgreSQL connection string'
  'mysql://[^[:space:]]+@|MySQL connection string'
  'redis://:[^[:space:]]+@|Redis connection string'
  # Slack/Discord
  'xoxb-[0-9]{10,}-[a-zA-Z0-9]{20,}|Slack bot token'
  'xoxp-[0-9]{10,}-[a-zA-Z0-9]{20,}|Slack user token'
  # Stripe
  'sk_live_[a-zA-Z0-9]{20,}|Stripe live secret key'
  'rk_live_[a-zA-Z0-9]{20,}|Stripe live restricted key'
)

# --- .env file check ---
while IFS= read -r file; do
  if [[ "$file" =~ \.env($|\.) ]]; then
    VIOLATIONS+=("$file: .env file should not be committed (add to .gitignore)")
  fi
done <<< "$STAGED_FILES"

# --- Secret pattern scan ---
while IFS= read -r file; do
  # Skip binary files, .gitignore, and this hook itself
  [[ "$file" == *.png || "$file" == *.jpg || "$file" == *.jpeg || "$file" == *.svg ]] && continue
  [[ "$file" == *.docx || "$file" == *.xlsx || "$file" == *.pdf ]] && continue
  [[ "$file" == "$0" ]] && continue

  # Get staged content (not working tree — what will actually be committed)
  CONTENT=$(cd "$WORKSPACE" && git show ":$file" 2>/dev/null || true)
  [[ -z "$CONTENT" ]] && continue

  for pattern_desc in "${PATTERNS[@]}"; do
    PATTERN="${pattern_desc%%|*}"
    DESC="${pattern_desc##*|}"
    if echo "$CONTENT" | grep -qEi "$PATTERN" 2>/dev/null; then
      VIOLATIONS+=("$file: $DESC detected")
    fi
  done
done <<< "$STAGED_FILES"

# --- Report ---
if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
  echo ""
  echo "========================================================"
  echo "  SECRETS DETECTED — COMMIT BLOCKED"
  echo "========================================================"
  echo ""
  for v in "${VIOLATIONS[@]}"; do
    echo "  ✗ $v"
  done
  echo ""
  echo "Fix: remove secrets from staged files, use env vars instead."
  echo "Override: git commit --no-verify (NOT recommended)"
  echo "========================================================"
  echo ""
  exit 2
fi

exit 0
