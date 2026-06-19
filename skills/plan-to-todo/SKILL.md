---
name: plan-to-todo
description: Finds the most recently saved plan in docs/research/, reviews it for issues, and writes a step-by-step implementation plan to TODO.md where each step is a small, testable logical unit guided by the incremental-development skill. Use when a plan file has been saved to docs/research/ and you need to convert it into actionable implementation steps.
compatibility: Requires a docs/research/ directory containing at least one .md plan file.
allowed-tools: Read Bash Write Edit
---

# Plan to TODO

## Purpose

Reads the most recently saved plan from `docs/research/`, reviews it for issues, and — if no major problems are found — writes a step-by-step implementation plan to `TODO.md`. Each step is a **small, logical unit** that can be implemented, tested, and committed independently, following the principles of the **[incremental-development](../incremental-development/SKILL.md)** skill.

---

## Step 1 — Find the latest plan

Run the helper script to discover the most recently modified `.md` file in `docs/research/`:

```bash
./scripts/find-latest-plan.sh
```

Capture its output as the plan file path (e.g. `docs/research/demo-data-plan.md`).

If the script exits with an error (no `docs/research/` directory, or no `.md` files found), report the issue to the user and stop.

---

## Step 2 — Load the incremental-development skill

Before reviewing or writing anything, read the **[incremental-development](../incremental-development/SKILL.md)** skill. Its philosophy — one small, testable unit per step, implemented and committed before touching the next — must guide how you structure the TODO.md plan.

---

## Step 3 — Read the plan

Read the plan file whose path was returned by the script in Step 1.

---

## Step 4 — Review for issues

Examine the plan for the following types of problems:

- **Ambiguous or underspecified requirements** — goals stated in a way that leaves implementation direction unclear.
- **Missing dependencies** — components or data sources that the plan references but does not define or explain how to obtain.
- **Out-of-scope or contradictory elements** — requirements that conflict with each other or clearly exceed stated goals.
- **Skipped prerequisites** — steps that assume prior work (tooling, data preparation, infrastructure) that hasn't been done.
- **Unclear acceptance criteria** — no way to tell whether a step is complete.

If any major issues are found, present them to the user with suggested fixes and ask for clarification before proceeding.

---

## Step 5 — Write TODO.md

If no major issues (or after clarifications resolve them), write a step-by-step implementation plan to `TODO.md` in the project root.

### Step granularity — follow incremental-development

Each step must be a **small, logical unit** that can function and be tested on its own. Apply the following principles from the `incremental-development` skill:

- **One logical unit per step.** A step should be a single thing: a type definition, a config loader, a parser, a transformation function, a route handler. Do not bundle multiple unrelated changes.
- **Testable independently.** Every step must produce code that can be tested in isolation. If a step is too broad to test, split it.
- **Foundation before consumer.** Shared types, errors, and interfaces come first. Components that depend on them come later.
- **Data access before logic.** Readers, loaders, and parsers come before business logic that transforms data.
- **Core logic before output.** Analytical or computational modules come before formatting, writing, or reporting.
- **Wiring last.** The entry point that assembles all components is its own step, written after everything it wires together.
- **Integration tests after all implementation steps.** Cross-component tests belong in late steps after every component exists.
- **Documentation last.** README and user-facing docs are the final step.

A step that is too small is always safe; a step that is too large is hard to verify and hard to roll back. **When in doubt, split.**

### Format

```markdown
# Implementation Plan: <Plan title>

Source plan: `docs/research/<filename>.md`

| # | Step | Description | Key deliverables | Dependencies |
|---|---|---|---|---|
| 1 | <short imperative name> | <what this step accomplishes> | <files to create/modify> | <prerequisite step #s or —> |
| 2 | ... | ... | ... | ... |
```

#### Column rules

- **#** — sequential integer starting at 1.
- **Step** — short imperative noun phrase (e.g. "Add error types", "Implement config loader").
- **Description** — one sentence explaining what this step accomplishes.
- **Key deliverables** — files created or meaningfully modified in this step.
- **Dependencies** — comma-separated step numbers that must be completed first, or `—` if none.

---

## Step 6 — Load the incremental-development skill for implementation

Remind the user that the **[incremental-development](../incremental-development/SKILL.md)** skill should be activated when they begin implementing — it enforces the per-step loop (implement → test → verify → commit → stop) that matches the structure you just wrote.

---

## Step 7 — Ask the user

Ask the user if the TODO.md plan looks correct, or if they want any adjustments.
