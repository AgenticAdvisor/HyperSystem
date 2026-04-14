# Architecture

> How The System is designed and why.

---

## Design Philosophy

Three principles drive every decision:

1. **Deterministic enforcement over instructional compliance.** Hooks run before the LLM sees context. They cannot be skipped, forgotten, or misinterpreted. Anything that must always happen belongs in a hook.
2. **Lean context, loaded on demand.** CLAUDE.md stays under 1,200 tokens. Skills, lessons, and memory load only when relevant. Unused knowledge costs zero tokens.
3. **Dev-first UX.** Slash commands, not procedures. Git for recovery, not backup directories. The system stays out of the way until needed.

---

## Four-Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Layer 0: Deterministic Enforcement (hooks)             │
│  Runs before LLM · Can't be skipped · No token cost    │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Governance (CLAUDE.md)                        │
│  Loaded every turn · <1,200 tokens · Routing + rules   │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Operations (skills + lessons)                 │
│  Per-session or per-invocation · Zero cost when unused  │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Knowledge (memory + executive summary)        │
│  On demand · Never speculatively loaded                 │
└─────────────────────────────────────────────────────────┘
```

Each layer loads only when needed. Layers 2 and 3 contribute zero tokens to sessions that don't use them.

---

## Why Four Layers

The critical insight: **Layer 0 makes governance guarantees possible.**

Without hooks, every rule depends on the LLM remembering to follow it. With hooks:
- **Health checks are guaranteed** — SessionStart fires before the LLM processes anything
- **File tracking is automatic** — PostToolUse fires after every Write/Edit, no LLM involvement
- **Session close is enforced** — Stop hook warns if files changed without `/close`
- **Compact triggers close** — PreCompact hook catches the edge case of context compaction without session close

Hooks handle binary questions (did close happen? were files modified?). CLAUDE.md handles judgment calls (which profile is active? what context to load?). This separation keeps both clean.

---

## Key Design Decisions

### Hooks for Enforcement, CLAUDE.md for Judgment

Hooks answer binary questions: Did session close happen? Were files modified? Is the three-date sentinel passing? These have deterministic answers and deterministic responses.

CLAUDE.md answers judgment questions: Which lessons profile applies? Should security gateway docs be loaded? What project context is relevant? These require LLM reasoning.

Mixing them — putting enforcement in CLAUDE.md or judgment in hooks — degrades both.

### Skills Replace Procedural Sections

The session close checklist is a skill (`/close`), not a section in CLAUDE.md. This saves ~2,000 tokens per turn. The checklist loads only when invoked.

Same pattern for `/new-project`, `/archive-project`, `/health-check`, and `/reload`. Each would add 200-500 tokens to every turn if inlined. As skills, their cost is zero until needed.

### Dual Memory with Domain Boundaries

Two memory systems serve different purposes:
- **Auto-memory** (Claude Code's built-in `MEMORY.md`) owns behavioral guidance — how to communicate, user preferences, interaction patterns.
- **Manual memory** (`memory/` directory) owns project knowledge — deep context, glossary, organizational identity.

Clear ownership prevents duplication and drift. A fact lives in exactly one place.

### Git IS the Backup

`git checkout HEAD~1 -- path/to/file` replaces an entire backup system. No `_backups/` directory, no timestamped copies, no cleanup scripts.

Every file modification is tracked by the PostToolUse hook. Git history provides full recoverability. The system trusts git to do what git does.

---

## Hook Architecture

```
SessionStart
  └── session-start.sh
       ├── Three-date sentinel (changelog, HANDOFF, SPRINT dates match)
       ├── File budget warnings (SPRINT lines, HANDOFF summary items)
       ├── Lesson coverage audit (cross-session — checks previous session)
       ├── Outcome verification (OWASP ASI09 — HANDOFF claims vs disk)
       ├── HANDOFF label extraction (session context)
       └── Injects warnings into additionalContext

PreToolUse (Bash)
  ├── pre-tool-bash-guard.sh
  │    ├── Data exfiltration detection (curl/wget/nc with outbound data)
  │    ├── Destructive operation detection (rm -rf, mkfs, git force push)
  │    ├── Privilege escalation detection (sudo, chmod +s, chown root)
  │    ├── Reverse shell detection (bash -i, netcat -e, python socket)
  │    ├── Credential harvesting detection (grep PASSWORD, env dump)
  │    └── Sensitive file access detection (.env, /etc/passwd, .ssh/)
  └── pre-commit-secrets.sh (git commit only)
       ├── API key detection (Anthropic, OpenAI, Google, AWS — 8 patterns)
       ├── Token detection (GitHub, Slack, Stripe — 8 patterns)
       ├── Private key detection (RSA, EC, DSA, PGP — 2 patterns)
       ├── Secret assignment detection (PASSWORD, API_KEY, etc. — 7 patterns)
       ├── Connection string detection (MongoDB, PostgreSQL, MySQL, Redis)
       └── .env file commit prevention

