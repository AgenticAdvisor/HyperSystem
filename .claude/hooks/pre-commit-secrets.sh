#!/usr/bin/env bash
# Pre-commit hook — scan staged files for secrets before they hit git history
# Blocks commits that contain API keys, tokens, passwords, or private keys.
# Exit 1 = block commit, Exit 0 = allow.

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
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
  # Generic secrets
  'PRIVATE_KEY\s*=\s*["\x27][^\s]{10,}|Private key assignment'
  'SECRET_KEY\s*=\s*["\x27][^\s]{10,}|Secret key assignment'
  'PASSWORD\s*=\s*["\x27][^\s]{6,}|Password assignment'
  'DB_PASSWORD\s*=\s*["\x27][^\s]{6,}|Database password'
  'API_KEY\s*=\s*["\x27][^\s]{10,}|API key assignment'
  'AUTH_TOKEN\s*=\s*["\x27][^\s]{10,}|Auth token assignment'
  'ACCESS_TOKEN\s*=\s*["\x27][^\s]{10,}|Access token assignment'
  # Connection strings
  'mongodb(\+srv)?://[^\s]+@|MongoDB connection string'
  'postgres(ql)?://[^\s]+@|PostgreSQL connection string'
  'mysql://[^\s]+@|MySQL connection string'
  'redis://:[^\s]+@|Redis connection string'
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
  exit 1
fi

exit 0
