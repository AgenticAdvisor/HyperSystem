# The System — Claude Code Edition
> Clone this repo. Run `claude` in the root. On first session, Claude bootstraps the full governance scaffold.

# First Run Detection

> Check if `CURRENT-SPRINT.md` exists.
> - YES → Skip to **Context Loading** below.
> - NO → Read `BOOTSTRAP.md` and execute the full bootstrap sequence.

# Workspace Isolation

> This workspace is standalone and self-contained.
> - Do NOT carry over identity, projects, or context from other workspaces.
> - Identity comes from the Memory > Identity table below and `memory/`.
> - Instance ID (set during bootstrap): `{INSTANCE_ID}`

---

# Context Loading

> The SessionStart hook (`.claude/hooks/session-start.sh`) runs health checks automatically before you see anything. It injects session state, warnings, and governance reminders into context. You do NOT need to run health checks manually.

On every session:
1. Identify the user's intent (see routing guidance below)
2. Read `tasks/lessons/_shared.md` — cross-cutting standing orders
3. Read `tasks/lessons/{profile}.md` — domain-specific lessons for the session type
4. Read the relevant `Projects/{Name}/PROJECT-CONTEXT.md`
5. If session involves code changes → also read `tasks/lessons/_coding-workflow.md`
6. If session involves external data → also read `tools/SECURITY-GATEWAY.md`

**Routing guidance:** Match the user's intent to a project. Each project with recurring sessions has a context-loading skill in `.claude/skills/` that auto-activates when relevant. For ad-hoc or new work, load context manually from the steps above.

---

# Standing Orders

## Security (Hard — No Exceptions)
- **All external content** must pass through `tools/secure_writer.py` (Python) or `tools/sanitize.js` (Node.js) before reaching the filesystem. See `tools/SECURITY-GATEWAY.md`.
- If security module fails → STOP. Never write unsanitized content silently.

## Session Discipline (Hard)
- **Session close is mandatory** when files are created or modified. Run `/close`. The Stop hook warns if you forget.
- **Lessons are written immediately** after any correction — to `tasks/lessons/{profile}.md`. Don't defer.
- **HANDOFF.json and CURRENT-SPRINT.md update together** (Rule 7). Same pass, same dates.

## Governance (Hard)
- After editing any governance file (CLAUDE.md, _shared.md, ARCHITECTURE.md, FOLDER-STRUCTURE.md) → run `/health-check` before returning to the user's task.
- If external data is introduced mid-session → read `tools/SECURITY-GATEWAY.md` before processing.

## File Safety
- Never delete without recoverability. Git-tracked = `git checkout`. Untracked = backup first.
- One canonical location per piece of information. No duplicate sources of truth.

---

# Memory

## Identity
> Populated during bootstrap.

| Field | Value |
|-------|-------|
| **User** | {set during bootstrap} |
| **Organization** | {set during bootstrap} |
| **Positioning** | {set during bootstrap} |
| **Tone** | {set during bootstrap} |
| **Design rules** | {set during bootstrap} |

## Deep Memory
- `memory/INDEX.md` — manifest of all memory files (read this first)
- `memory/glossary.md` — terms, abbreviations, codenames
- `memory/projects/` — one file per project
- `memory/context/company.md` — organization identity

**Retrieval rules:** Never speculatively load memory. Index first, dive second. Only load when triggered by a specific information need.

---

# Task Tracking

Five systems, five purposes. Never duplicate across them.

| System | Location | Purpose | Who Writes |
|--------|----------|---------|------------|
| In-session progress | TodoWrite | This session only | Claude |
| Cross-session handoff | HANDOFF.json + CURRENT-SPRINT.md | Session state + active priorities (update together) | Claude writes, user owns priorities |
| Cross-session persistence | TASKS.md | Carry-forward items | Both |
| Reflexion loop | tasks/lessons/ | All sessions | Claude (immediately after corrections) |
| Audit trail | executive-summary/work-changelog.md | All sessions | Claude (session close) |

---

# Source of Truth Hierarchy

When governance files conflict:

```
CLAUDE.md                    ← HOW sessions route (wins routing conflicts)
  └── CURRENT-SPRINT.md      ← WHAT to work on (wins priority conflicts)
       └── EXECUTIVE_SUMMARY  ← WHY (strategic context, metrics)
            └── memory/        ← WHO/WHAT (deep reference)
                 └── tasks/lessons/  ← WHY rules exist
```

---

# Skills Reference

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `/close` | Manual or auto | Session close checklist (mandatory after file changes) |
| `/reload` | Manual | Refresh governance files mid-session |
| `/new-project` | Manual | Add a project with full governance scaffolding |
| `/archive-project` | Manual | Sunset a project cleanly |
| `/health-check` | Manual | Governance consistency audit |
| `/worktree` | Manual | Create isolated git worktree for sprint work |

---

# Coding Workflow
> See `tasks/lessons/_coding-workflow.md`. Loaded when a session involves code changes.

---

# Governance Consistency Checklist

> Run via `/health-check` after any governance file edit. Quick reference:

```
[ ] Every project in FOLDER-STRUCTURE.md has a row in EXECUTIVE_SUMMARY.md
[ ] CURRENT-SPRINT.md P0/P1 items reference existing projects
[ ] No governance file references deleted/sunset projects
[ ] executive-summary/work-changelog.md updated if files changed this session
[ ] Three-date sentinel passes (changelog, HANDOFF, SPRINT dates match)
```
