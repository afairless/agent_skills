---
name: plan-commits
description: Reads project architecture and specification documents in docs/ and produces a step-by-step, commit-by-commit implementation plan written to TODO.md. Use when a new project has architecture and specification documents available but no code. Applies to any programming language.
compatibility: Requires a docs/ directory containing architecture and/or specification documents.
allowed-tools: Read Bash Write Edit
---

## Purpose

Read the project's specification documents, reason about the logical structure of the work, and write a sequenced implementation plan to `TODO.md`. Each step in the plan corresponds to one commit: a unit of code that can be written, tested, and verified before the next unit begins.

---

## Step 1 — Discover and read the documentation

1. List the contents of `docs/` recursively.
2. Read every file found. At minimum expect `docs/ARCHITECTURE.md`; there may also be language standards files (e.g. `docs/languages/rust.md`), API specs, data schemas, or other references.
3. From the documents extract:
   - **Project purpose** — one sentence describing what the software does.
   - **Components** — every module, class, file, or function that must be implemented.
   - **Dependencies between components** — which components import types or interfaces from others.
   - **Data flow** — how data moves through the system from input to output.
   - **Key types and interfaces** — shared data structures, error types, configuration shapes.
   - **Output artefacts** — files, databases, APIs, or other outputs the system produces.
   - **Language and toolchain** — programming language(s) and build tool(s) in use.

---

## Step 2 — Determine the commit sequence

Apply the following ordering principles to produce a sequence where every step builds cleanly on all previous steps.

### Ordering principles

1. **Foundation first.** Repository initialisation (`.gitignore`, toolchain config) and project skeleton (manifest file, entry point stub, empty module files) come before any logic. These commits establish the structure that all subsequent commits fill in.

2. **Shared types and errors before their consumers.** Any component whose types, interfaces, or error definitions are imported by other components must appear earlier in the sequence than those consumers. A module cannot be written correctly against a type that does not yet exist.

3. **Data access before logic.** Components that read, parse, or load external data (files, databases, APIs, queues) come before components that reason about or transform that data. Logic written before its inputs exist cannot be meaningfully tested.

4. **Core logic before output.** Analytical, computational, or transformation components come before components that format, write, or report results. The output layer depends on having correct values to emit.

5. **Wiring last among implementation steps.** The entry point or orchestrator that calls all other components is assembled after all components exist. This keeps each earlier commit self-contained and the final wiring commit free of new logic.

6. **Integration tests after all implementation units.** Tests that span multiple components require those components to exist first. One or more late-sequence commits may be dedicated to integration or end-to-end tests.

7. **README and user-facing documentation last.** Written once the implementation is complete and its behaviour is confirmed.

### Granularity

The default unit is one module or one class per commit. Adjust granularity by judgment:

- **Split** a module when it contains a function or sub-component important enough to deserve its own write-test-verify cycle. Example: a complex parsing function inside a loader module may warrant its own commit before the rest of the module is built.
- **Merge** adjacent steps when two components are too small or too tightly coupled to test independently. Example: a trivial constants file and its only consumer can ship together.

Prefer smaller commits when in doubt. A step that is too small is always safe; a step that is too large is hard to verify and hard to roll back.

---

## Step 3 — Determine the test scope for each step

For each step, reason about which test types are appropriate given the nature of the code being committed. Write that assessment into the Tests column. Use `—` when no tests apply (e.g. repo setup, documentation).

Consider the following test types — this list is not exhaustive:

| Type | When to use |
|---|---|
| **Unit** | A function or component with well-defined inputs and outputs; use for most implementation steps. |
| **Property-based** | A function with invariants that must hold for all valid inputs: round-trips (serialize → deserialize → original), idempotent operations, mathematical properties, sort/filter correctness. |
| **Smoke** | The skeleton or entry point compiles and starts without crashing; useful for scaffold commits where little logic exists yet. |
| **Integration** | Multiple components wired together as a subsystem; typically reserved for late-sequence steps, but can appear earlier when a natural boundary exists. |
| **Doc tests** | Public API functions whose documented examples should be verified as executable tests; use in languages that support inline doc tests (Rust, Python, etc.). |

A single step may list multiple test types if the code warrants it.

---

## Step 4 — Write TODO.md

Write the plan to `TODO.md` in the project root using this format exactly.

```markdown
# <Project title>

<One-sentence project purpose.>

**Docs:** `docs/ARCHITECTURE.md`, `docs/languages/<lang>.md`  <!-- list every doc file read -->

| # | Commit message | Logical unit | Key deliverables | Tests |
|---|---|---|---|---|
| 1 | chore: initialise repository | Repo setup | `.gitignore`, initial commit | — |
| 2 | feat: scaffold project | Project skeleton | manifest file, entry point stub, module stubs | smoke |
| 3 | ... | ... | ... | ... |
| N | docs: write README | Documentation | `README.md` | — |
```

Rules for each column:

- **#** — sequential integer starting at 1.
- **Commit message** — [Conventional Commits](https://www.conventionalcommits.org/) format: `<type>: <short imperative description>`. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
- **Logical unit** — a short noun phrase naming the thing being built (e.g. "Error types", "Config loader", "Gap-detection logic").
- **Key deliverables** — the files created or meaningfully modified in this commit, or the primary artefacts produced. Keep to one line.
- **Tests** — comma-separated list of test types from Step 3, or `—` if none.

---

## Examples

### Example: a data-pipeline project (Python)

| # | Commit message | Logical unit | Key deliverables | Tests |
|---|---|---|---|---|
| 1 | chore: initialise repository | Repo setup | `.gitignore`, `pyproject.toml` stub | — |
| 2 | feat: scaffold project | Project skeleton | `src/__init__.py`, `src/main.py` stub, module stubs | smoke |
| 3 | feat: add error types | Domain errors | `src/errors.py` — custom exception hierarchy | unit |
| 4 | feat: add config loader | Configuration | `src/config.py`, `config.example.toml` | unit |
| 5 | feat: add file reader | Data ingestion | `src/reader.py` — parse input CSVs | unit, property-based |
| 6 | feat: add transform module | Core logic | `src/transform.py` — business rules | unit, property-based |
| 7 | feat: add report writer | Output | `src/writer.py` — write output parquet | unit |
| 8 | feat: implement pipeline orchestration | Entry point | `src/main.py` — wire all modules | smoke |
| 9 | test: add integration tests | Integration | `tests/test_pipeline.py` | integration |
| 10 | docs: write README | Documentation | `README.md` | — |

### Example: a web API project (TypeScript)

| # | Commit message | Logical unit | Key deliverables | Tests |
|---|---|---|---|---|
| 1 | chore: initialise repository | Repo setup | `.gitignore`, `package.json` stub | — |
| 2 | feat: scaffold project | Project skeleton | `src/index.ts`, `tsconfig.json`, module stubs | smoke |
| 3 | feat: add domain types | Shared types | `src/types.ts` — request/response interfaces | unit |
| 4 | feat: add config module | Configuration | `src/config.ts`, `.env.example` | unit |
| 5 | feat: add database layer | Data access | `src/db.ts` — query functions | unit, integration |
| 6 | feat: add service layer | Business logic | `src/service.ts` — core rules | unit, property-based |
| 7 | feat: add route handlers | HTTP layer | `src/routes.ts` | unit, smoke |
| 8 | feat: wire application entry point | Entry point | `src/index.ts` — start server | smoke |
| 9 | test: add end-to-end tests | Integration | `tests/e2e.test.ts` | integration |
| 10 | docs: write README | Documentation | `README.md` | — |
