# Security Model

> Security architecture, attack surface coverage, and API reference. For the security team.

---

## Trust Boundary Rule

If data crosses a trust boundary into the workspace, it must be sanitized before reaching the filesystem.

**What crosses the boundary (MUST sanitize):**
- Email content (bodies, subjects, sender fields)
- File uploads from external sources
- MCP tool content (any data returned from MCP servers)
- Third-party API responses (JSON, XML, plain text)
- User-pasted content from external sources (when writing to files)
- Web page fetches (URLs, scraped content, API responses)

**What does NOT cross (no sanitization needed):**
- Content authored by Claude or the user within the workspace
- Files already in the workspace (git-tracked)
- Internal computations on already-sanitized data
- Output from trusted local CLI tools (git, npm, pip)

The line is clear: if the data originated outside this workspace and is being written to a file, it crosses the boundary.

---

## Two-Layer Architecture

**Layer 1 -- Detection Engine** (`tools/content_security.py`):
6-phase pipeline covering 30+ attack vectors. Pattern matching, stripping, escaping. This is the core analysis engine. Pipelines never call it directly.

**Layer 2 -- Enforcement Gateway** (`tools/secure_writer.py`):
Sanitize, log, write. Single chokepoint for all external data entering the filesystem. All pipelines call the gateway, which delegates to the detection engine internally.

**Node.js path:**
`tools/sanitize.js` calls `tools/_sanitize_bridge.py`, which calls `content_security.py`. Same detection engine, different entry point. There is no separate JavaScript security implementation.

```
External Data
     |
     v
secure_writer.py (enforcement)
     |
     +-- sanitize --> content_security.py (detection, 6-phase)
     +-- log ------> .security-log.jsonl (audit)
     +-- write ----> workspace file
```

---

## Defense Inventory (132 Defenses, A-Z)

