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

## Security Controls (113 controls in 7 categories)

> **Counting convention.** A "control" is one distinct enforcement point — a regex pattern, a path check, a budget guard, etc. Patterns that share an enforcement code path but match different tokens (e.g., the seven generic credential-assignment patterns in `D.6`) are counted by the number of distinct tokens they catch. Defense-in-depth means a single attack input may trip multiple controls; the count below is of controls, not events.
>
> Governance enforcement (session close, lesson capture, three-date sentinel) is documented separately at the end. It runs in the same hook layer but is not a security control.

### A. Content sanitization patterns (54)

`tools/content_security.py` — pattern-based detection over a 6-phase pipeline. All controls in this category are pattern-match-and-strip; bypasses for sufficiently novel inputs are an acknowledged limit (see Known Limitations §1).

- **A.1 SQL injection (7).** DROP/ALTER/TRUNCATE/DELETE/INSERT/UPDATE; UNION SELECT; time-delay blind (WAITFOR/SLEEP/BENCHMARK/pg_sleep); boolean blind; stacked queries (`;DROP`/`;EXEC`/`xp_cmdshell`); comment-based evasion; hex-encoded SQL.
- **A.2 Code execution (7).** Python `exec`/`eval`/`compile`/`__import__`/`getattr`/`setattr`/`delattr`; `os.system`/`os.popen`/`subprocess.*`; deserialization (`pickle.loads`/`marshal.loads`/`yaml.unsafe_load`); shell command injection; shell pipe to interpreter; backtick execution; Node `child_process`/`process.exit`/`process.env`.
- **A.3 XSS / browser injection (10).** Script tag; event handler; `javascript:` URI; `data:text/html`; SVG with event; CSS `expression`/`behavior`; CSS `@import`; iframe; object/embed/applet; form action hijack.
- **A.4 Prompt injection (10).** System override; instruction override; role manipulation; authority impersonation; constitutional jailbreak (DAN/bypass safety); data-exfiltration instruction; privilege-escalation instruction; hidden instruction marker; multi-turn trust building; incremental escalation.
- **A.5 Hidden content (3).** HTML comments containing instruction keywords; invisible CSS (`display:none`/`visibility:hidden`/`opacity:0`/`font-size:0`/`color:white`); base64-encoded payload (decoded + rescanned against the other categories).
- **A.6 JSON / structured-data injection (2).** `system`/`role`/`__proto__`/`constructor`/`prototype` field injection; JSON script-field with `javascript:`/`data:`.
- **A.7 Encoding evasion (3).** HTML entity obfuscation chains; Unicode escape sequences; URL-encoding chains.
- **A.8 SSRF (3).** Internal IP ranges (`127.0.0.1`/`10.x`/`172.16-31.x`/`192.168.x`/`localhost`/`0.0.0.0`); cloud metadata endpoints (`169.254.169.254`/`metadata.google.internal`/`metadata.azure.com`); `file://` protocol.
- **A.9 CSV / spreadsheet injection (2).** Formula injection (leading `=`/`+`/`@`); DDE injection (`IMPORTXML`/`IMPORTFEED`/`HYPERLINK`/`CMD`).
- **A.10 RAG poisoning (5).** Authority-document spoofing; cross-document reference injection; time-delayed activation triggers; gradual-escalation markers (phase-N/step-N); embedding-space poisoning (token stuffing).
- **A.11 Output rendering safety (2).** Residual HTML tag stripping after pattern phase; HTML entity escaping for rendering contexts (diary/HTML).

### B. Resource-exhaustion limits (4)

`tools/content_security.py` — fail-closed reject or truncate before further scanning.

- **B.1** Input size hard reject (100 MB).
- **B.2** Token-exhaustion truncation (50,000-char limit).
- **B.3** Repeated-character stuffing (collapse runs > 500 chars).
- **B.4** JSON nesting bomb (depth > 10).

### C. Unicode / invisible-character normalization (4)