Work Phase
  └── PostToolUse (Write, Edit)
       └── track-modified.sh
            └── Appends modified file paths to /tmp/.claude-modified-files

Stop
  └── stop-guard.sh
       ├── Checks: were files modified AND was /close not run?
       ├── YES → Warn via additionalContext (does NOT block)
       └── NO → Silent pass

PreCompact
  └── pre-compact-close.sh
       ├── Same check as stop-guard
       └── Catches context compaction without session close
```

**Warn-not-block pattern:** All enforcement hooks use `exit 0` with `additionalContext`, never `exit 2` (which would block the operation). The secrets pre-commit hook is the one exception — it exits `1` to block commits containing secrets. Defense in depth — multiple hooks catch the same issue at different points.

---

## Security Architecture

```
External Data → secure_writer.py → Workspace Files
                    │
                    ├── sanitize → log → write
                    ├── Delegates to content_security.py (6-phase, 30+ vectors)
                    ├── Functions: write_text(), write_json(), write_lines(), sanitize_only()
                    ├── Audit trail: tools/.security-log.jsonl
                    └── Failure mode: STOP
```

Two entry points:
- **Python**: `tools/secure_writer.py` — primary gateway for Python-based workflows
- **Node.js**: `tools/sanitize.js` — delegates to Python via `tools/_sanitize_bridge.py`

All external content must pass through one of these before reaching the filesystem. The Standing Orders in CLAUDE.md enforce this at the governance layer. The detection engine (`content_security.py`) runs a 6-phase pipeline covering 30+ attack vectors.

If sanitization fails, the system stops. No silent fallback. No writing unsanitized content.

---

## Startup Sequence

1. **Hook fires** — `session-start.sh` runs health checks, injects warnings into context
2. **Claude reads CLAUDE.md** — routing rules, standing orders, identity (loaded every turn by Claude Code)
3. **Claude reads user message** — identifies intent, loads relevant context per Context Loading rules
4. **Work begins** — with full governance active, file tracking enabled, and session state known

---

## Source of Truth Hierarchy

When governance files conflict:

```
CLAUDE.md                    ← HOW sessions route (wins routing conflicts)
  └── CURRENT-SPRINT.md      ← WHAT to work on (wins priority conflicts)
       └── EXECUTIVE_SUMMARY  ← WHY (strategic context, metrics)
            └── memory/        ← WHO/WHAT (deep reference)
                 └── tasks/lessons/  ← WHY rules exist
```

---

## Five Governance Systems

| System | File(s) | Scope | Who Writes |
|--------|---------|-------|------------|
| In-session progress | TodoWrite | Current session | Claude |
| Cross-session handoff | HANDOFF.json + CURRENT-SPRINT.md | Between sessions | Claude writes, user owns priorities |
| Cross-session persistence | TASKS.md | Across sessions | Both |
| Reflexion loop | tasks/lessons/*.md | All sessions | Claude (immediately after corrections) |
| Audit trail | executive-summary/work-changelog.md | All sessions | Claude (at session close) |

---

## Scaling Properties

- **Adding projects:** O(1). Run `/new-project`. Creates folder, context file, memory entry, lessons profile, and context-loading skill. No existing files modified except governance indexes.
- **Adding profiles:** One skill file + one lessons file. The system discovers them automatically.
- **Adding complexity:** Hooks and skills compose. A new enforcement rule is one hook + one line in `settings.json`. A new workflow is one skill. Neither bloats CLAUDE.md.

---

## Recovery (Git-Based)

| Scenario | Command |
|----------|---------|
| Restore a single file | `git checkout HEAD~1 -- path/to/file` |
| See what changed | `git diff HEAD~1` |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` |
| Undo last commit (discard changes) | `git reset --hard HEAD~1` |
| Find when a file was deleted | `git log --diff-filter=D -- path/to/file` |
| Restore deleted file | `git checkout <commit>~1 -- path/to/file` |

No backup directories. No timestamped copies. Git handles recovery.
