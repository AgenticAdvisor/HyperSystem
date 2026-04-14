# Customization Guide

> How to extend The System: add projects, modify rules, create hooks and skills.

---

## Adding a Project

The fastest path: run `/new-project` in a Claude Code session. It creates all 5 files automatically and updates governance indexes.

To add a project manually, create these files:

1. `Projects/{Name}/PROJECT-CONTEXT.md` -- session startup context (keep under 40 lines)
2. `memory/projects/{slug}.md` -- deep reference for the project
3. `.claude/skills/{slug}-context/SKILL.md` -- context-loading skill (auto-activates when relevant)
4. `tasks/lessons/{slug}.md` -- domain-specific lessons for this project

Then update these governance files:

5. `executive-summary/EXECUTIVE_SUMMARY.md` -- add a row in the project portfolio
6. `memory/INDEX.md` -- add a line in the memory manifest
7. `memory/context/company.md` -- add the project to organizational context

Run `/health-check` after to verify consistency.

---

## Modifying Standing Orders

Standing orders live in `tasks/lessons/` and load per-session, not per-turn.

- **`_shared.md`** -- Cross-cutting rules that apply to all sessions. Keep under 60 lines. These are the highest-priority operational rules after CLAUDE.md itself.
- **`_coding-workflow.md`** -- Coding-specific sequence and rules. Loaded only when a session involves code changes.
- **`{profile}.md`** -- Domain-specific lessons for a particular project or workflow. One file per profile.

Rules added here cost zero tokens in sessions that don't load them.

---

## Adding Hooks

Hooks are configured in `.claude/settings.json` under the `hooks` key.

Available lifecycle events:
- **SessionStart** -- fires before the LLM processes anything
- **PostToolUse** -- fires after a tool call (use `matcher` regex to filter by tool name)
- **Stop** -- fires when the session ends
- **PreCompact** -- fires before context compaction

Hook output format: JSON with an `additionalContext` field. The content is injected into the LLM's context.

Exit codes:
- `exit 0` -- warn (inject context, continue)
- `exit 2` -- block (prevent the operation)

Prefer `exit 0` with warnings over `exit 2` blocking. See the Design Philosophy doc for rationale.

---

## Adding Skills

1. Create `.claude/skills/{name}/SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: One-line description of what the skill does
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash"]
---
```

2. Write the skill instructions in the body of the file.
3. If the skill is user-invocable, add it to the Skills Reference table in `CLAUDE.md`.

Skills load only when invoked. They contribute zero tokens to sessions that don't use them.

---

## Extending the Security Pipeline

When creating a new pipeline that ingests external data:

1. Add an entry to the Pipeline Compliance Tracker in `tools/SECURITY-GATEWAY.md`.
2. Route all external data through `tools/secure_writer.py` (Python) or `tools/sanitize.js` (Node.js).
3. Use the `context` parameter to identify the data source for audit purposes.
4. Test with real data to populate `tools/.security-log.jsonl` and verify detections.

A pipeline without a compliance tracker entry is a critical security finding (P0).

---

## Changing Directory Layout

If you rename or move directories:

1. Update `FOLDER-STRUCTURE.md` to reflect the new structure.
2. Update `ARCHITECTURE.md` if the change affects system design references.
3. Update any hook or skill that references the changed path.
4. Run `/health-check` to verify governance consistency.

Paths are referenced across multiple governance files. A rename in one place without updating the others will cause health check failures.