1. .env file commit prevention
2. .env / .env.* / .env.local / .env.production exclusion (.gitignore)
3. ACCESS_TOKEN assignment detection
4. API_KEY assignment detection
5. Anthropic API key detection (sk-ant-*)
6. AUTH_TOKEN assignment detection
7. Authority document spoofing detection (RAG)
8. Authority impersonation detection (prompt injection)
9. AWS Access Key ID detection (AKIA*)
10. Backtick shell execution detection
11. Base64-encoded attack payload detection (decode + re-scan)
12. Base64 payload sequence pattern matching
13. Bidirectional control character detection
14. Block device write prevention
15. Boolean blind SQLi detection
16. Credential harvesting detection (grep PASSWORD/SECRET/TOKEN)
17. Close-before-compact enforcement warning
18. Cloud metadata endpoint detection (AWS/GCP/Azure)
19. Comment-based SQL evasion detection
20. Constitutional jailbreak detection (DAN mode/bypass safety)
21. Content size hard reject (100MB)
22. Context window stuffing detection (repeated characters)
23. Cross-document reference injection detection (RAG)
24. Cross-session lesson coverage audit
25. Cross-session outcome verification (HANDOFF claims vs disk)
26. CSS @import with JavaScript/HTTP detection
27. CSS display:none / visibility:hidden stripping
28. CSS expression/behavior detection
29. Data exfiltration chain detection (cat file | curl)
30. Data exfiltration detection (curl/wget/nc with outbound data)
31. Data exfiltration instruction detection (prompt injection)
32. Data URI with HTML detection
33. DB_PASSWORD assignment detection
34. DDE injection detection (IMPORTXML/CMD)
35. Destructive git operation detection (force push/hard reset/clean)
36. Disk/filesystem operation detection (mkfs/dd/shred)
37. DROP/ALTER/TRUNCATE/DELETE/INSERT/UPDATE command detection
38. Environment variable dump piping detection
39. File modification tracking (audit trail)
40. File protocol detection (file://)
41. File transfer tool detection (scp/rsync/ftp)
42. Form action hijacking detection
43. Formula injection detection (leading =, +, @)
44. GitHub fine-grained PAT detection (github_pat_*)
45. GitHub OAuth token detection (gho_*)
46. GitHub personal access token detection (ghp_*)
47. GitHub server token detection (ghs_*)
48. Google API key detection (AIza*)
49. Gradual escalation marker detection (RAG)
50. HANDOFF summary budget enforcement (under 6 items)
51. Hex-encoded SQL detection
52. Hidden instruction marker detection
53. Homoglyph attack detection (>30% non-ASCII threshold)
54. HTML comment instruction detection (Phase 2)
55. HTML comment instruction pattern matching (Phase 4)
56. HTML entity escaping for rendering contexts
57. HTML entity obfuscation chain detection
58. Iframe injection detection
59. Immediate lesson capture standing order (Rule 4)
60. Incremental escalation detection (prompt injection)
61. Instruction override detection (prompt injection)
62. Internal IP address detection (127.0.0.1, 10.x, 172.x, 192.168.x)
63. JavaScript URI detection
64. JSON nesting bomb detection
65. JSON script field detection (onclick/src/href with javascript:)
66. JSON system/role/__proto__ field injection detection
67. Local settings exclusion (.claude/settings.local.json)
68. Log rotation (5,000 entry limit, keeps recent half)
69. Mandatory lesson declaration at /close (Option A or B)
70. MongoDB connection string detection
71. Multi-turn trust building detection (prompt injection)
72. MySQL connection string detection
73. NFC Unicode normalization
74. No-silent-fallback standing order (Rule 2)
75. Node.js dangerous pattern detection (child_process/process.exit)
76. Object/embed/applet tag detection
77. OpenAI API key detection (sk-*)
78. OWASP ASI03 project-scoped access advisory
79. Parent directory auto-creation
80. PASSWORD assignment detection
81. PGP private key detection
82. PostgreSQL connection string detection
83. Privilege escalation detection (Bash — sudo/doas/su/pkexec)
84. Privilege escalation instruction detection (prompt injection)
85. PRIVATE_KEY assignment detection
86. Python dangerous function detection (exec/eval/compile/__import__)
87. Python deserialization detection (pickle/marshal/yaml.unsafe_load)
88. Python os/subprocess call detection
89. Python socket reverse shell detection
90. Recursive/forced file deletion detection (rm -rf)
91. Redis connection string detection
92. Remote code execution detection (pipe download to shell)
93. Residual HTML tag stripping
94. Reverse shell detection (bash -i > /dev/tcp)
95. Reverse shell via netcat detection
96. Role manipulation detection (prompt injection)
97. Rolling SHA-256 hash chain (tamper-evident audit log)
98. Root ownership change detection
99. RSA/EC/DSA/OpenSSH private key detection
100. Sanitize-all-external-content standing order (Rule 1)
101. Script tag detection (XSS)
102. SECRET_KEY assignment detection
103. Security log exclusion from git tracking
104. Sensitive file access detection (.env/passwd/.ssh/credentials/.aws)
105. Session close enforcement warning (Stop hook)
106. Session close mandatory standing order (Rule 3)
107. Shell command injection detection
108. Shell pipe execution detection
109. Slack bot token detection (xoxb-*)
110. Slack user token detection (xoxp-*)
111. SPRINT file budget enforcement (under 120 lines)
112. Stacked SQL query detection (;DROP/;EXEC/xp_cmdshell)
113. Stripe live restricted key detection (rk_live_*)
114. Stripe live secret key detection (sk_live_*)
115. SVG with script event detection
116. System path blocking (/etc, /usr, /bin, /sbin, /proc, /sys, /dev)
117. System prompt override detection (prompt injection)
118. Three-date sentinel (HANDOFF vs SPRINT vs changelog)
119. Three-layer lesson enforcement standing order (Rule 12)
120. Time-delay blind SQLi detection (WAITFOR/SLEEP/BENCHMARK)
121. Time-delayed activation trigger detection (RAG)
122. Token exhaustion truncation (50K char limit)
123. Token stuffing / embedding space poisoning detection (RAG)
124. UNION SELECT injection detection
125. Unicode escape sequence detection
126. URL encoding chain detection
127. White-on-white / invisible CSS text detection
128. World-writable/setuid permission change detection
129. Workspace boundary enforcement (writes must resolve inside workspace)
130. XSS event handler detection (onerror/onload/onclick)
131. Zero-width character sequence pattern matching
132. Zero-width character stripping

---

## Failure Mode: STOP

If `secure_writer.py` or `content_security.py` cannot load (missing file, import error) or sanitization fails at runtime:

1. The pipeline stops immediately.
2. No content is written to the filesystem.
3. The error is surfaced to the user with full context.
4. There is no silent fallback. No degraded mode. No bypass.

This is enforced as a standing order in `tasks/lessons/_shared.md`. It is not optional and cannot be overridden by convenience.

---

## Audit Trail

All sanitization events are automatically appended to `tools/.security-log.jsonl`. Each entry includes:

- Timestamp
- Rolling hash (`prev_hash`) — SHA-256 of the previous log entry for tamper detection
- Context string (what the content is, where it came from)
- Detection results (which phases flagged, which vectors matched)
- Outcome (pass / sanitized / blocked)

The log is append-only, machine-readable, and tamper-evident. Each entry's `prev_hash` field contains the first 16 characters of the SHA-256 hash of the previous entry's raw JSON line. The first entry uses `"genesis"` as its prev_hash. If any entry is deleted or modified, the hash chain breaks — detectable by sequential validation.

Do not delete or truncate the log. No manual logging is required.

---

## Pipeline Compliance

Every pipeline ingesting external data must have an entry in the Pipeline Compliance Tracker (`tools/SECURITY-GATEWAY.md`). A missing entry is a critical security finding and an immediate P0 priority.

The tracker records which pipelines exist, which gateway they use, and any relevant notes. This provides a single audit point for verifying that all external data paths are covered.

---

## API Reference

### Python -- `tools/secure_writer.py`

| Function | Signature | Returns |
|----------|-----------|---------|
| `write_text` | `write_text(content, filepath, context="")` | `bool` |
| `write_json` | `write_json(data, filepath, context="")` | `bool` |
| `write_lines` | `write_lines(lines, filepath, context="")` | `bool` |
| `sanitize_only` | `sanitize_only(content, context="")` | `str` |

### Node.js -- `tools/sanitize.js`

| Function | Signature | Returns |
|----------|-----------|---------|
| `sanitizeText` | `sanitizeText(content, context?)` | `Promise<string>` |
| `sanitizeDict` | `sanitizeDict(obj, context?)` | `Promise<object>` |
| `sanitizeItems` | `sanitizeItems(items, context?)` | `Promise<array>` |

The `context` parameter is a short string describing the content source (e.g., `"api-response"`, `"scraped-webpage"`). It is written to the security log for audit purposes.

Node.js functions delegate to Python via `_sanitize_bridge.py`. The detection engine is shared -- there is no separate JavaScript implementation.

---

## Standards Alignment

This security model is designed against the following published frameworks:

| Framework | Coverage | Notes |
|-----------|----------|-------|
| [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/) | LLM01 (Prompt Injection), LLM02 (Sensitive Info Disclosure), LLM06 (Excessive Agency), LLM10 (Unbounded Consumption) | Core focus areas. LLM06 mitigated via Bash command guard and project scope. |
| [OWASP Top 10 for Agentic Applications (2025/2026)](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) | ASI01 (Goal Hijack), ASI02 (Tool Misuse), ASI03 (Identity/Privilege), ASI06 (Data Poisoning), ASI08 (Cascading Failures), ASI09 (Trust Exploitation) | Six of ten risks addressed. ASI04/05/07/10 noted in Known Limitations. |
| [NIST AI Risk Management Framework](https://csrc.nist.gov/pubs/ir/8596/iprd) | Cybersecurity Framework Profile for AI (Draft, Dec 2025) | Audit logging with tamper detection, fail-closed design, non-bypassable Layer 0 hooks align with NIST's "non-bypassable controls" concept. |
| [NIST SP 800-53 COSAiS](https://cloudsecurityalliance.org/blog/2025/09/03/a-look-at-the-new-ai-control-frameworks-from-nist-and-csa) | Control overlays for single-agent AI (in development) | Workspace boundary enforcement and tool-call validation align with anticipated control requirements. |
| [Microsoft Indirect Prompt Injection Research](https://www.microsoft.com/en-us/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks) | Defense-in-depth model | Pattern-based detection as first layer; model-level defenses (e.g., TaskTracker) are outside scaffold scope — see Known Limitations. |

---

## Security Hooks (Deterministic Enforcement)

Layer 0 hooks provide non-bypassable security enforcement at key lifecycle events:

| Hook | Event | Mitigates | Action |
|------|-------|-----------|--------|
| `pre-tool-bash-guard.sh` | PreToolUse (Bash) | LLM06, ASI02 | Warns on data exfiltration, destructive ops, privilege escalation, reverse shells, credential harvesting |
| `pre-commit-secrets.sh` | PreToolUse (git commit) | LLM02 | Blocks commits containing API keys, tokens, private keys, connection strings (30+ patterns) |
| `session-start.sh` | SessionStart | ASI09 | Verifies previous session's self-reported claims against actual file state (outcome mismatch detection) |

---

## Known Limitations

### 1. Indirect Prompt Injection (LLM01 — Advanced)

Pattern-based detection catches known injection vectors but cannot detect **semantic** prompt injections — attacks that are meaning-equivalent to "ignore previous instructions" without using any trigger words. Microsoft's [TaskTracker](https://www.microsoft.com/en-us/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks) approach (analyzing LLM internal activations) addresses this at the model level, which is outside the scope of a workspace scaffold.

**Mitigation posture:** Defense-in-depth. Pattern scanning is a first-pass filter. The trust boundary rule (sanitize all external content) limits the attack surface. Session discipline and human review provide additional layers. But a sophisticated attacker crafting novel indirect injections could bypass pattern detection.

**References:** [Greshake et al. (2023)](https://arxiv.org/abs/2510.05244), [OWASP LLM01:2025](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)

### 2. Identity & Privilege Scope (ASI03 — Partial)

Project-scoped access is enforced via **advisory directives** in context-loading skills, not deterministic file-system permissions. Claude is instructed not to access other projects' files or credentials, but this instruction can be overridden by the user or bypassed by prompt injection.

**Why not deterministic:** Claude Code's permission model is controlled by the host environment, not by workspace scaffolding. The System cannot enforce file-system ACLs. Advisory enforcement is the strongest mechanism available at this layer.

**Mitigation posture:** The Bash command guard catches obvious cross-boundary access (sensitive file reads, credential harvesting). Context-loading skills set the scope. Human approval via Claude Code's permission system provides the final gate.

### 3. Human-Agent Trust Exploitation (ASI09 — Partial)

The session-start hook verifies that files claimed as created in `HANDOFF.json` actually exist on disk (outcome verification). However, it cannot detect:
- Correct-sounding but subtly wrong code that passes tests
- Plausible justifications for skipping security steps
- Self-reported "no corrections" declarations that are inaccurate

**Why not fully solvable:** This is fundamentally the alignment problem applied to session governance. Detecting when an AI agent is confidently wrong requires a second evaluator or human review — not more hooks.

**Mitigation posture:** Three-layer lesson enforcement reduces drift. Cross-session outcome verification catches some mismatches. The mandatory `/close` declaration creates an auditable record. But human oversight remains the ultimate defense.

### 4. Supply Chain & Agentic Dependencies (ASI04)

The System does not scan dependencies (`npm audit`, `pip-audit`), verify package integrity, or detect supply chain attacks in imported libraries. This is standard SDLC tooling, not a workspace governance concern.

**Recommendation:** Use dedicated supply chain security tools (Dependabot, Snyk, Socket) in your CI/CD pipeline alongside The System.

### 5. Inter-Agent Communication (ASI07)

Not applicable to single-agent deployments. If The System is extended to multi-agent workflows (multiple Claude instances coordinating), there is currently no authentication, message integrity, or trust verification between agents.

**When this matters:** Multi-agent architectures where Agent A's output becomes Agent B's input without validation. Spoofed inter-agent messages could redirect entire workflows.

**Recommendation:** If extending to multi-agent, add message signing and per-agent identity before deployment. [NIST's NCCoE](https://federalnewsnetwork.com/cybersecurity/2026/02/nist-agentic-ai-initiative-looks-to-get-handle-on-security/) is developing identity and authorization frameworks for AI agents (expected 2026-2027).

### 6. Rogue Agent Behavior (ASI10)

The System detects misalignment through outcome verification and lesson enforcement, but cannot prevent an agent from exhibiting concealment, self-directed goal changes, or deceptive compliance. These risks are documented in the [OWASP Agentic Top 10](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) and are an active area of AI safety research.

**Mitigation posture:** Session discipline, audit trails, and cross-session verification provide observability. But detection ≠ prevention. Human oversight is required for high-stakes decisions.