`tools/content_security.py` — applied before pattern matching.

- **C.1** NFC Unicode normalization.
- **C.2** Homoglyph attack detection (>30% non-ASCII alpha threshold). **Caveat:** triggers NFKD ASCII-fold, which lossily transliterates non-Latin scripts. Not appropriate for multilingual ingestion without configuration.
- **C.3** Zero-width character stripping (`U+200B`–`U+200F`, `U+2060`–`U+2064`, `U+FEFF`).
- **C.4** Bidirectional / format control stripping (`U+2028`–`U+2029`, `U+202A`–`U+202E`, `U+2066`–`U+2069`).

### D. Secret-scan patterns (26)

`.claude/hooks/pre-commit-secrets.sh` — runs as a PreToolUse(Bash) gate on `git commit` and blocks the commit on detection.

- **D.1 Cloud provider API keys (4).** Anthropic (`sk-ant-*`); OpenAI (`sk-*`); Google (`AIza*`); AWS Access Key ID (`AKIA*`).
- **D.2 GitHub tokens (4).** Personal access (`ghp_*`); OAuth (`gho_*`); server (`ghs_*`); fine-grained (`github_pat_*`).
- **D.3 Slack tokens (2).** Bot (`xoxb-*`); user (`xoxp-*`).
- **D.4 Stripe keys (2).** Live secret (`sk_live_*`); live restricted (`rk_live_*`).
- **D.5 Private key blocks (2).** RSA / EC / DSA / OpenSSH PEM headers; PGP private key block.
- **D.6 Generic credential assignments (7).** `PRIVATE_KEY`, `SECRET_KEY`, `PASSWORD`, `DB_PASSWORD`, `API_KEY`, `AUTH_TOKEN`, `ACCESS_TOKEN` — quoted-value patterns covering both single- and double-quoted assignments.
- **D.7 Database connection strings (4).** `mongodb(+srv)?://`, `postgres(ql)?://`, `mysql://`, `redis://` with embedded credentials.
- **D.8 .env file commit prevention (1).** Any staged path matching `.env` or `.env.*` blocks commit.

### E. Bash command guard (17)

