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

## Post-Work Repository Cleanup

After completing a coding project or task (the last implementation step is committed and all tests pass), check whether any uncommitted changes remain. Automated tools such as formatters, linters, or code generators often leave behind changes after the final manual commit — this section tells you how to handle them so the repository is left clean.

### 1. Check for uncommitted changes

```bash
git status
```

- If `git status` shows **nothing to commit** (working tree clean), no action is needed. You are done.
- If there are **uncommitted changes** (staged, unstaged, or untracked files), proceed to classify them below.

### 2. Classify the changes

Inspect the diff to determine what kind of changes remain:

```bash
git diff
```

If `git diff` is empty (everything is staged), also inspect the staged diff:

```bash
git diff --cached
```

#### A. Formatting / linting auto-fixes only

The diff consists entirely of changes that match what the project's formatter or linter would produce — whitespace, indentation, line breaks, import reordering, trailing commas, or other purely cosmetic adjustments. Clues:
- Only existing source files are modified (no new files, no deletions)
- The diff touches only formatting patterns (spacing, line wrapping, quotes, semicolons, trailing whitespace)
- Running the project's formatter (e.g., `ruff format`, `prettier --write`, `cargo fmt`, `gofmt -w`, `stylua`) produces an identical diff

**Action**: Commit the changes as a `style:` commit using the `conventional-commit` skill:

```bash
git add -A
git commit -m "style: Format code"
```

Verify the commit landed:

```bash
git log -1
```

#### B. Trivial / non-meaningful changes

Uncommitted changes fall into this category when they consist entirely of:
- Files that belong in `.gitignore` (build output, `__pycache__`, `node_modules`, `.ruff_cache/`, `target/`, etc.)
- Empty files, editor swap files, or lock files created by accident
- Whitespace-only changes in non-source files (generated docs, lock files, binary files)
- Files that were clearly created or modified by a tool run but are not part of the project's source

**Action**: Discard the changes and ensure the working tree is clean:

```bash
git checkout -- .           # discard unstaged changes in tracked files
git clean -fd               # remove untracked files and directories
```

If any of the files should be added to `.gitignore` to prevent recurring noise, update `.gitignore` and commit that change:

```bash
echo "path/to/file" >> .gitignore
git add .gitignore
git commit -m "chore: Add noise files to .gitignore"
```

#### C. Substantial or ambiguous changes

Any change that is **not** clearly formatting-only and **not** clearly trivial falls into this category. Examples:
- New source files that were created but never committed
- Modifications to logic, configuration, or data files
- A mix of formatting changes *and* meaningful changes in the same file
- Deletions of source files
- Changes to files that the agent does not recognize

**Action**: **Stop and ask the user.** Present the full diff (`git diff` and `git diff --cached`) and a summary of what was found. Propose what you think the right action is (e.g., "these look like an incomplete feature — should I commit or discard?"), but let the user make the final call.

### 3. Confirm clean state

After any action (commit, discard, or user direction), run one final check:

```bash
git status
```

The working tree must be clean. If it is not, diagnose why and escalate to the user.

---

## Safety Guardrails
- **No Force Pushes**: Never run `git push --force` on any branch.
- **Destructive Actions**: If you encounter a complex Git conflict you cannot resolve via a standard rebase, **stop immediately** and flag a human operator for assistance. Do not attempt manual cache purging or hard resets on remote code.