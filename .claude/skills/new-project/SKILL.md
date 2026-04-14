---
name: new-project
description: Add a new project with full governance scaffolding. Creates project folder, context files, memory, lessons, and context-loading skill.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, TodoWrite
---

# New Project Setup

## Step 1: Gather Info

Ask the user conversationally:
- **Project name** — What should this project be called?
- **Description** — One or two sentences about what the project is.

Do not proceed until you have both.

## Step 2: Create Project Files

Create the following 5 files. Use `{Name}` for the display name and `{slug}` for the kebab-case version (e.g., "My Project" becomes `my-project`).

1. **`Projects/{Name}/PROJECT-CONTEXT.md`** — Use the template from `docs/TEMPLATES.md`. Fill in the project name, description, and today's date. Set status to "Active".

2. **`Projects/{Name}/CHANGELOG.md`** — Initialize with:
   ```markdown
   # {Name} — Changelog

   ## YYYY-MM-DD — Project Created
   - Initial scaffolding via /new-project
   ```

3. **`memory/projects/{slug}.md`** — Initialize with:
   ```markdown
   # {Name}

   {Description}

   ## Key Decisions
   - (none yet)

   ## Architecture Notes
   - (none yet)
   ```

4. **`tasks/lessons/{slug}.md`** — Initialize with:
   ```markdown
   # Lessons — {Name}

   ## Rules
   (No rules yet. Rules are added when corrections are made during sessions.)
   ```

5. **`.claude/skills/{slug}-context/SKILL.md`** — Context-loading skill:
   ```yaml
   ---
   name: {slug}-context
   description: Load {Name} context. Use when working on {description snippet}.
   user-invocable: true
   allowed-tools: Read
   ---
   ```
   Body:
   ```markdown
   Load context for {Name}:
   1. Read `Projects/{Name}/PROJECT-CONTEXT.md`
   2. Read `tasks/lessons/{slug}.md` — this is your working document for this session.
      Scan for gaps: if you learn something new or get corrected, add it here immediately.
      Don't wait for session close.
   3. If this session involves external data, also read `tools/SECURITY-GATEWAY.md`

   Project boundary (OWASP ASI03): This session is scoped to `Projects/{Name}/`.
   Do not read or modify files in other project directories unless explicitly asked.
   Do not access credentials, tokens, or API keys belonging to other projects.
   ```

## Step 3: Update Governance Files

1. **`executive-summary/EXECUTIVE_SUMMARY.md`** — Add a row for the new project with status "Active".
2. **`memory/INDEX.md`** — Add a line pointing to `memory/projects/{slug}.md`.
3. **`memory/context/company.md`** — Add the project to the active projects list.
4. **CURRENT-SPRINT.md** — If the project is P0 or P1 priority, add it to the sprint.

## Step 4: Confirm

Tell the user: **"Project {Name} is set up."** List the files created.
