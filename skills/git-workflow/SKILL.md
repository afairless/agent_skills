---
name: git-workflow
description: Git workflow conventions covering branching strategy, pre-commit gatekeeping, commit atomicity, and safety guardrails. Use when starting a new task, preparing commits, or resolving Git workflow issues in any project.
---

# Git Workflow

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