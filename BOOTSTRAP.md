# Bootstrap

> Only run this once — on the first session with a new workspace.
> Claude: execute these steps in order. Keep it conversational.
> The user is a developer running Claude Code from the terminal.

---

## Step 0: User-Level Config

Check if `~/.claude/CLAUDE.md` exists.

- **Exists** — Great, skip ahead.
- **Missing** — Point the user to `docs/RECOMMENDED-USER-CONFIG.md`. This file contains a recommended `~/.claude/CLAUDE.md` template with sane defaults for Claude Code power users. It's recommended but not required — the system works without it.

Wait for the user to confirm they've set it up, or ask to skip.

---

## Step 0.5: Set Your Remote

Check if origin points to the template source:

```bash
git remote -v
```

If origin points to `AgenticAdvisor/HyperSystem` (the template repo):
1. Remove the template remote: `git remote remove origin`
2. Add your team's remote: `git remote add origin <your-repo-url>`
3. Push: `git push -u origin main`

If you cloned fresh and want to start clean, this is fine — just set your team's remote. This ensures your workspace doesn't accidentally push to the template source.

---

## Step 1: Gather Identity

Ask three conversational questions, one at a time:

1. **"What should I call you?"** — Name or alias.
2. **"What's your organization or role?"** — Company, team, solo dev, etc.
3. **"What projects will you be working on?"** — List the initial projects. Each gets its own folder under `Projects/`.

From the answers, infer:
- **Positioning** — one-line summary (e.g., "Solo dev building SaaS tools", "Team lead at a startup")
- **Tone** — communication style (e.g., "Direct, casual, dev-to-dev" or "Professional, detailed")
- **Design rules** — any stated preferences, or "None" if not mentioned

Present the inferred values and confirm before proceeding.

---

## Step 2: Create Folder Scaffold

```bash
mkdir -p tasks/lessons
mkdir -p tools
mkdir -p memory/context
mkdir -p memory/projects
mkdir -p executive-summary/archive
mkdir -p Projects
```

Generate a unique instance ID and write it into CLAUDE.md:

```bash
INSTANCE_ID=$(date +%s%N | sha256sum | head -c 12)
```

Replace `{INSTANCE_ID}` in CLAUDE.md with the generated value. This ID distinguishes this workspace from other clones.

---

## Step 3: Generate Core Files

Using templates from `TEMPLATES.md`, generate these files personalized with identity from Step 1:

| File | Template | Notes |
|------|----------|-------|
| `HANDOFF.json` | Handoff Template | Populated with bootstrap session data |
| `CURRENT-SPRINT.md` | Sprint Template | Initial priorities from Step 1 projects |
| `TASKS.md` | Header only | `# Tasks` + blank |
| `executive-summary/EXECUTIVE_SUMMARY.md` | Executive Summary Template | Portfolio with initial projects |
| `executive-summary/work-changelog.md` | Header only | `# Work Changelog` + first entry for bootstrap |
| `memory/INDEX.md` | Memory Index Template | All memory files listed |
| `memory/glossary.md` | Glossary Template | Starter terms |
| `memory/context/company.md` | Company Context Template | From identity answers |

**Note:** `tools/` files (`secure_writer.py`, `sanitize.js`, `content_security.py`, `_sanitize_bridge.py`) are already in place from the repo clone. Do not regenerate them.

Also write the identity values into the Memory > Identity table in CLAUDE.md, replacing the `{set during bootstrap}` placeholders.

---

## Step 4: Generate Project Context Files

For each project named in Step 1:

1. **Ask one follow-up question** — "Tell me a bit about {project}. What's it built with, and where is it at?" This gives enough context to populate the files meaningfully.

2. **Create five files per project:**

| File | Template | Purpose |
|------|----------|---------|
| `Projects/{Name}/PROJECT-CONTEXT.md` | Project Context Template | Session startup context |
| `Projects/{Name}/CHANGELOG.md` | Header only | `# Changelog — {Name}` |
| `memory/projects/{slug}.md` | Deep Memory Template | Persistent project knowledge |
| `.claude/skills/{slug}-context/SKILL.md` | Context-Loading Skill | Auto-loads project context |
| `tasks/lessons/{slug}.md` | Lessons header | Domain-specific lessons |

The **context-loading skill** template:

```yaml
---
name: {slug}-context
description: Load {project name} context. Use when working on {trigger phrases}.
user-invocable: false
allowed-tools: Read
---
```

Skill body:

```markdown
Load context for {project name}:
1. Read `Projects/{Name}/PROJECT-CONTEXT.md`
2. Read `tasks/lessons/{slug}.md` — this is your working document for this session.
   Scan for gaps: if you learn something new or get corrected, add it here immediately.
   Don't wait for session close.
3. If this session involves external data, also read `tools/SECURITY-GATEWAY.md`

Project boundary (OWASP ASI03): This session is scoped to `Projects/{Name}/`.
Do not read or modify files in other project directories unless explicitly asked.
Do not access credentials, tokens, or API keys belonging to other projects.
```

The **lessons file** starts with a header and empty rules section:

```markdown
# Lessons — {project name}
> Domain-specific lessons for {project name} sessions.

(No rules yet — lessons are added as corrections happen.)
```

**Slug convention:** lowercase, hyphens for spaces (e.g., "My App" becomes `my-app`).

---

## Step 5: Git Commit

```bash
git add -A
git commit -m "bootstrap: initialize workspace"
```

This commit is not optional. The system's recovery model is git-based (`git checkout HEAD~1`), the three-date sentinel greps committed files, and uncommitted bootstrap files create permanent noise in `git status`. This is checkpoint zero — every future change is diffable against it, and the audit trail starts here.

---

## Step 6: Verify & Welcome

Run `/health-check` silently (don't show raw output to the user unless there are issues).

Then tell the user what's now running:

- **4 hooks** — session start health checks, file modification tracking, session close enforcement, compact-before-close guard
- **5+ skills** — `/close`, `/reload`, `/new-project`, `/archive-project`, `/health-check`, plus a context-loading skill per project
- **Security layer** — all external content passes through sanitization before reaching the filesystem
- **Session continuity** — HANDOFF.json + CURRENT-SPRINT.md carry state between sessions automatically

End with: **"What do you want to work on?"**

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `sha256sum` not found (macOS) | Use `shasum -a 256` instead |
| `date +%s%N` not supported | Use `date +%s` (less entropy, still unique enough) |
| Missing tools/ files | Re-clone the repo — tools ship with the repo |
| Health check fails after bootstrap | Run `/health-check` manually and fix reported issues |

---

## What Bootstrap Does NOT Do

- Does not install dependencies (no `npm install`, no `pip install`)
- Does not modify `~/.claude/CLAUDE.md` — that's the user's file
- Does not create `.claude/hooks/` or `.claude/settings.json` — those ship with the repo
- Does not set up CI/CD, deployment, or external integrations
