---
name: new-project
description: Add a new project with full governance scaffolding. Creates project folder, context files, memory, lessons, and context-loading skill.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, TodoWrite
---

# New Project Bootstrap

## Step 1: Gather Info
Ask the user conversationally:
- "What's the project name?"
- "Tell me about it — what is it, how far along, anything I should know?"

## Step 2: Create Project Files
From the user's answers, create:

1. `Projects/{Name}/PROJECT-CONTEXT.md` — Use the Project Context Template from TEMPLATES.md
2. `Projects/{Name}/CHANGELOG.md` — Header: `# {Name} Changelog`
3. `memory/projects/{slug}.md` — Use the Deep Memory Template from TEMPLATES.md
4. `tasks/lessons/{slug}.md` — Header + empty rules section:
   ```
   # Lessons — {Name}
   > Domain-specific lessons for {name} sessions.

   ## Rules
   (none yet)
   ```
5. `.claude/skills/{slug}-context/SKILL.md`:
   ```yaml
   ---
   name: {slug}-context
   description: Load {project name} context. Use when working on {trigger phrases}.
   user-invocable: false
   allowed-tools: Read
   ---

   Load context for {project name}:
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
- Add a row to `executive-summary/EXECUTIVE_SUMMARY.md` Portfolio Status table
- Add a line to `memory/INDEX.md` under Projects
- Update `memory/context/company.md` Active Projects table
- Update `CURRENT-SPRINT.md` if the project has P0/P1 items

## Step 4: Confirm
Tell the user: "Project {Name} is set up. Context loader, lessons file, and memory are ready."
