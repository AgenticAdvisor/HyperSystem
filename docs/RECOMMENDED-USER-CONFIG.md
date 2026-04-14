# Recommended User Config

> Optional user-level settings for `~/.claude/CLAUDE.md`. Applies to all Claude Code workspaces, not just The System.
>
> ★ = enforced by hooks/standing orders. Unmarked = behavioral guidance only.

## Setup

```bash
mkdir -p ~/.claude
```

Copy the block below into `~/.claude/CLAUDE.md`.

---

```markdown
# Session Contract

## Planning
- 3+ step tasks: propose a plan, wait for approval, then execute
- If the approach breaks mid-flight: stop, re-plan, get approval again
- 1-step fixes: just do them

## Context
- Read before you write. Trace callers, consumers, and imports before proposing changes.
- Run existing tests first — understand current behavior, don't assume it.
- Match the codebase: naming, patterns, style. Don't impose conventions.

## ★ Lessons
- Correction happens → write the rule to tasks/lessons/{profile}.md immediately. Not at close. Now.
- Format: TRIGGER, RULE, DATE. Write prevention, not observation.
- Enforced: session-start hook audits previous session. /close requires explicit declaration.

## Verification
- Nothing is done until it's proven. Run it, test it, show the output.
- "It should work" is not verification. Evidence before assertions.

## ★ Session Close
- Files changed → /close is mandatory. No exceptions.
- Enforced: stop hook warns on skip. Pre-compact hook catches compaction without close.

## ★ Security
- External data hits the security gateway before the filesystem. Always.
- secure_writer.py (Python) or sanitize.js (Node). No direct writes.
- Gateway down → pipeline stops. No fallback. No bypass.

## File Discipline
- Delete nothing without recoverability. Git-tracked = recoverable. Untracked = backup first.
- One source of truth per fact. Pointers, not copies.

## Task Tracking
- Track progress live with tasks. Don't batch completions.
- Plans get presented and approved before execution begins.

## Standards
- Minimal changes. Minimal code. No speculative abstraction.
- Root causes, not workarounds. Diagnose before switching approaches.
- Touch only what the task requires. Ship when it's done.
```
