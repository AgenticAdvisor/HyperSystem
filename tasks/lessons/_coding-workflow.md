# Coding Workflow

When any task involves writing or modifying code, follow this sequence strictly:

## 0. Triage
- Is this trivial? (1 file, obvious fix, no architectural risk)
- If yes: fix it, verify it works, done. Skip steps 1-5.
- If no: proceed through the full sequence.

## 1. Context Gathering (go wide)
- Read all relevant files, not just the one being changed
- Trace imports, callers, and consumers of the code being touched
- Run the existing code/tests to understand current behavior — don't just read
- Use subagents to explore the codebase in parallel if the surface area is large
- Check for existing tests, types, and contracts that constrain the change
- Understand the runtime environment (dependencies, versions, config)
- Note existing code style, naming conventions, and patterns — match them

## 2. Architecture Assessment
- Determine if the current architecture supports the change cleanly
- If not, propose a new architecture — don't force a square peg into a round hole
- Keep it as simple as possible (Simplicity First principle still applies)
- Flag any changes that cross module boundaries or introduce new dependencies

## 3. Low-Level Design
- Map out the data flow and control flow of the change
- Identify interfaces, function signatures, and type boundaries
- Consider edge cases, error paths, and failure modes
- Document assumptions explicitly before writing any code

## 4. Propose & Get Approval
- List every file that will be created, modified, or deleted
- Identify downstream effects: what breaks, what needs updating, what tests need changing
- Assess risk: is this a surgical fix or a sweeping refactor?
- Present the full plan: what changes, why, and what the impact is
- Wait for approval before executing

## 5. Execute (TDD — Test First)
- Write failing tests BEFORE writing implementation code
- Use the `superpowers:test-driven-development` skill for the red-green-refactor cycle
- Red: write a test that fails for the right reason
- Green: write the minimum code to make it pass
- Refactor: clean up without changing behavior
- Run tests, check logs, demonstrate correctness
- Confirm nothing downstream broke
- If verification fails: stop, diagnose, re-plan — don't patch on top of patches
