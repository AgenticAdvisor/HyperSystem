# Folder Structure

```
workspace/
├── .claude/
│   ├── settings.json              ★ Hook wiring, permissions
│   ├── settings.local.json        Local overrides (gitignored)
│   ├── hooks/
│   │   ├── pre-bash-cwd-check.sh  ★ PreToolUse(Bash): nested-repo cwd-leak guard for git ops
│   │   ├── pre-commit-secrets.sh  ★ PreToolUse(git commit): secrets detection (30+ patterns)
│   │   ├── pre-compact-close.sh   ★ PreCompact: close-before-compact enforcement
│   │   ├── pre-tool-bash-guard.sh ★ PreToolUse(Bash): tool misuse detection (OWASP LLM06/ASI02)
│   │   ├── session-start.sh       ★ SessionStart: health check + context injection + outcome verification
│   │   ├── stop-guard.sh          ★ Stop: session close enforcement
│   │   └── track-modified.sh      ★ PostToolUse(Write|Edit): file modification tracking
│   └── skills/
│       ├── close/SKILL.md         /close — session close checklist (incl. branch-check + budget gate)
│       ├── reload/SKILL.md        /reload — refresh governance mid-session
│       ├── new-project/SKILL.md   /new-project — add a project
│       ├── archive-project/SKILL.md /archive-project — sunset a project
│       ├── health-check/SKILL.md  /health-check — governance audit
│       ├── worktree/SKILL.md      /worktree — create isolated git worktree for sprint work
│       └── {slug}-context/SKILL.md  Per-project context loaders (created during bootstrap)
│
├── CLAUDE.md                      ★ Root instructions
├── HANDOFF.json                   ★ Machine-readable session handoff
├── CURRENT-SPRINT.md              ★ Active priorities
├── ARCHITECTURE.md                ★ System map and design rationale
├── FOLDER-STRUCTURE.md            This file
├── BOOTSTRAP.md                   First-run setup sequence
├── TEMPLATES.md                   File templates for bootstrap + project creation
├── TASKS.md                       Cross-session task persistence
├── .gitignore
│
├── tasks/
│   └── lessons/
│       ├── _shared.md             ★ Cross-cutting standing orders
│       ├── _coding-workflow.md    Coding sequence (code sessions only)
│       └── {profile}.md           Domain-specific lessons
│
├── tools/
│   ├── SECURITY-GATEWAY.md        ★ Sanitization rules + compliance tracker
│   ├── content_security.py        Detection engine (6-phase, 30+ vectors)
│   ├── secure_writer.py           Python gateway — sanitize + write
│   ├── sanitize.js                Node.js gateway
│   ├── _sanitize_bridge.py        Node↔Python bridge
│   ├── check-session-close.sh     Post-session governance validator
│   └── check-handoff-budget.py    HANDOFF.json summary budget enforcer (≤6 items, called from /close Step 3.5)
│
├── memory/
│   ├── INDEX.md                   One-line manifest of all memory files
│   ├── glossary.md                Terms, abbreviations, codenames
│   ├── context/
│   │   └── company.md             Organization identity
│   └── projects/
│       └── {slug}.md              Deep memory per project
│
├── executive-summary/
│   ├── EXECUTIVE_SUMMARY.md       Strategic context, metrics, portfolio
│   ├── work-changelog.md          Unified work log (all sessions)
│   └── archive/                   Session history, completed sprint items
│
├── docs/
│   ├── DESIGN-PHILOSOPHY.md       Why the system is designed this way
│   ├── SECURITY-MODEL.md          Security architecture standalone
│   ├── CUSTOMIZATION.md           How to extend the system
│   └── RECOMMENDED-USER-CONFIG.md ~/.claude/CLAUDE.md template
│
└── Projects/
    ├── {Name}/
    │   ├── PROJECT-CONTEXT.md     Session startup context (≤40 lines)
    │   ├── CHANGELOG.md           Project-specific log
    │   └── (project files)
    └── Reference/                 Archived/sunset projects
```

★ = Governance file (loaded at startup or enforced by hooks)

**Note:** HANDOFF.json, CURRENT-SPRINT.md, TASKS.md, `memory/`, `executive-summary/`, and `Projects/` are generated at bootstrap. They do not exist in the shipped repo.
