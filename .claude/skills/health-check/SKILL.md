---
name: health-check
description: Full governance consistency audit. Run after any governance file edit or when something feels off.
user-invocable: true
allowed-tools: Read, Bash, TodoWrite
---

# Governance Health Check

Run each check and report results. Use checkmarks for pass, warnings for fail.

## Checks

1. **Folder structure** — Every directory in FOLDER-STRUCTURE.md exists on disk
2. **Project references** — Every project in EXECUTIVE_SUMMARY.md has a `Projects/{Name}/` folder
3. **Sprint references** — CURRENT-SPRINT.md P0/P1 items reference existing projects
4. **Three-date sentinel** — Dates match across:
   - `HANDOFF.json` → `last_session.date`
   - `CURRENT-SPRINT.md` → `Last updated:`
   - `executive-summary/work-changelog.md` → last `## YYYY-MM-DD` entry
5. **Memory index** — Every file listed in `memory/INDEX.md` exists on disk
6. **No orphan projects** — Every `Projects/{Name}/` folder has a row in EXECUTIVE_SUMMARY.md
7. **File budgets** — CURRENT-SPRINT.md under 120 lines, HANDOFF.json summary under 6 items
8. **Security tools** — All files listed in FOLDER-STRUCTURE.md under `tools/` exist
9. **Skills** — All skill directories in `.claude/skills/` have a `SKILL.md` file
10. **Lessons** — `tasks/lessons/_shared.md` exists and is non-empty

## Output
Report results as a checklist. If any check fails, explain what's wrong and how to fix it.
