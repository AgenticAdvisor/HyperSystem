# Design Philosophy

> Why The System is designed the way it is. For architects evaluating the governance model.

---

## 1. Deterministic Enforcement Over Instructional Compliance

LLMs forget instructions. Shell scripts don't.

The core insight: move binary enforcement into shell hooks that run before the LLM processes anything, at zero token cost. Health checks, file tracking, session close enforcement, and date alignment verification all happen deterministically. The LLM never needs to remember to do them.

This leaves judgment calls -- which profile to load, whether to activate security docs, what project context is relevant -- to the LLM, where reasoning belongs.

The boundary is clean and auditable: if the answer is binary (yes/no, pass/fail, happened/didn't), it belongs in a hook. If the answer requires context-dependent reasoning, it belongs in CLAUDE.md.

---

## 2. Four Layers, Not Three

Previous governance patterns for LLM workspaces used three layers: routing instructions, operational procedures, and knowledge bases. The System adds Layer 0 below the LLM.

Layer 0 is shell hooks wired to Claude Code lifecycle events (SessionStart, PostToolUse, Stop, PreCompact). These run in the host shell, not in the LLM context. They have zero token cost and cannot be skipped, forgotten, or misinterpreted.

With Layer 0 in place:
- Health checks are guaranteed -- SessionStart fires before the LLM sees anything.
- File tracking is automatic -- PostToolUse fires after every Write/Edit, no LLM involvement.
- Session close is enforced -- the Stop hook warns if files changed without `/close`.
- Compact triggers close -- the PreCompact hook catches context compaction without session close.

Without Layer 0, every one of these rules depends on the LLM remembering to follow it. That is not governance; it is hope.

---

## 3. Warn, Not Block

The Stop hook warns (`exit 0` with `additionalContext`) rather than blocks (`exit 2`).

Rationale: blocking frustrates developers and they disable the hook. A warning gives Claude information to act on -- it can remind the user, run the close checklist, or note the gap in context for the next session.

Defense in depth makes this safe:
- The Stop hook catches missed closes at session end.
- The PreCompact hook catches them before context compaction.
- The three-date sentinel (SessionStart) catches them next session.
- Lessons files record patterns to prevent recurrence.

Warning + sentinel + lessons is more robust than blocking alone, because blocking has a single point of failure: the developer disabling the hook.

Escalate to blocking only if chronic drift is observed in a specific workspace.

---

## 4. Lean Core, On-Demand Everything Else

CLAUDE.md loads every turn and costs tokens every turn. Target: under 1,200 tokens.

Everything that fires less than every turn lives elsewhere:
- **Skills** (loaded per-invocation): `/close`, `/new-project`, `/health-check`, `/reload`, `/archive-project`.
- **Lessons** (loaded per-session): standing orders, coding workflow, domain-specific rules.
- **Memory** (loaded on demand): project knowledge, glossary, organizational context.

The session close checklist alone is ~500 tokens. The new-project procedure is ~300. Health check is ~400. Inlining all of these into CLAUDE.md would add ~2,000 tokens to every turn -- most of which are irrelevant to most turns.

The rule: if it runs less than once per turn, it does not belong in CLAUDE.md.

---

## 5. Dual Memory with Domain Boundaries

Claude Code provides auto-memory (`MEMORY.md`) alongside the manual `memory/` directory. Rather than fight this or pick one, the system defines clear ownership:

- **Auto-memory** owns behavioral guidance: how to communicate, user preferences, interaction patterns, feedback corrections.
- **Manual memory/** owns project knowledge: organizational context, glossary, deep reference, project-specific facts.

The boundary is enforced by convention: before creating a new entry, check the other system. Duplicates across systems drift and create contradictions. A fact lives in exactly one place.

This also makes the manual memory/ portable. It can ship with a repo or be shared across workspaces. Auto-memory is workspace-local by design.

---

## 6. Git as Backup

No `_backups/` directory. No timestamped copies. No cleanup scripts.

`git checkout HEAD~1 -- path/to/file` replaces the entire backup system. The bootstrap commit is checkpoint zero. Every change after that is diffable, recoverable, and attributable.

Developers already have git. Building a parallel backup system adds complexity, creates a maintenance burden, and solves a problem that git already solves better.

The PostToolUse hook tracks every file modification automatically. Git history provides full recoverability. The system trusts git to do what git does.

---

## 7. Five Systems, No Overlap

Five task and tracking systems, each with a distinct scope:

| System | Scope | Purpose |
|--------|-------|---------|
| TodoWrite | Current session | In-session progress tracking |
| HANDOFF.json + CURRENT-SPRINT.md | Between sessions | Session state and active priorities |
| TASKS.md | Across sessions | Carry-forward items not tied to a sprint |
| tasks/lessons/ | All sessions | Reflexion loop -- why rules exist |
| work-changelog.md | All sessions | Audit trail -- what happened when |

The rule: these five never duplicate each other. If information belongs in one, it does not go in another. TodoWrite items do not get copied into TASKS.md. Lessons do not restate changelog entries. HANDOFF.json does not duplicate CURRENT-SPRINT.md priorities.

Overlap creates drift. Drift creates contradictions. Contradictions erode trust in the system. Five systems with clear boundaries are simpler than three systems with fuzzy ones.