`.claude/hooks/pre-tool-bash-guard.sh` — runs as PreToolUse(Bash). Warns on detection (does not block; user approves via Claude Code's permission prompt). Mitigates OWASP LLM06 / ASI02.

- **E.1 Data exfiltration (3).** Outbound transfer (`curl`/`wget`/`nc`/`ncat` with `-d`/`--data`/`-F`/`--form`/`--upload`/`>`); pipe-to-interpreter (`curl ... | bash`/`sh`/`zsh`/`python`); file-transfer tools (`scp`/`rsync`/`ftp`).
- **E.2 Destructive operations (4).** `rm -rf`/`--recursive`/`--force`; `mkfs`/`dd of=`/`shred`; `git push --force`/`reset --hard`/`clean -fd`; direct block-device writes (`> /dev/sd*`/`/dev/nvme*`/`/dev/disk*`).
- **E.3 Privilege escalation (3).** `sudo`/`doas`/`su`/`pkexec`; world-writable or setuid `chmod`; `chown root`.
- **E.4 Sensitive file access (2).** Read of `.env`/`/etc/passwd`/`/etc/shadow`/`id_rsa`/`.ssh/`/`credentials`/`.aws/`; exfiltration chain (`cat`/`base64`/`xxd` piped to `curl`/`wget`/`nc`).
- **E.5 Reverse shells (3).** `bash -i ... >/dev/tcp`; `nc -e`/`ncat -e` to a shell; `python ... socket ... connect`.
- **E.6 Credential harvesting (2).** Environment-variable dump piped to another command (`printenv`/`env`/`set` followed by pipe); `grep` searches for `PASSWORD`/`SECRET`/`TOKEN`/`API_KEY`/`PRIVATE`.

### F. Path & workspace boundary (4)

`tools/secure_writer.py` — fail-closed `ValueError` on violation.

- **F.1** Workspace boundary enforcement (resolved destination must be under `WORKSPACE_ROOT`; `../` escapes blocked).
- **F.2** System-path blocking (`/etc`/`/usr`/`/bin`/`/sbin`/`/var/run`/`/run`/`/proc`/`/sys`/`/dev`).
- **F.3** Symlink resolution before validation (`Path.resolve()` — symlink targets cannot smuggle paths past the boundary check).
- **F.4** Parent-directory auto-creation under the workspace root.

### G. Audit & integrity (4)

- **G.1** Append-only security log (`tools/.security-log.jsonl`).
- **G.2** Rolling SHA-256 hash chain (each entry's `prev_hash` = first 16 hex of the previous entry's SHA-256). **Caveat:** detects modification only when validated against an external anchor; the log file itself is workspace-writable, so an attacker with shell access can rewrite the entire chain consistently.
- **G.3** Log rotation with explicit `rotation_marker` entry (no silent chain discontinuity at the rotation boundary).
- **G.4** File-modification tracking (`.claude/hooks/track-modified.sh`) records writes/edits for cross-session reconciliation.

### H. Governance enforcement (7) — *not security*

These run in the same Layer 0 hook architecture but enforce session discipline, not security boundaries. Listed here for completeness.

- **H.1** Three-date sentinel (HANDOFF / SPRINT / changelog must agree).
- **H.2** HANDOFF summary budget (≤ 6 items).
- **H.3** Mandatory lesson declaration at `/close` (Option A or B).
- **H.4** Session-close enforcement warning (Stop hook).
- **H.5** Cross-session outcome verification — files self-reported as created in `HANDOFF.json` are checked against the actual disk state.
- **H.6** PreCompact close warning.
- **H.7** SPRINT file budget (< 120 lines).

### Standing orders (advisory, not counted as controls)

`tasks/lessons/_shared.md` documents written rules — Rule 1 (sanitize all external content), Rule 2 (no-silent-fallback), Rule 3 (session close mandatory), Rule 4 (immediate lesson capture), Rule 12 (three-layer lesson enforcement), and others. These shape behavior but are not enforcement points; they appear here for completeness, not in the count.

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

This security model is informed by the following published frameworks. "Informed by" means the design draws on these frameworks; it does not claim certified or audited compliance, and several of the framework documents below are themselves drafts.

| Framework | Coverage | Notes |
|-----------|----------|-------|
| [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/) | LLM01 (Prompt Injection), LLM02 (Sensitive Info Disclosure), LLM06 (Excessive Agency), LLM10 (Unbounded Consumption) | Core focus areas. LLM06 mitigated via Bash command guard and project scope. |
| [OWASP Top 10 for Agentic Applications (2025/2026)](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) | ASI01 (Goal Hijack), ASI02 (Tool Misuse), ASI06 (Data Poisoning), ASI08 (Cascading Failures), ASI09 (Trust Exploitation) — partial. ASI03 (Identity/Privilege) addressed via *advisory* directives only, not deterministic enforcement (see Known Limitations §2). | Five of ten risks addressed deterministically; ASI03 advisory; ASI04/05/07/10 noted in Known Limitations. |
| [NIST AI Risk Management Framework](https://csrc.nist.gov/pubs/ir/8596/iprd) — *Draft, Dec 2025* | Cybersecurity Framework Profile for AI (Draft) | Audit logging with tamper detection, fail-closed design, and non-bypassable Layer 0 hooks are informed by NIST's "non-bypassable controls" concept. Framework is currently a draft; final form may differ. |
| [NIST SP 800-53 COSAiS](https://cloudsecurityalliance.org/blog/2025/09/03/a-look-at-the-new-ai-control-frameworks-from-nist-and-csa) — *In development* | Control overlays for single-agent AI | Workspace boundary enforcement and tool-call validation are informed by anticipated control requirements. The control overlay itself is not yet finalized. |
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
