---
name: close
description: Session close checklist. Run at the end of any session with file changes.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, TodoWrite
---

# Session Close Checklist

Run these steps in order. Do not skip steps.

## Step 1: Review Modified Files

Check `/tmp/.claude-modified-files-${SESSION_ID}` for the list of files modified this session. If the file does not exist or is empty, tell the user "No file changes detected this session — no close needed." and stop.

## Step 2: Lesson Declaration (MANDATORY)

Review the session for corrections, mistakes, and technical lessons learned.

You MUST declare one of the following — this step cannot be skipped:

**Option A — Corrections occurred:**
State: "Corrections logged:" followed by a list of each lesson written, including:
- The lessons file modified (e.g., `tasks/lessons/{profile}.md`)
- The rule number and title added
- One-line summary of what was learned

**Option B — No corrections:**
State: "No corrections this session — no lessons to capture."

If project code was modified but you declare Option B, briefly explain why
(e.g., "Trivial config change, no new patterns learned").

## Step 3: Update HANDOFF.json and CURRENT-SPRINT.md

These two files MUST be updated in the same pass (Rule 7). For HANDOFF.json:
- Update `last_updated` date to today
- Update `session_label` to describe what was done
- Update `summary` with key outcomes
- Update `decisions` with any decisions made
- Update `files_changed` with the modified files list
- Detect worktree/branch: run `git rev-parse --abbrev-ref HEAD` and check if working directory is inside a worktree (`git rev-parse --show-toplevel` differs from main repo root). Record in `last_session.worktree` (branch name if in worktree, `null` if on main)

For CURRENT-SPRINT.md:
- Update the `Last updated` date to match HANDOFF.json exactly
- Update task statuses if any changed
- Add notes on progress

**The dates in HANDOFF.json and CURRENT-SPRINT.md MUST match.**

## Step 4: Update Work Changelog

Append a dated entry to `executive-summary/work-changelog.md`. Use the format:

```markdown
## YYYY-MM-DD — {Session Label}

- Bullet point summarizing what was done
- Another bullet if needed
```

**The date MUST match the dates in HANDOFF.json and CURRENT-SPRINT.md.** This is the three-date sentinel rule.

## Step 5: Update PROJECT-CONTEXT.md if Applicable

For each project touched during the session, update its `Projects/{Name}/PROJECT-CONTEXT.md`:
- Update the status field if it changed
- Update the "last touched" date to today

If no project-specific work was done, skip this step.

## Step 6: Create Close Marker

Run: `touch /tmp/.claude-session-closed-${SESSION_ID}`

Tell the user: **"Session closed. Governance state updated."**
