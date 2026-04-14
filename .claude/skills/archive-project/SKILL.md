---
name: archive-project
description: Sunset a project cleanly. Moves files to archive, updates governance references.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, TodoWrite
---

# Archive Project

## Step 1: Confirm

Ask the user which project to archive. List active projects from `executive-summary/EXECUTIVE_SUMMARY.md` so they can choose. Do not proceed without explicit confirmation.

## Step 2: Move Project Files

Move `Projects/{Name}/` to `Projects/Reference/{Name}/`. Create the `Projects/Reference/` directory if it does not exist. Keep the `memory/projects/{slug}.md` file in place — memory is retained for archived projects.

## Step 3: Update Governance

1. **`executive-summary/EXECUTIVE_SUMMARY.md`** — Change the project's status to "Archived".
2. **`memory/INDEX.md`** — Mark the project entry as archived (e.g., append "(archived)").
3. **`memory/context/company.md`** — Remove the project from the active projects list.
4. **CURRENT-SPRINT.md** — Remove any references to the archived project.
5. **`.claude/skills/{slug}-context/`** — Delete the context-loading skill directory for this project.

## Step 4: Confirm

Tell the user: **"Project {Name} archived."** Summarize what was moved and what governance files were updated.
