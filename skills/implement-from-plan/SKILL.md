---
name: implement-from-plan
description: Reads TODO.md and its referenced plan source document, performs a quick review for major issues, then implements the plan step-by-step following the incremental-development workflow. Use when a TODO.md plan already exists and you want to execute it.
compatibility: Requires TODO.md and either a feature plan in docs/research/*.md or docs/ARCHITECTURE.md (greenfield).
allowed-tools: Read Bash Write Edit AskUserQuestion
---

# Implement from Plan

## Purpose

This skill executes a plan that already exists in `TODO.md`. It reads the
plan and its source documents, does a quick sanity check for major issues,
then — if nothing looks blocked — implements every step using the
incremental-development loop: implement, test, verify, commit, repeat.

---

## Step 1 — Discover project context

Run the discovery script. Resolve the path against this skill's own
directory (the parent of SKILL.md), **not** the project root:

```bash
<script-dir>/scripts/discover.sh
```

Where `<script-dir>` is the absolute path to this skill's directory. The
script outputs:

| Variable | Meaning |
|---|---|
| `PLAN_MODE` | `feature` (add to existing project) or `greenfield` (new project) |
| `SOURCE` | Path to the plan source document |
| `LANGUAGE` | Detected language (`rust`, `python`, `typescript`, `go`, `lua`, `r`, or `unknown`) |

If the script exits with an error (no `TODO.md`, no source document found),
report the issue with suggested remedies and stop.

---

## Step 2 — Load supporting skills

Load skills that teach the implementation workflow and language conventions.

| Skill | Always? | Why |
|---|---|---|
| **[incremental-development](../incremental-development/SKILL.md)** | Always | Enforces the write-test-verify-commit loop for every step. |
| **[git-workflow](../git-workflow/SKILL.md)** | Always | Branching strategy, pre-commit checks, cleanup. |
| **[conventional-commit](../conventional-commit/SKILL.md)** | Always | Commit message format. |
| **[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)** | When data flows through stages | Ensures ingestion, transformation, and output stages are separated. |

**Language skill** — if `LANGUAGE` is a known language, load the
corresponding dev skill:

| Detected language | Skill to load |
|---|---|
| `rust` | [rust-dev](../rust-dev/SKILL.md) |
| `python` | [python-dev](../python-dev/SKILL.md) |
| `typescript` | [typescript-dev](../typescript-dev/SKILL.md) |
| `go` | [go-dev](../go-dev/SKILL.md) |
| `lua` | [lua-dev](../lua-dev/SKILL.md) |
| `r` | [r-dev](../r-dev/SKILL.md) |

If `LANGUAGE` is `unknown`, skip the language-specific skill and rely on
the existing project's own tooling conventions (e.g., `Makefile`, CI
config, `package.json` scripts).

---

## Step 3 — Read the documents

### TODO.md

Read the full `TODO.md`. Pay attention to:

- The source document it references (verify it matches `$SOURCE`)
- The step table — number, commit message type, logical unit, deliverables
- The overall sequence of steps

### Source document

Read the file at `$SOURCE`.

If `PLAN_MODE=feature`, also read `docs/ARCHITECTURE.md` if it exists, and
skim the top-level source directory layout to understand the existing
project structure.

If `PLAN_MODE=greenfield` and there are other files in `docs/`, read them
too to understand the full specification.

---

## Step 4 — Quick review for major issues

Unlike the full plan-review skill, this is a **lightweight check**. Look
only for issues that would prevent implementation from succeeding:

1. **Missing files or dependencies** — does the plan reference modules,
   data files, configs, or dependencies that don't exist and aren't
   created by any step?
2. **Unclear acceptance criteria** — is there no way to tell whether a
   step is complete?
3. **Steps too large** — does any step look like it covers multiple
   unrelated changes that should be split?
4. **Circular ordering** — does the plan try to use a type or component
   before the step that defines it?
5. **Source document still in review** — does the source document have a
   status like "Draft" or "Needs Review"? If so, ask the user before
   implementing.

If any major issue is found, **ask the user** with a concise summary and
suggested fix before proceeding. Do not start implementing.

If no major issues, proceed to implementation.

---

## Step 5 — Implement the plan

Follow the **[incremental-development](../incremental-development/SKILL.md)**
per-step loop for every step in `TODO.md`:

1. **Implement** — write code and tests for this step only. Do not write
   code for future steps.
2. **Test** — run the full test suite. All tests must pass.
3. **Verify** — run language-specific linters and type checkers (use the
   loaded language-dev skill's commands). Zero warnings.
4. **Review staged changes** — `git status` and `git diff --cached`.
5. **Commit** — write a [conventional commit](../conventional-commit/SKILL.md) message.
6. **Stop** — announce step completion, then repeat from Step 1 of the
   loop for the next step.

### Branching

Before the first implementation step, create a branch following
[git-workflow](../git-workflow/SKILL.md) conventions:

```bash
git checkout -b agent/<short-description>
```

---

## Step 6 — Report completion

When all steps are committed:

1. Run `git status` to confirm a clean working tree.
2. Run `git log --oneline` to show the chain of commits.
3. Present a summary to the user:

   ```
   Implemented: <number> steps from <plan name>
   Branch: agent/<short-description>
   Commits:
     abc123 feat: ...
     def456 fix: ...
     ...
   ```

4. Ask the user if they'd like to push the branch or open a PR.
