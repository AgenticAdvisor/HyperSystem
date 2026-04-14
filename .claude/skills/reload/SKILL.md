---
name: reload
description: Refresh governance files mid-session. Use when CLAUDE.md or governance files have been externally edited.
user-invocable: true
allowed-tools: Read
---

# Reload Governance Context

Re-read the following files in order to refresh your working context:

1. **CLAUDE.md** — Root governance and routing instructions
2. **CURRENT-SPRINT.md** — Active priorities and sprint state
3. **HANDOFF.json** — Session handoff state
4. **tasks/lessons/_shared.md** — Cross-cutting standing orders and lessons
5. **Relevant tasks/lessons/{profile}.md** — Domain-specific lessons for the current session type (determine from the work being done)

After reading all files, tell the user: **"Governance context reloaded. Ready to continue."**
