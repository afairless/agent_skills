---
name: git-workflow
description: Git workflow conventions covering branching strategy, pre-commit gatekeeping, commit atomicity, and safety guardrails. Use when starting a new task, preparing commits, or resolving Git workflow issues in any project.
---

# Git Workflow

## Pre-Work Repository Check

Before starting any work on an **existing** repository, verify that the workspace is in a known-good state. This is a safety gate — do not skip it even when the task seems trivial.

### 1. Check for uncommitted changes

Run `git status` and `git stash list`:

```bash
git status
git stash list
```

- If there are **staged or unstaged changes** (modifications, new files, deletions) that are not part of any open, intentional work, **stop immediately**.
- If there are **stashed changes**, note them and **stop immediately**.

State what you found to the user and propose a plan: commit the changes if they form a coherent unit, or stash/discard them if they are experimental or were left accidentally. Do **not** overwrite, discard, or commit anything without explicit user approval.

If a clean `git status` shows nothing to commit and no stashed changes, proceed.

### 2. Verify the test suite passes

Run the project's test command (e.g., `pytest`, `cargo test`, `npm test`, `go test ./...`):

```bash
# Project-dependent — use the test command configured for this project
<test command>
```

- If **all tests pass**, proceed.
- If **any test fails**, **stop immediately**. Inform the user that the pre-existing test suite has failures. Do not proceed with the planned work until the user acknowledges the failures or they are resolved.

### 3. Bad state → stop and escalate

If either check fails, communicate clearly:

1. What was found (dirty working tree, stashed changes, test failures with output).
2. A proposed plan for resolving the issue (e.g., "commit these changes as WIP, then run tests again", "stash the changes and proceed", "fix the three failing tests first").
3. Wait for user input. Do not make any changes to the repo without confirmation.

---

## Branching Strategy
- **Isolation**: Create a dedicated branch for every task. Format: `agent/<short-description>` (e.g., `agent/fix-login-validation`).
- **Synchronization**: Regularly pull and rebase against the target upstream branch (`main`/`develop`) to catch integration conflicts early.

## Pre-Commit Gatekeeping
- **Validation Execution**: You must run tests and linting locally before creating a commit. Zero warnings or errors are permitted.
- **Staging Hygiene**: Review files explicitly via `git status`. Do not snapshot files or build artifacts that belong in `.gitignore`.

## Commit Standards
- **Atomicity**: Frequently commit small, incremental changes that together form one logical unit of work. Ensure that unit of work operates correctly with testing and error correction before committing.
- **Commit message format**: Use the `conventional-commit` skill for commit message formatting rules, types, and examples.

## Safety Guardrails
- **No Force Pushes**: Never run `git push --force` on any branch.
- **Destructive Actions**: If you encounter a complex Git conflict you cannot resolve via a standard rebase, **stop immediately** and flag a human operator for assistance. Do not attempt manual cache purging or hard resets on remote code.