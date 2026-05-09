---
name: reload
description: Refresh governance files mid-session. Use when CLAUDE.md or governance files have been externally edited.
user-invocable: true
allowed-tools: Read
---

# Reload Governance Context

Re-read these files to refresh your understanding of the current workspace state:

1. Read `CLAUDE.md` (routing, standing orders, memory pointers)
2. Read `CURRENT-SPRINT.md` (active priorities)
3. Read `HANDOFF.json` (last session state)
4. Read `tasks/lessons/_shared.md` (standing orders)
5. Read the relevant `tasks/lessons/{profile}.md` for the current session type

Tell the user: "Governance context reloaded. Ready to continue."
