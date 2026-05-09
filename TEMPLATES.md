# Templates

> File templates used during bootstrap (Steps 3-4) and the `/new-project` skill.
> Not loaded during normal sessions — only referenced when creating new files.
>
> All templates use `{placeholder}` syntax. Replace with actual values during generation.

---

## 1. Handoff Template

> Path: `HANDOFF.json`

```json
{
  "schema_version": "1.0",
  "last_session": {
    "date": "{YYYY-MM-DD}",
    "label": "{descriptive-label}",
    "summary": [
      "{what was accomplished — max 6 items}"
    ],
    "decisions": [
      "{key decisions made during the session}"
    ],
    "files_created": [
      "{list of new files}"
    ],
    "files_modified": [
      "{list of changed files}"
    ],
    "worktree": null
  },
  "next_session_should": [
    "{what the next session should pick up}"
  ],
  "active_blockers": [
    "{anything blocking progress — empty array if none}"
  ]
}
```

**Rules:**
- `summary` array: max 6 items. Be specific, not vague.
- `date` must match the dates in `CURRENT-SPRINT.md` and `executive-summary/work-changelog.md` (three-date sentinel).
- `label` is a short slug like `bootstrap-init` or `website-redesign`. Used for stale session detection.
- `files_created` and `files_modified` are populated from `.claude/.modified-files` during session close.

---

## 2. Shared Lessons Template

> Path: `tasks/lessons/_shared.md`
> Note: This file ships with the repo. Template here for reference only.

```markdown
# Lessons — Shared
> Cross-cutting standing orders that apply to ALL session profiles.
> Loaded first, before any profile-specific lessons file.
>
> **Numbering convention:** rule numbers are stable identifiers assigned in the order rules were added. Sections group rules topically, so numbers may appear non-sequentially within the file. External references depend on numbers staying stable — never renumber existing rules.

## Security Baseline

### Rule 1: Sanitize All External Content
- **TRIGGER:** Any data crossing a trust boundary into the workspace
- **RULE:** All external/untrusted content must pass through `tools/secure_writer.py` (Python) or `tools/sanitize.js` (Node.js) before reaching the filesystem. No exceptions.
- **DETAIL:** See `tools/SECURITY-GATEWAY.md` for API reference and compliance table.

### Rule 2: No Silent Fallback on Security
- **TRIGGER:** Security module unavailable, import error, or sanitization failure
- **RULE:** Pipeline STOPS. Never fall back to writing unsanitized content. Surface the error to the user.

## Session Discipline

### Rule 3: Session Close Is Not Optional
- **TRIGGER:** End of any session with file changes
- **RULE:** Run all steps of the Session Close Checklist in order. A session with file changes that skips close is a governance failure.

### Rule 4: Lessons Are Written Immediately
- **TRIGGER:** Any correction from the user during a session
- **RULE:** Write the lesson to `tasks/lessons/{profile}.md` the moment the correction happens. Don't defer to end of session.

## Coding Standards

### Rule 11: TDD Is Default for All Code
- **TRIGGER:** Any session that writes or modifies code
- **RULE:** Write failing tests before implementation. Red-green-refactor, no exceptions. Trivial one-line fixes may skip if no test infrastructure exists yet.

## File Safety

### Rule 5: Never Delete Without Recoverability
- **TRIGGER:** Any file deletion, rename, or overwrite of untracked content
- **RULE:** Git-tracked files can be recovered via `git checkout`. Untracked files must get a backup copy first.

### Rule 6: No Duplicate Source of Truth
- **TRIGGER:** Creating a file that contains content already canonical elsewhere
- **RULE:** One canonical location per piece of information. Use pointers instead of copies.

## Governance

### Rule 7: HANDOFF.json and CURRENT-SPRINT.md Update Together
- **TRIGGER:** Session close step 3
- **RULE:** These two files share ~80% of the same state. Update them in a single pass. The three-date sentinel detects drift.

### Rule 8: Architecture Docs Must Reflect Reality
- **TRIGGER:** Any governance file edit, or architecture/infrastructure change
- **RULE:** If ARCHITECTURE.md references a file, that file must exist. If a file is removed, update ARCHITECTURE.md.

### Rule 9: Governance Edits Trigger Consistency Check
- **TRIGGER:** Any edit to CLAUDE.md, _shared.md, ARCHITECTURE.md, FOLDER-STRUCTURE.md
- **RULE:** Run the Governance Consistency Checklist before returning to the user's task.

### Rule 12: Lesson Enforcement Is Three-Layer
- **TRIGGER:** Any session that modifies project code
- **RULE:** Three enforcement layers ensure lessons are captured: (1) session-start hook audits previous session, (2) `/close` Step 2 requires explicit declaration, (3) context-loading skills load lessons as working documents.

### Rule 10: Memory Systems Don't Overlap
- **TRIGGER:** Writing information to a memory file
- **RULE:** Auto-memory owns feedback, corrections, user preferences. Manual memory/ owns project knowledge, org context, glossary. Check for overlap before creating new entries.
```

---

## 3. Memory Index Template

> Path: `memory/INDEX.md`

