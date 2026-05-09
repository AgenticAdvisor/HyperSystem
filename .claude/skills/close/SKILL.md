---
name: close
description: Session close checklist. Run at the end of any session with file changes.
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, TodoWrite
---

# Session Close Checklist

Execute these steps in order. Do not skip any step.

## Step 1: Review Modified Files + Branch Check
- Check `/tmp/.claude-modified-files-${SESSION_ID}` for files modified this session
- If no modified files exist, tell the user "No files were modified — session close not needed" and stop
- Run: `git rev-parse --abbrev-ref HEAD`
- If branch is `main` → proceed to Step 2.
- If branch is NOT `main`:
  - Print this explanation:
    > HEAD is `<branch>`, not `main`. Workspace-scope governance writes
    > (HANDOFF.json / CURRENT-SPRINT.md / EXECUTIVE_SUMMARY.md /
    > work-changelog.md / `tasks/lessons/_*.md`) belong on `main` per
    > the workspace-scope governance rule. Project-scope governance
    > (PROJECT-CONTEXT.md, per-project CHANGELOG, project dev-logs /
    > specs / plans, project-specific lessons in
    > `tasks/lessons/<project>.md`) legitimately rides on a feature
    > branch. Which is this close?
  - Use AskUserQuestion with options:
    - "Switch to main before continuing close"
    - "Stay on this branch (writes are intentionally branch-scoped)"
  - If "switch":
    - Run `git status --short` to verify clean tree.
    - If dirty: surface the modified files to the user with options
      (commit on branch / stash / abort close). Do NOT auto-commit.
    - Once clean (or stashed), run `git checkout main` then proceed to Step 2.
  - If "stay": proceed on branch and record the decision in
    `HANDOFF.last_session.decisions` at Step 3 (e.g.,
    "Stayed on branch `<branch>` for close: writes are project-scoped
    [PROJECT-CONTEXT, CHANGELOG, etc.]; will arrive on main at merge.").

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
- Update both files in the SAME pass (Rule 7)
- HANDOFF.json: update date, label, summary, decisions, files_created, files_modified, next_session_should, worktree
- Detect worktree/branch: run `git rev-parse --abbrev-ref HEAD` and check if working directory is inside a worktree (`git rev-parse --show-toplevel` differs from main repo root). Record in HANDOFF.json `last_session.worktree` (branch name if in worktree, `null` if on main)
- CURRENT-SPRINT.md: update "Last updated" date, move completed items, update Active P0/P1 tables
- Dates MUST match between both files

## Step 3.5: Verify HANDOFF Summary Budget
- Run: `python3 tools/check-handoff-budget.py`
- If exit code 0 → proceed to Step 4.
- If exit code 1:
  - Read the script's stdout (lists current items + consolidation prompt).
  - Use AskUserQuestion with options:
    - "Consolidate now (merge items and re-write HANDOFF)"
    - "Proceed at <N> items (log reason in HANDOFF.last_session.decisions)"
  - If "consolidate": iterate — edit `HANDOFF.json` to merge items, re-run
    the script, repeat until exit 0.
  - If "proceed": append a one-line rationale to
    `HANDOFF.last_session.decisions` explaining why the budget was exceeded
    (e.g., "Summary at 7 items — multi-project session spanning A, B, C;
    consolidation would lose distinct narratives.").

## Step 4: Update Work Changelog
- Append a dated entry to `executive-summary/work-changelog.md`
- Format: `## YYYY-MM-DD — {Session Label}`
- Include bullet points summarizing what was done
- Date MUST match HANDOFF.json and CURRENT-SPRINT.md

## Step 5: Update PROJECT-CONTEXT.md (if applicable)
- For each project touched this session, update its `Projects/{Name}/PROJECT-CONTEXT.md`
- Update status, last touched date, current state

## Step 6: Create Close Marker
- Run: `touch /tmp/.claude-session-closed-${SESSION_ID}`
- Tell the user: "Session closed. Governance state updated."
