# The System

> Session discipline, security enforcement, and knowledge capture for Claude Code — out of the box.

## The Problem

Claude Code is powerful. It's also stateless. Every session starts from zero. Your team's hard-won lessons vanish when the context window closes. Security enforcement is "please remember to sanitize." Session handoffs are copy-paste or nothing. And when something goes wrong, there's no audit trail to trace.

Teams using Claude Code without governance are accumulating risk they can't see:

- **Lost knowledge.** A developer learns that CORS failures are silent, or that Pydantic validates shape but not safety. That lesson lives in one conversation, then disappears. The next developer hits the same wall.
- **Inconsistent sessions.** One session closes cleanly. The next three don't. Nobody knows what was done last Tuesday. The sprint file says one thing, the handoff says another, the changelog hasn't been touched.
- **No security boundary.** External data flows into the workspace without sanitization. Prompt injection, XSS payloads, and path traversal attempts pass through unchecked because there's no enforcement layer.
- **No accountability.** Did lessons get captured? Did the session close properly? Did governance files stay in sync? Without automated checks, the answer is always "probably."

## The Solution

The System is a governance scaffold that drops into any Claude Code workspace and enforces discipline automatically. Clone it, run `claude`, answer three questions. Everything else is handled.

```bash
git clone https://github.com/AgenticAdvisor/HyperSystem.git my-workspace
cd my-workspace
claude
# Answer 3 questions. Bootstrap does the rest.
```

### What You Get

**Sessions that don't lose state.** HANDOFF.json carries machine-readable context between sessions. A three-date sentinel catches drift between the handoff, sprint, and changelog. The next session knows exactly where the last one left off.

**Lessons that actually persist.** Three-layer enforcement ensures knowledge is captured — not hoped for. The session-start hook audits the previous session's lesson coverage. The close checklist requires an explicit declaration. Context-loading skills treat lesson files as working documents, not afterthoughts.

**Security that enforces itself.** 132 defenses across content sanitization, secrets detection, and tool misuse prevention. A two-layer pipeline (detection engine + enforcement gateway) scans all external content before it reaches the filesystem. Failure mode: STOP. Never silent fallback.

**Governance you can audit.** Health checks run at session start. File budgets are enforced. Cross-references are validated. When something drifts, you know immediately — not three sessions later.

## Architecture

Four layers, each with a clear job:

```
Layer 0 — Deterministic Enforcement (shell hooks — runs before the LLM, cannot be skipped)
Layer 1 — Governance (CLAUDE.md — routing, standing orders, loaded every turn)
Layer 2 — Operations (skills + lessons — loaded per-session, zero cost when unused)
Layer 3 — Knowledge (memory + executive summary — loaded on demand, never speculatively)
```

The key insight: **Layer 0 is deterministic.** Shell hooks run before Claude processes anything. Health checks, file tracking, and session-start audits are guaranteed — not dependent on the LLM remembering to do them.

## What Ships vs. What's Generated

| Ships in the repo | Generated at bootstrap |
|---|---|
| 4 lifecycle hooks | HANDOFF.json |
| Security gateway (1,200+ lines) | CURRENT-SPRINT.md |
| 5 operational skills | EXECUTIVE_SUMMARY.md |
| Standing orders + coding workflow | work-changelog.md |
| Templates for all generated files | memory/ (index, glossary, context) |
| Architecture + folder structure docs | Projects/ (per-project files) |
| 4 enterprise docs | Per-project skills + lessons |

## Documentation

| Doc | Audience | Purpose |
|-----|----------|---------|
| `docs/DESIGN-PHILOSOPHY.md` | Architects | Why the system is designed this way |
| `docs/SECURITY-MODEL.md` | Security teams | Attack surface, trust boundaries, failure modes |
| `docs/CUSTOMIZATION.md` | Operators | How to extend: projects, hooks, skills, standing orders |
| `docs/RECOMMENDED-USER-CONFIG.md` | Developers | Optional user-level Claude Code config |

## Requirements

- Claude Code (CLI or IDE extension)
- git
- Python 3 (for security tools)

## License

MIT — see LICENSE file.
