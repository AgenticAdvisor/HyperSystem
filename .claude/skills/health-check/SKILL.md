---
name: health-check
description: Full governance consistency audit. Run after any governance file edit or when something feels off.
user-invocable: true
allowed-tools: Read, Bash, TodoWrite
---

# Governance Health Check

Run all 10 checks below. Report results as a checklist with checkmarks for passing and warnings for failures.

## Check 1: Folder Structure

Verify every directory listed in `docs/FOLDER-STRUCTURE.md` actually exists on disk. Flag any missing directories.

## Check 2: Project References

Verify every project listed in `executive-summary/EXECUTIVE_SUMMARY.md` (that is not archived) has a corresponding `Projects/{Name}/` folder. Flag mismatches.

## Check 3: Sprint References

Verify every P0/P1 item in `CURRENT-SPRINT.md` references a project that exists in `executive-summary/EXECUTIVE_SUMMARY.md` and has an active status. Flag orphaned references.

## Check 4: Three-Date Sentinel

Compare the last-updated dates across three files:
- `HANDOFF.json` — the `last_updated` field
- `CURRENT-SPRINT.md` — the `Last updated` line
- `executive-summary/work-changelog.md` — the most recent `## YYYY-MM-DD` heading

All three dates MUST match. Flag any mismatch.

## Check 5: Memory Index

Verify every file path listed in `memory/INDEX.md` exists on disk. Flag missing files.

## Check 6: No Orphan Projects

Verify every folder under `Projects/` (excluding `Projects/Reference/`) has a corresponding row in `executive-summary/EXECUTIVE_SUMMARY.md`. Flag orphans.

## Check 7: File Budgets

- `CURRENT-SPRINT.md` must be under 120 lines. Flag if over.
- `HANDOFF.json` summary array must have 6 or fewer items. Flag if over.

## Check 8: Security Tools

Verify all files listed under `tools/` in `docs/FOLDER-STRUCTURE.md` exist on disk. Flag missing tools.

## Check 9: Skills

Verify every directory under `.claude/skills/` contains a `SKILL.md` file. Flag any skill directory missing its definition.

## Check 10: Lessons

Verify `tasks/lessons/_shared.md` exists and is non-empty. Flag if missing or empty.

---

## Output Format

Present results as:

```
Governance Health Check
=======================
[x] Check 1: Folder Structure — All directories present
[!] Check 2: Project References — Missing folder for "Example Project"
[x] Check 3: Sprint References — All references valid
...

Summary: X/10 checks passed. Y warnings.
```

If all checks pass: **"Governance is healthy."**
If any fail: List the specific issues and suggest fixes.
