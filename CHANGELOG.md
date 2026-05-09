# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] — 2026-05-09

### Added
- **`/worktree` skill** — creates an isolated git worktree for sprint/feature work in one command (defaults to `sprint/<today>`).
- **`pre-bash-cwd-check.sh` hook** (PreToolUse Bash) — warns when a `git` command is about to run against a *nested* repo whose toplevel differs from the workspace root. Catches the silent-wrong-remote class of bug.
- **`tools/check-handoff-budget.py`** — enforces the HANDOFF.json `summary ≤ 6 items` budget at session close. Wired into `/close` Step 3.5 with consolidate-or-rationalize prompts.
- **`.github/workflows/test.yml`** — GitHub Actions CI runs `bash test.sh` on every push and PR. SHA-pinned actions (`actions/checkout@v6.0.2`, `actions/setup-python@v6.2.0`), 5-minute job timeout, read-only `contents` permission, and `persist-credentials: false` on checkout.
- **`Known Limitations`** section in `README.md`: no automated upgrade path, single-agent trust model only, Claude Code-specific, pattern-based prompt-injection detection only.
- **Numbering convention header** in `tasks/lessons/_shared.md` and `TEMPLATES.md`: rule numbers are stable identifiers assigned in add-order; sections group rules topically. External references depend on stable numbering — never renumber.
- **Lessons-folder placement explainer** in `docs/CUSTOMIZATION.md`: documents why per-project lessons live at `tasks/lessons/{slug}.md` and how to flip the convention.

### Changed
- **All five original skills hardened** — `/close`, `/new-project`, `/archive-project`, `/health-check`, `/reload` updated with branch-aware governance writes, mandatory lesson-declaration step (Option A or B), and three-date-sentinel reconciliation guidance.
- **`pre-commit-secrets.sh`** now reads its own stdin payload and self-filters on `git commit` rather than relying on an inline shell pipeline embedded in `settings.json`. Settings file is now declarative; gating logic lives in the script.
- **`TEMPLATES.md` inline `_shared.md` template** synced to current 12-rule shape (was 10 — added Rules 11 TDD and 12 Lesson Enforcement Three-Layer that had been added to `_shared.md` directly without back-syncing the template).
- **`test.sh`** now covers all 7 hooks, 6 skills, and 7 tools (was 6 hooks, 5 skills, 6 tools). Total checks: **42** (was 38).

### Fixed
- **Skill catalog drift** between `.claude/skills/` (6 user-invocable skills shipped) and the references in `CLAUDE.md`, `README.md`, and `docs/DESIGN-PHILOSOPHY.md` (5 listed). All four sources now show 6.
- **`test.sh` hook-wiring loop** now checks `pre-bash-cwd-check` along with the other six hooks. Previously, a missing wiring entry for that hook would not fail the test suite.

## [0.1.0] — 2026-04-14

### Added
- Initial public release of The System: a governance scaffold for Claude Code workspaces.
- **Four-layer architecture**: Layer 0 deterministic enforcement (shell hooks), Layer 1 governance (`CLAUDE.md`), Layer 2 operations (skills + lessons), Layer 3 knowledge (memory + executive summary).
- **Hooks** wired to Claude Code lifecycle events: `session-start.sh` (SessionStart), `track-modified.sh` (PostToolUse Write|Edit), `stop-guard.sh` (Stop), `pre-compact-close.sh` (PreCompact), `pre-tool-bash-guard.sh` (PreToolUse Bash), `pre-commit-secrets.sh` (PreToolUse git commit).
- **Skills**: `/close`, `/new-project`, `/archive-project`, `/health-check`, `/reload`.
- **Two-layer security pipeline**: detection engine (`tools/content_security.py`) + enforcement gateway (`tools/secure_writer.py` for Python, `tools/sanitize.js` for Node). 132 named defenses covering content sanitization, secrets detection, and tool misuse prevention. Tamper-evident SHA-256 hash chain in the audit log.
- **Cross-session governance**: `HANDOFF.json` machine-readable handoff, `CURRENT-SPRINT.md` priorities, three-date sentinel that detects drift between the handoff, sprint, and changelog.
- **Standing orders** in `tasks/lessons/_shared.md` (Rules 1–10), coding-workflow rules in `tasks/lessons/_coding-workflow.md`.
- **Bootstrap sequence** in `BOOTSTRAP.md` — first-run setup that personalizes `CLAUDE.md` and scaffolds the workspace.
- **Documentation**: `ARCHITECTURE.md`, `FOLDER-STRUCTURE.md`, `TEMPLATES.md`, `docs/DESIGN-PHILOSOPHY.md`, `docs/SECURITY-MODEL.md`, `docs/CUSTOMIZATION.md`, `docs/RECOMMENDED-USER-CONFIG.md`.
- **Standards alignment**: OWASP LLM Top 10 (2025), OWASP Agentic Top 10 (2025/2026), NIST AI RMF.
- **Test suite** (`test.sh`): 38 checks across content security, gateway, hook wiring, skill existence, governance files, security tools, documentation, and defense-count consistency.
- MIT License.

[Unreleased]: https://github.com/AgenticAdvisor/HyperSystem/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/AgenticAdvisor/HyperSystem/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/AgenticAdvisor/HyperSystem/releases/tag/v0.1.0
