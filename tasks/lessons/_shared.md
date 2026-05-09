# Lessons — Shared
> Cross-cutting standing orders that apply to ALL session profiles.
> Loaded first, before any profile-specific lessons file.
>
> **Numbering convention:** rule numbers are stable identifiers assigned in the order rules were added. Sections group rules topically, so numbers may appear non-sequentially within the file (Rule 11 sits in Coding Standards between Rules 4 and 5; Rule 12 sits in Governance between Rules 9 and 10). External references (e.g., "Rule 7" in `tools/check-session-close.sh`, `.claude/skills/close/SKILL.md`, `docs/SECURITY-MODEL.md`) depend on numbers staying stable — never renumber existing rules.

## Security Baseline

### Rule 1: Sanitize All External Content
- **TRIGGER:** Any data crossing a trust boundary into the workspace
- **RULE:** All external/untrusted content must pass through `tools/secure_writer.py` (Python) or `tools/sanitize.js` (Node.js) before reaching the filesystem. No exceptions.
- **DETAIL:** See `tools/SECURITY-GATEWAY.md` for API reference and compliance table.

### Rule 2: No Silent Fallback on Security
- **TRIGGER:** Security module unavailable, import error, or sanitization failure
- **RULE:** Pipeline STOPS. Never fall back to writing unsanitized content. Surface the error to the user.

## Session Discipline

### Rule 3: Session Close Is Not Optional
- **TRIGGER:** End of any session with file changes
- **RULE:** Run all 6 steps of the Session Close Checklist (CLAUDE.md) in order. A session with file changes that skips close is a governance failure.

### Rule 4: Lessons Are Written Immediately
- **TRIGGER:** Any correction from the user during a session
- **RULE:** Write the lesson to `tasks/lessons/{profile}.md` the moment the correction happens. Don't defer to end of session.

## Coding Standards

### Rule 11: TDD Is Default for All Code
- **TRIGGER:** Any session that writes or modifies code
- **RULE:** Write failing tests before implementation. Use the `superpowers:test-driven-development` skill. Red-green-refactor, no exceptions. Trivial one-line fixes may skip if no test infrastructure exists yet.

## File Safety

### Rule 5: Never Delete Without Recoverability
- **TRIGGER:** Any file deletion, rename, or overwrite of untracked content
- **RULE:** Git-tracked files can be recovered via `git checkout`. Untracked files must get a backup copy first.

### Rule 6: No Duplicate Source of Truth
- **TRIGGER:** Creating a file that contains content already canonical elsewhere
- **RULE:** One canonical location per piece of information. Use pointers instead of copies.

## Governance

### Rule 7: HANDOFF.json and CURRENT-SPRINT.md Update Together
- **TRIGGER:** Session close step 3
- **RULE:** These two files share ~80% of the same state. Update them in a single pass. The three-date sentinel in Phase 1 detects drift.

### Rule 8: Architecture Docs Must Reflect Reality
- **TRIGGER:** Any governance file edit, or architecture/infrastructure change
- **RULE:** If ARCHITECTURE.md references a file, that file must exist. If a file is removed, update ARCHITECTURE.md.

### Rule 9: Governance Edits Trigger Consistency Check
- **TRIGGER:** Any edit to CLAUDE.md, _shared.md, ARCHITECTURE.md, FOLDER-STRUCTURE.md
- **RULE:** Run the Governance Consistency Checklist (CLAUDE.md) before returning to the user's task. Do not skip — governance edits that break cross-references cause phantom failures in later sessions.

### Rule 12: Lesson Enforcement Is Three-Layer
- **TRIGGER:** Any session that modifies project code
- **RULE:** Three enforcement layers ensure lessons are captured:
  1. **Session-start hook** audits the previous session's lesson coverage (cross-session accountability)
  2. **`/close` Step 2** requires explicit correction declaration — not advisory (auditable output)
  3. **Context-loading skills** load lessons files as working documents (structural integration)
- **DETAIL:** If session-start warns about missed lessons from a previous session, address them BEFORE starting new work. The declaration at close must be Option A (corrections logged with references) or Option B (no corrections, with justification if code was modified).

### Rule 10: Memory Systems Don't Overlap
- **TRIGGER:** Writing information to a memory file (auto-memory or manual memory/)
- **RULE:** If both auto-memory and manual memory/ exist, respect the domain boundary: auto-memory owns feedback, corrections, user preferences, and behavioral guidance. Manual memory/ owns project knowledge, org context, glossary, and deep reference. Before creating a new memory entry, check if the other system already covers it. Duplicates across memory systems drift and create contradictions.
