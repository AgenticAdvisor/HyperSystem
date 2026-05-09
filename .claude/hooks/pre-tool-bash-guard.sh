#!/usr/bin/env bash
# PreToolUse hook — scan Bash commands for dangerous patterns
# Mitigates: OWASP LLM06 (Excessive Agency), OWASP ASI02 (Tool Misuse)
# Warns on detection (does NOT block — user can approve via Claude Code permissions)

set -euo pipefail

# Claude Code passes hook payload as JSON on stdin
PAYLOAD=$(cat)
[[ -z "$PAYLOAD" ]] && exit 0

# Extract command from .tool_input.command
COMMAND=$(echo "$PAYLOAD" | grep -o '"command": *"[^"]*"' | head -1 | sed 's/"command": *"//;s/"$//' 2>/dev/null || true)
[[ -z "$COMMAND" ]] && exit 0

WARNINGS=()

# --- Category 1: Data Exfiltration ---
# Network tools that could send data to external servers
if echo "$COMMAND" | grep -qEi '(curl|wget|nc|ncat|netcat)\s.*(-d|--data|-F|--form|--upload|>)'; then
  WARNINGS+=("Potential data exfiltration: outbound data transfer detected")
fi
if echo "$COMMAND" | grep -qEi 'curl\s.*\|\s*(bash|sh|zsh|python)'; then
  WARNINGS+=("Remote code execution: piping downloaded content to shell")
fi
if echo "$COMMAND" | grep -qEi '(scp|rsync|ftp)\s'; then
  WARNINGS+=("File transfer tool detected: verify destination is authorized")
fi

# --- Category 2: Destructive Operations ---
if echo "$COMMAND" | grep -qEi 'rm\s+(-rf|--recursive|--force)'; then
  WARNINGS+=("Destructive: recursive/forced file deletion")
fi
if echo "$COMMAND" | grep -qEi 'mkfs|dd\s+.*of=|shred\s'; then
  WARNINGS+=("Destructive: disk/filesystem operation")
fi
if echo "$COMMAND" | grep -qEi 'git\s+(push\s+--force|reset\s+--hard|clean\s+-fd)'; then
  WARNINGS+=("Destructive git operation: may cause data loss")
fi
if echo "$COMMAND" | grep -qEi '>\s*/dev/(sd|nvme|disk)'; then
  WARNINGS+=("Destructive: writing directly to block device")
fi

# --- Category 3: Privilege Escalation ---
if echo "$COMMAND" | grep -qEi '(sudo|doas|su\s|pkexec)\s'; then
  WARNINGS+=("Privilege escalation: elevated permissions requested")
fi
if echo "$COMMAND" | grep -qEi 'chmod\s+[0-7]*[2367][0-7]*\s|chmod\s+.*\+s'; then
  WARNINGS+=("Permission change: world-writable or setuid detected")
fi
if echo "$COMMAND" | grep -qEi 'chown\s+root'; then
  WARNINGS+=("Ownership change to root")
fi

# --- Category 4: Sensitive File Access ---
if echo "$COMMAND" | grep -qEi '(cat|head|tail|less|more|vi|vim|nano)\s+.*(\.env|/etc/passwd|/etc/shadow|id_rsa|\.ssh/|credentials|\.aws/)'; then
  WARNINGS+=("Sensitive file access: secrets or credentials file")
fi
if echo "$COMMAND" | grep -qEi '(cat|base64|xxd)\s.*\|\s*(curl|wget|nc)'; then
  WARNINGS+=("Data exfiltration chain: reading file and sending via network")
fi

# --- Category 5: Reverse Shells / Backdoors ---
if echo "$COMMAND" | grep -qEi '(bash|sh|zsh)\s+-i\s+.*>/dev/tcp'; then
  WARNINGS+=("Reverse shell: interactive shell to remote host")
fi
if echo "$COMMAND" | grep -qEi '(nc|ncat|netcat)\s+.*-e\s+(bash|sh|/bin)'; then
  WARNINGS+=("Reverse shell via netcat")
fi
if echo "$COMMAND" | grep -qEi 'python.*socket.*connect'; then
  WARNINGS+=("Potential reverse shell via Python socket")
fi

# --- Category 6: Credential Harvesting ---
if echo "$COMMAND" | grep -qEi '(printenv|env|set)\s*\|'; then
  WARNINGS+=("Environment variable dump piped to another command")
fi
if echo "$COMMAND" | grep -qEi 'grep\s+.*(PASSWORD|SECRET|TOKEN|API_KEY|PRIVATE)'; then
  WARNINGS+=("Credential harvesting: searching for secrets in environment/files")
fi

# --- Report ---
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  WARNING_TEXT=""
  for w in "${WARNINGS[@]}"; do
    WARNING_TEXT="${WARNING_TEXT}\n  - ${w}"
  done
  echo "{\"additionalContext\": \"⚠️ TOOL SAFETY WARNING (OWASP LLM06/ASI02):${WARNING_TEXT}\nReview this command carefully before approving.\"}"
fi

exit 0
