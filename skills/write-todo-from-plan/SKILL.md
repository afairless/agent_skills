---
name: write-todo-from-plan
description: Reads source documents (a feature plan from docs/research/ or project architecture from docs/) and writes a step-by-step, commit-by-commit implementation plan to TODO.md. Each step is a small, testable logical unit. Use when you need to convert research or architecture documents into an actionable implementation plan.
compatibility: Requires either docs/research/*.md (existing, brownfield project with feature plan) or docs/ARCHITECTURE.md (new, greenfield project).
allowed-tools: Read Bash Write Edit
---

# Source to TODO

## Purpose

Discovers the relevant source documents — either a saved feature plan in `docs/research/` or project architecture documents in `docs/` — and turns them into a sequenced implementation plan in `TODO.md`. Each step is a **small, logical unit** that can be implemented, tested, and committed independently, following the principles of the **[incremental-development](../incremental-development/SKILL.md)** skill.

---

## Step 1 — Discover source documents

Run the discovery script. The script is located in this skill's `scripts/` directory. Resolve the path against this skill's own directory (the parent of SKILL.md), **not** the project root:

```bash
<script-dir>/scripts/find-source-docs.sh
```

Where `<script-dir>` is the absolute path to this skill's directory (where SKILL.md lives).

The script outputs two variables:

- `MODE` — either `feature` (existing project, new feature) or `greenfield` (new project, no code yet)
- `SOURCE` — path to the primary document (e.g. `docs/research/demo-data-plan.md` or `docs/ARCHITECTURE.md`)

If the script exits with an error, report the issue to the user with the suggested remedies and stop.

---

## Step 2 — Load the incremental-development skill

Read the **[incremental-development](../incremental-development/SKILL.md)** skill. Its philosophy — one small, testable unit per step, implemented and committed before touching the next — must guide how you structure the TODO.md plan.

---

## Step 3 — Read the source documents

### In feature mode

Read the single plan file at `$SOURCE`. This document describes a specific feature or change to add to an existing project.

### In greenfield mode

List the contents of `docs/` recursively. Read every file found. At minimum expect `docs/ARCHITECTURE.md`; there may also be language standards files (e.g. `docs/languages/rust.md`), API specs, data schemas, or other references.

---

## Step 4 — Understand the work

### In feature mode

Examine the plan for the following types of issues:

- **Ambiguous or underspecified requirements** — goals stated in a way that leaves implementation direction unclear.
- **Missing dependencies** — components or data sources that the plan references but does not define or explain how to obtain.
- **Out-of-scope or contradictory elements** — requirements that conflict with each other or clearly exceed stated goals.
- **Skipped prerequisites** — steps that assume prior work (tooling, data preparation, infrastructure) that hasn't been done.
- **Unclear acceptance criteria** — no way to tell whether a step is complete.

If any major issues are found, present them to the user with suggested fixes and ask for clarification before proceeding.

### In greenfield mode

Extract the following from the documents:

- **Project purpose** — one sentence describing what the software does.
- **Components** — every module, class, file, or function that must be implemented.
- **Dependencies between components** — which components import types or interfaces from others.
- **Data flow** — how data moves through the system from input to output.
- **Key types and interfaces** — shared data structures, error types, configuration shapes.
- **Output artefacts** — files, databases, APIs, or other outputs the system produces.
- **Language and toolchain** — programming language(s) and build tool(s) in use.

Then reason about the structure and the correct build order. Apply the step-ordering principles from the next section.

---

## Step 5 — Write TODO.md

Write the implementation plan to `TODO.md` in the project root.

**Always** list the source documents of the plan in `TODO.md` with the paths to the source documents relative to the project root.

### Step-ordering principles

These apply to both modes. Every step builds cleanly on all previous steps.

1. **Foundation first.** In greenfield mode: repo initialisation, toolchain config, project skeleton. In feature mode: any shared types, error types, or configuration changes.
2. **Shared types and errors before their consumers.** Any component whose types or interfaces are imported by others must appear earlier.
3. **Data access before logic.** Readers, loaders, and parsers come before business logic that transforms data.
4. **Core logic before output.** Computational modules come before formatting, writing, or reporting.
5. **Wiring last.** The entry point or orchestrator is its own step, assembled after all components it wires together.
6. **Integration tests after all implementation steps.** Cross-component tests belong after every component exists.
7. **Documentation last.** README and user-facing docs are the final step.

### Granularity

Each step must be a **small, logical unit** that can function and be tested on its own. A step is one thing: a type definition, a config loader, a parser, a transformation function, a route handler.

- **Split** when a module contains a sub-component important enough for its own write-test-verify cycle.
- **Merge** adjacent steps only when two components are too small or too tightly coupled to test independently.
- **When in doubt, split.** A step that is too small is always safe; a step that is too large is hard to verify and hard to roll back.

### Test scope for each step

For each step, determine which test types apply:

| Type | When to use |
|---|---|
| **Unit** | Functions with well-defined inputs and outputs; use for most steps. |
| **Property-based** | Invariants that must hold for all valid inputs (round-trips, idempotency, ordering). |
| **Smoke** | Skeleton or entry point compiles and starts without crashing. |
| **Integration** | Multiple components wired together; typically late-sequence. |
| **Doc tests** | Public API examples verified as executable tests (Rust, Python, etc.). |

Use `—` when no tests apply (e.g. repo setup, documentation).

### Format

```markdown
# Implementation Plan: <Title>

Source: `docs/research/<file>.md` or `docs/ARCHITECTURE.md`

| # | Commit message | Logical unit | Key deliverables | Tests |
|---|---|---|---|---|
| 1 | <type>: <short imperative description> | <noun phrase> | <files or artefacts> | <test types or —> |
| 2 | ... | ... | ... | ... |
```

**Column rules:**

- **#** — sequential integer starting at 1.
- **Commit message** — [Conventional Commits](https://www.conventionalcommits.org/) format: `feat:` for new capabilities, `fix:` for bug fixes, `refactor:` for restructuring, `test:` for tests only, `docs:` for documentation, `chore:` for tooling and setup.
- **Logical unit** — short noun phrase naming the thing being built (e.g. "Error types", "Config loader", "Data ingestion").
- **Key deliverables** — files created or meaningfully modified. Keep to one line.
- **Tests** — comma-separated test types or `—` if none.

---

## Step 6 — Ask the user

Ask the user if the TODO.md plan looks correct, or if they want any adjustments.

---

## Step 7 — Commit plan documents

If the user approves the TODO.md plan, commit TODO.md and any uncommitted plan documents to the main or master branch, or to the branch of the planned feature, if it already exists and is checked out.  If you're unsure which branch to use, ask the user.
