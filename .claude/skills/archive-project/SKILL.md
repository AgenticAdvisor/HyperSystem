---
name: archive-project
description: Sunset a project cleanly. Moves files to archive, updates governance references.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, TodoWrite
---

# Archive Project

## Step 1: Confirm
Ask: "Which project do you want to archive?" List active projects from `executive-summary/EXECUTIVE_SUMMARY.md`.
Confirm with the user before proceeding.

## Step 2: Move Project Files
- Move `Projects/{Name}/` to `Projects/Reference/{Name}/`
- Keep `memory/projects/{slug}.md` (reference, don't delete)

## Step 3: Update Governance Files
- Update `executive-summary/EXECUTIVE_SUMMARY.md`: change status to "Archived"
- Update `memory/INDEX.md`: mark as archived
- Update `memory/context/company.md`: remove from Active Projects
- Remove from `CURRENT-SPRINT.md` P0/P1 tables if present
- Remove the context-loading skill `.claude/skills/{slug}-context/`

## Step 4: Confirm
Tell the user: "Project {Name} archived to Projects/Reference/. Memory preserved for reference."
