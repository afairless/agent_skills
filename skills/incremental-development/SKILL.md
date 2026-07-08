---
name: incremental-development
description: "Enforce a strict implementation workflow where each step is one small, logical unit: write code and tests, verify everything passes, commit with a conventional message, and only then proceed. Use when beginning the implementation phase of any project or after completing any implementation step."
---

# Incremental Development

## Why This Skill Exists

Coding agents routinely produce all the code for an entire project at once and then commit everything in a single batch at the end. This is a poor engineering workflow — it skips testing between steps, makes rollback difficult, and hides integration problems until everything is assembled.

**This skill mandates a different approach.** You implement the project in the smallest testable units, verifying and committing each one before touching the next. No exceptions.

---

## When This Skill Activates

This skill activates when:

- **Beginning implementation** of a new project (after planning is done, before any code is written)
- **After completing any implementation step** — it kicks in again to enforce the workflow for the next step

If you are about to write code, you **must** follow the per-step loop below. Do not write code for multiple steps in a single pass.

---

## Related Skills

Read these skills for supporting conventions:

- [git-workflow](../git-workflow/SKILL.md) — branching strategy, staging hygiene, safety guardrails
- [conventional-commit](../conventional-commit/SKILL.md) — commit message format and types
- [plan-commits](../plan-commits/SKILL.md) — producing a commit-by-commit plan in `TODO.md`
- [testing-guide](../testing-guide/SKILL.md) — unit, integration, and property-based testing methodology
- [frontend-debug](../frontend-debug/SKILL.md) — Browser-based verification for front-end changes during the Verify step of the per-step loop.
- [data-pipeline-architecture](../data-pipeline-architecture/SKILL.md) — structure data processing code into distinct stages (ingestion → transformation → output)

---

## Starting a Project

When you begin implementation:

0. **Check workspace health (existing repos only).** If you are working on a repository that already has code and commits, load [git-workflow](../git-workflow/SKILL.md) and follow its **Pre-Work Repository Check** section before doing anything else. Verify the workspace is clean and all tests pass. If either check fails, stop, inform the user, and wait for instructions. Do not proceed until the repo is in a known-good state.

1. **Read the plan.** Load `TODO.md` (or produce one with `plan-commits` if it does not exist). Understand every step in sequence.

2. **Read git-workflow.** Follow its branching strategy: create a branch for the task (`agent/<short-description>`) before writing any code.

3. **Internalize the rule.** You will implement **one step at a time**, test it, verify it, commit it. You will **not** write code for step N+1 while step N is uncommitted. If you find yourself doing that, stop immediately and revert the extra changes.

---

## Per-Step Implementation Loop

For **every** step in the plan, execute this loop completely before moving on:

```
┌─────────────────────────────────────────────────────────┐
│  1. Implement  ──  code and tests for this step only    │
│  2. Test       ──  run tests, fix failures, re-run      │
│  3. Verify     ──  lint, type-check, no warnings        │
│  4. Review     ──  git status, git diff                 │
│  5. Commit     ──  conventional message, confirm        │
│  6. ⚠️ STOP    ──  do NOT start next step yet           │
└─────────────────────────────────────────────────────────┘
```

### Step 1 — Implement only this step

Write exactly the code files called for in the plan's current step. **Do not** write code belonging to future steps, even if:

- It seems trivial (e.g., a one-line function or a simple type definition)
- It feels "closely related" to the current step
- It would save you a tiny bit of time to do it now
- You are confident you'll need it later

The only exception is test scaffolding that directly tests this step's deliverables.

If you are tempted to write code for a future step, **step back**. Ask yourself: "Is the current step implemented, tested, and committed yet?" If the answer is no, you are violating the workflow.

### Step 2 — Write and run tests

Write tests appropriate for this step:

- **Unit tests** for functions with well-defined inputs and outputs
- **Property-based tests** for functions with invariants (round-trips, idempotency, ordering)
- **Smoke tests** for scaffold steps where little logic exists yet
- **Integration tests** when a step spans multiple components (use sparingly before the wiring step)

See [testing-guide](../testing-guide/SKILL.md) for detailed methodology on all test types.

Run the full test suite. Every test must pass before you proceed.

### Step 3 — Verify

Run linters, type checkers, and any other static analysis tools configured for the project. **Zero warnings, zero errors are permitted.** If any tool reports an issue, fix it before proceeding.

If the project has no linter or type checker configured, ensure at minimum that the code compiles or parses without errors.

### Step 4 — Review staged changes

Run:

```bash
git status
git diff --cached   # or git diff if nothing staged yet
```

Verify that:

- Only files belonging to the current step are changed
- No debug code, commented-out code, or temporary files are included
- No files that belong in `.gitignore` are tracked

### Step 5 — Commit

Write a [conventional commit](../conventional-commit/SKILL.md) message.

Verify the commit landed:

```bash
git log -1
```

### Step 6 — Stop and confirm

This is the most critical step. **Do not start working on the next step yet.**

Instead, explicitly state:

> **Completed:** Step N — \<logical unit description\>
> **Tests passing:** Yes/No
> **Committed:** abc123 — \<commit message\>
> **Next:** Step N+1 — \<logical unit description\>

Then begin the loop again for step N+1.

---

## Enforcement: Warning Signs

You are violating this workflow if any of the following are true:

| Symptom | What to do |
|---|---|
| You have edited files for step N+1 while step N is not yet committed | **Stop.** `git stash` the changes for step N+1. Complete step N. Pop the stash only when step N is committed. |
| You have written code for three steps without running tests once | **Stop.** Discard changes for all but the earliest uncommitted step. Test and commit that step. Repeat. |
| You are about to run one big `git add .` and commit everything at the end | **Stop.** That is exactly the anti-pattern this skill exists to prevent. Reset, pick one step, implement it properly. |
| You are planning to "clean things up in a later commit" | **Stop.** Every commit must already be clean. Do not defer cleanup. |

---

## After Every Commit

After each commit, before starting the next step, you **must** run the following check:

1. Note which step was just completed (by number and description)
2. Confirm all tests pass on this commit
3. Confirm no uncommitted changes exist (`git status` should be clean)
4. State the next step's number and description aloud
5. Begin implementing **only** that step — nothing else

This checkpoint is mandatory. Do not skip it even when the next step seems like a "trivial continuation" of the previous one.

---

## Anti-Pattern: The "One Big Commit"

The single most common failure mode this skill prevents:

```
❌ BAD:  Write all code → edit 20 files → git add . → git commit -m "Implement project"
✅ GOOD: Step 1 → test → commit → Step 2 → test → commit → ... → Step N → test → commit
```

If you ever find yourself drafting a commit message like "feat: implement X, Y, and Z" or "add whole feature", you are committing too much at once. Break it down. Each commit should be a single logical unit that could stand alone on a code review.

---

## Working with an Existing TODO.md Plan

If `TODO.md` already exists (from `plan-commits` or otherwise):

1. Read it to understand the full step sequence
2. Determine which step is next (look for the first uncommitted step)
3. Apply the Per-Step Implementation Loop to that step
4. After committing, repeat from step 2 for the next uncommitted step

Do not re-plan or reorder the steps mid-implementation unless you explicitly confirm with a human that the plan should change.
