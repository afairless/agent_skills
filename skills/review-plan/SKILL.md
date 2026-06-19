---
name: review-plan
description: >-
  Reads a project plan — either a feature plan from docs/research/ or a
  greenfield specification from docs/ARCHITECTURE.md — and performs a
  structured critical review. Use when asked to review, assess, or critique a
  saved plan document, including checking for logical inconsistencies, lack
  of detail, codebase conflicts, testing gaps, and technical errors. Designed
  to be invoked as a plan review agent.
compatibility: Requires either docs/research/*.md (feature plan) or docs/ARCHITECTURE.md (greenfield project).
allowed-tools: Read Bash Write Edit AskUserQuestion
---

# Plan Review

## Purpose

This skill drives a structured critical review of a saved project plan. It
discovers the most relevant plan automatically — either the most recent
feature plan in `docs/research/` or the greenfield specification in
`docs/ARCHITECTURE.md` — reads it, and examines it for issues: logical
inconsistencies, missing detail, architecture conflicts, testing gaps, and
technical errors. It reports findings to the user and can update the plan
with identified fixes.

---

## Step 1 — Discover the source document

Run the discovery script. The script is located in this skill's `scripts/` directory. Resolve the path against this skill's own directory (the parent of SKILL.md), **not** the project root:

```bash
<script-dir>/scripts/find-latest-plan.sh
```

Where `<script-dir>` is the absolute path to this skill's directory (where SKILL.md lives).

The script outputs two variables:

- `MODE` — either `feature` (existing project, new feature) or
  `greenfield` (new project, no code yet)
- `SOURCE` — path to the document to review
  (e.g. `docs/research/my-feature-plan.md` or `docs/ARCHITECTURE.md`)

Note the values. The `MODE` determines how you approach the review in the
steps below.

If the script exits with an error, report the issue to the user with the
suggested remedies and stop.

---

## Step 2 — Load supporting skills

Load the following skills that help you assess the plan from different angles.
Read each skill's `SKILL.md` to understand its guidance.

| Skill | Why load it |
| --- | --- |
| **[documentation-practices](../documentation-practices/SKILL.md)** | Check whether the plan's docstring and documentation recommendations are sound. |
| **[testing-guide](../testing-guide/SKILL.md)** | Assess whether the plan's testing coverage is adequate and follows good methodology. |
| **[security-guardrails](../security-guardrails/SKILL.md)** | Identify any security concerns or missing security considerations in the plan. |
| **[incremental-development](../incremental-development/SKILL.md)** | Evaluate whether the plan's steps are small, testable, and logically ordered. |

---

## Step 3 — Read the source document

Read the file at `$SOURCE`.

### Feature plan

The source is a specific feature plan describing a change to add to an
existing project.

### Greenfield architecture spec

The source is `docs/ARCHITECTURE.md`, the project architecture specification
for a new project with no code yet. There may also be additional files in
`docs/` (language standards, API specs, data schemas). If `MODE=greenfield`,
list the contents of `docs/` recursively and read every file found.

---

## Step 4 — Understand the project architecture

To assess whether the plan conflicts with the project's design, explore the
codebase or specification:

### Existing codebase (feature mode)

There is existing code to compare against. Explore the project:

- Read `docs/ARCHITECTURE.md` if it exists.
- Read `README.md` if it exists.
- List the project's top-level source directories to understand its
  structure.

### Specification only (greenfield mode)

There is no code yet. The source document(s) from Step 3 are the
design itself. Focus your review on the architecture specification's own
internal consistency, completeness, and feasibility.

---

## Step 5 — Perform the critical review

Examine the plan for the following categories of issues. Keep notes on
anything you find.

### 5.1 — Logical inconsistencies and contradictions

- Does the plan contradict itself in different sections?
- Are there contradictory requirements or acceptance criteria?
- Does the plan suggest approaches that conflict with each other?

### 5.2 — Lack of detail

- Are there underspecified requirements that leave implementation direction unclear?
- Are data structures, interfaces, or APIs described only vaguely?
- Are acceptance criteria missing or too vague to verify?
- Are error handling and edge cases mentioned or ignored?

### 5.3 — Architecture conflicts

**Feature mode (existing project):**

- Does the plan propose patterns, libraries, or structures that conflict
  with what the project already uses?
- Does it reference modules, data sources, or dependencies that don't exist
  or aren't explained?
- Does it duplicate existing functionality?

**Greenfield mode (new project):**

- Are the proposed architectural decisions internally consistent?
- Do the components, data flows, and interfaces form a coherent whole?
- Are there any design contradictions or impossible-to-satisfy constraints?

### 5.4 — Inadequate testing coverage

- Based on the testing-guide skill, are the plan's test categories appropriate?
- Are there gaps (missing unit tests, no integration tests, no
  property-based tests where they'd be valuable)?
- Does the plan skip testing for error paths or edge cases?

### 5.5 — Overlooked issues and problems

- Security concerns (refer to the security-guardrails skill).
- Missing error handling, logging, or observability.
- Performance implications for large inputs or high traffic.
- Missing configuration, environment setup, or migration steps.
- Dependencies that need to be added or version bumps required.

### 5.6 — Step ordering (from incremental-development skill)

- Are the plan's steps ordered so that each builds cleanly on prior steps?
- Are any steps too large to be a single logical, testable unit?
- Are shared types and interfaces defined before their consumers?

### 5.7 — Technical errors

- Incorrect API usage, wrong function signatures, type mismatches.
- Misunderstanding of language or framework features.
- Impossible or circular dependency ordering.
- Syntax errors in any code snippets included in the plan.

---

## Step 6 — Report findings and ask for clarifications

Present your findings to the user concisely. For each issue found, state:

1. **Category** (which of the above it falls under)
2. **Location** (section, step, or line in the plan)
3. **The issue** (what's wrong)
4. **Suggested fix** (how the plan should be updated)

After presenting findings, ask the user for any needed clarifications and
whether they'd like you to update the plan with the identified fixes.
