---
name: worktree
description: Use when the user wants to create an isolated git worktree for feature work or sprint sessions. Invoke with /worktree <branch-name> or /worktree (defaults to sprint/<today>).
user-invocable: true
allowed-tools: Bash, Read, Edit, Glob
---

# Create Worktree

Create an isolated git worktree in `.worktrees/`. Accepts an optional branch name argument.

## Steps

### 1. Parse branch name

- If argument provided (e.g., `/worktree workflow-backend`): use `sprint/<argument>` as branch, `<argument>` as directory name
- If no argument: use `sprint/<YYYY-MM-DD>` as branch, `sprint-<YYYY-MM-DD>` as directory name
- If branch already exists: report it and ask the user what to do

### 2. Verify .worktrees/ is gitignored

```bash
git check-ignore -q .worktrees 2>/dev/null
```

- If NOT ignored: add `.worktrees/` to `.gitignore`, commit, then proceed
- If ignored: proceed

### 3. Create worktree

```bash
git worktree add .worktrees/<dir-name> -b <branch-name>
```

### 4. Run project setup (if applicable)

Auto-detect from project files:
- `package.json` → `npm install`
- `requirements.txt` → `pip install -r requirements.txt`
- `pyproject.toml` → `poetry install`
- No dependency file → skip

### 5. Report

```
Worktree ready:
  Path: <full-path>
  Branch: <branch-name>
```