```markdown
# Memory Index
> Manifest of all memory files. Read this first — dive into specific files only when needed.

## Glossary & Context
- `glossary.md` — Terms, abbreviations, codenames
- `context/company.md` — Organization identity, priorities, tools

## Projects
{for each project:}
- `projects/{slug}.md` — {project name}: {one-line description}
```

---

## 4. Project Context Template

> Path: `Projects/{Name}/PROJECT-CONTEXT.md`
> Keep this under 40 lines. It loads at session start for every relevant session.

```markdown
# {Project Name} — Context

| Field | Value |
|-------|-------|
| **Completion** | {percentage or phase} |
| **Priority** | {P0/P1/P2} |
| **Architecture Score** | {1-5, where 5 = clean and extensible} |
| **Blockers** | {current blockers or "None"} |
| **Last Touched** | {YYYY-MM-DD} |

## Tech Stack
{languages, frameworks, key dependencies}

## Key Files
| File | Purpose |
|------|---------|
| {path} | {what it does} |

## Current State & Decisions
{2-3 sentences on where the project is and any recent decisions}

## Gotchas
{known issues, quirks, things that will bite you}

## What NOT to Touch
{files or areas that are stable and should not be modified without good reason}
```

---

## 5. Deep Memory Template

> Path: `memory/projects/{slug}.md`

```markdown
# {Project Name}

## What It Is
{one paragraph description}

## Current State
{where the project stands — phase, maturity, recent changes}

## Known Issues
{bugs, limitations, technical debt}

## Dependencies
{external services, APIs, libraries, other projects}

## Key Context
{anything a future session needs to know that doesn't fit above}
```

---

## 6. Sprint Template

> Path: `CURRENT-SPRINT.md`

```markdown
# Current Sprint

> Last updated: {YYYY-MM-DD}

## Priority Stack

### P0 — Must Do
- [ ] {highest priority item} — {project name}

### P1 — Should Do
- [ ] {important but not urgent} — {project name}

### P2 — Nice to Have
- [ ] {backlog item} — {project name}

## Active Work

### P0
| Item | Project | Status | Notes |
|------|---------|--------|-------|
| {item} | {project} | {status} | {notes} |

### P1
| Item | Project | Status | Notes |
|------|---------|--------|-------|
| {item} | {project} | {status} | {notes} |

## Completed
| Item | Project | Date | Notes |
|------|---------|------|-------|
| Bootstrap workspace | — | {YYYY-MM-DD} | Initial setup |

## Session Handoff
See `HANDOFF.json` for machine-readable session state.

## How to Use
- P0 items are worked on first, always.
- P1 items are picked up when P0 is clear or blocked.
- P2 items are backlog — they don't drive sessions.
- Move items between tiers as priorities shift.
- Completed items move to the Completed table with a date.
```

---

## 7. Executive Summary Template

> Path: `executive-summary/EXECUTIVE_SUMMARY.md`

```markdown
# Executive Summary

> Strategic context, portfolio status, and session history.
> Updated at session close.

## Portfolio Status

| Project | Priority | Status | Completion | Last Session |
|---------|----------|--------|------------|--------------|
| {name} | {P0/P1/P2} | {active/paused/blocked} | {%} | {YYYY-MM-DD} |

## Key Metrics

| Metric | Value | Trend |
|--------|-------|-------|
| Active projects | {count} | — |
| P0 items open | {count} | — |
| Sessions this week | {count} | — |
| Architecture score (avg) | {1-5} | — |

## Session History

| Date | Label | Summary |
|------|-------|---------|
| {YYYY-MM-DD} | {label} | {one-line summary} |
```

---

## 8. Glossary Template

> Path: `memory/glossary.md`

```markdown
# Glossary

| Term | Definition |
|------|-----------|
| P0 | Highest priority — must be done immediately |
| P1 | Important — should be done soon |
| P2 | Nice to have — backlog |
| PROJECT-CONTEXT.md | Per-project session startup file (≤40 lines) |
| Three-date sentinel | Health check that verifies dates match across HANDOFF.json, CURRENT-SPRINT.md, and work-changelog.md |
| Session close | Mandatory end-of-session checklist (`/close`) |
| Deep memory | Persistent project knowledge in `memory/projects/` |
| Standing orders | Rules in `tasks/lessons/_shared.md` that apply to all sessions |
```

---

## 9. Company Context Template

> Path: `memory/context/company.md`

```markdown
# Organization Context

## Identity

| Field | Value |
|-------|-------|
| **Name** | {organization or individual name} |
| **Type** | {company/team/solo/etc.} |
| **Domain** | {what they do} |

## Current Priorities
{what the organization is focused on right now}

## Tools & Platforms
{languages, frameworks, services, deployment targets}

## Active Projects

| Project | Role | Priority |
|---------|------|----------|
| {name} | {what this project does} | {P0/P1/P2} |
```

---

## Usage Notes

- **Bootstrap** uses all templates (Steps 3-4).
- **`/new-project`** uses templates 3, 4, 5, and the context-loading skill template from `BOOTSTRAP.md` Step 4.
- **`/archive-project`** does not use templates — it moves existing files.
- Placeholder syntax: `{placeholder}` — replace with actual values. Do not leave placeholders in generated files.
- All paths use `executive-summary/` (kebab-case). No spaces in directory names.
