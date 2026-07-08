---
name: agents-doc
description: Conventions for writing AGENTS.md — a document that describes how AI coding agents should interact with a project. Use when creating or updating AGENTS.md for any codebase.
---

# Agents Documentation

## 1. What is AGENTS.md?

`AGENTS.md` is a project-level guide that instructs AI coding agents on how to work effectively within a specific codebase. It answers:

- What is this project, and what problem does it solve?
- What technologies, patterns, and conventions does it use?
- How should an agent build, test, lint, and run the project?
- What are the non-negotiable rules (security, style, commit conventions)?
- How are decisions recorded and where should an agent look for context?

Unlike `README.md` (aimed at human users) or `ARCHITECTURE.md` (aimed at human developers), `AGENTS.md` is optimized for machine consumption by AI coding agents. Be explicit, structured, and unambiguous.

## 2. When to Write

Write AGENTS.md early — preferably as part of project initialization or the first commit. It is especially important when:

- The project has specific conventions that differ from the agent's defaults (e.g., a different test framework, a non-standard project layout, a custom linting setup).
- The project has security-sensitive areas (secrets, authentication, data handling) where the agent should follow strict rules.
- Multiple agents or agent-augmented workflows interact with the same codebase.
- The project is large enough that an agent would benefit from knowing which files to read first.

## 3. What to Include

### 3.1 Project Identity

```
# Project Name

## Purpose

One or two sentences describing what this project is and whom it serves.

## Stack

- **Language**: Python 3.12
- **Framework**: FastAPI
- **Database**: PostgreSQL 16 via SQLAlchemy 2.0 (async)
- **Testing**: pytest + pytest-asyncio
- **Linting**: ruff
- **Type checking**: pyright (strict mode)
- **Package manager**: uv
```

### 3.2 Project Structure

Show the top-level directory layout with one-line descriptions. Do not list every file — just the logical groupings.

```
src/            — application package
  api/          — HTTP route handlers
  service/      — business logic layer
  storage/      — database access layer
tests/          — test suite (mirrors src/ structure)
docs/           — architecture and design documents
scripts/        — build and CI helper scripts
```

### 3.3 Build, Test, and Lint Commands

Provide exact commands the agent should run. Be precise:

```yaml
# Prefer specific, scoped commands over generic ones.
build:   uv sync --frozen
test:    uv run pytest -xvs tests/
lint:    uv run ruff check src/ tests/
typecheck: uv run pyright
clean:   rm -rf .venv && uv sync
```

### 3.4 Coding Conventions

List the project's specific conventions. Focus on what differs from language defaults:

```markdown
## Conventions

- Imports: standard library first, third-party second, local third (PEP 8).
- Error handling: use Result types from `result` library; avoid bare exceptions.
- Async: all I/O must be async; use `asyncio` for concurrency.
- Naming: `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_CASE` for constants.
- Type annotations: required on all function signatures (pyright strict mode).
- Commit messages: conventional commits (see [conventional-commit](../conventional-commit/SKILL.md)).
```

### 3.5 Security Rules

Document any rules the agent must follow when handling sensitive data:

```markdown
## Security

- Never log tokens, passwords, or PII. Use `mask_sensitive()` on all log output.
- Database credentials come from environment variables only — never from config files.
- SQL queries must use parameterized statements (SQLAlchemy ORM or text() with bind params).
- Input validation happens at the API layer via Pydantic models — never trust raw request data.
- All file uploads are scanned for malware before storage.
```

### 3.6 Documentation References

Point the agent to the other documentation files it should read:

```markdown
## Documentation

- `ARCHITECTURE.md` — system design, module map, and key decisions.
- `CONTRIBUTING.md` — human-oriented contribution workflow.
- `docs/research/*.md` — feature plans and design proposals.
```

### 3.7 Agent-Specific Instructions

Include any instructions that apply specifically to AI agents interacting with this project:

```markdown
## Agent Instructions

- When implementing a new feature, first read the relevant plan from `docs/research/`.
- Run lint + typecheck + tests before declaring a task complete.
- If a test fails, fix the code — do not modify the test unless the test is incorrect.
- Use the `documentation-practices` skill for docstrings and README conventions.
- When making architectural changes, update `ARCHITECTURE.md` in the same commit.
- Do not edit files outside `src/` and `tests/` without explicit user instruction.
```

## 4. AGENTS.md Formatting Guidelines

### 4.1 Be Machine-Friendly

- Use consistent headings and structured lists. Agents parse markdown headings to find sections.
- Prefer tables and code blocks over prose paragraphs for commands, configuration, and conventions.
- Use explicit section anchors: `[commands](#33-build-test-and-lint-commands)` for cross-references.
- Put the most important information early — agents may truncate attention on long documents.

### 4.2 Be Precise

- Avoid vague instructions like "ensure quality" — say "run `uv run pytest -xvs` and fix all failures".
- Give exact filenames and paths: "edit `src/api/routes.py`" not "edit the API routes file".
- Specify which skills the agent should load: "Use the `python-dev` and `testing-guide` skills."

### 4.3 Keep It Current

- Update AGENTS.md whenever build commands, testing frameworks, or project conventions change.
- A stale AGENTS.md misleads the agent. Fix it in the same commit that introduces the change.
- Review AGENTS.md for accuracy at least every release cycle.

## 5. Example AGENTS.md

```markdown
# Pricing Engine

## Purpose

Calculates real-time price quotes for financial instruments. Serves internal
trading desk applications via gRPC.

## Stack

- **Language**: Rust 1.80
- **Async runtime**: Tokio (multi-threaded)
- **Database**: Redis (cache), ClickHouse (analytics)
- **Testing**: cargo test + proptest
- **Linting**: cargo clippy (deny warnings)
- **Formatting**: rustfmt

## Project Structure

```

crates/
  api/      — gRPC service definitions and server
  core/     — pricing algorithms and business logic
  storage/  — cache and persistence adapters
tests/      — integration and end-to-end tests
docs/       — architecture and research documents

```

## Commands

| Action | Command |
|---|---|
| Build | `cargo build` |
| Test all | `cargo test` |
| Test single | `cargo test test_name` |
| Lint | `cargo clippy -- -D warnings` |
| Format | `cargo fmt --check` |

## Conventions

- All public items MUST have doc comments (`///`).
- Errors use `thiserror`; fallible functions return `Result<T, AppError>`.
- No `unwrap()` in production code — use `?` or context-aware error handling.
- gRPC protos live in `crates/api/proto/`; regenerate before committing changes.

## Security

- API keys come from environment variables (`.env` is gitignored).
- All price calculations are logged at `info` level; PII is never logged.
- Input validation happens at the gRPC middleware layer.

## Documentation

- `ARCHITECTURE.md` — module dependencies and data flow.
- `docs/research/` — feature plans for upcoming work.

## Agent Instructions

- Read `ARCHITECTURE.md` before making structural changes.
- Run `cargo clippy -- -D warnings` and fix all issues before committing.
- When the user asks to add a feature, first check `docs/research/` for a plan.
- Use the `rust-dev` skill for Rust-specific conventions.
- Commit messages follow conventional commits (the `conventional-commit` skill).
```

## 6. Related Skills

- **[documentation-practices](../documentation-practices/SKILL.md)** — General documentation conventions (docstrings, README, inline comments).
- **[architecture-doc](../architecture-doc/SKILL.md)** — Writing and maintaining ARCHITECTURE.md.
- **[review-plan](../review-plan/SKILL.md)** — Reviewing project plans and architecture documents.
- **[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)** — The three-stage data processing model. Reference when specifying data handling conventions in AGENTS.md.
- **[data-contracts](../data-contracts/SKILL.md)** — Data quality contracts at boundaries. Reference when specifying validation and error handling rules for agents.
- **[data-pipeline-reliability](../data-pipeline-reliability/SKILL.md)** — Production reliability practices. Reference when specifying idempotency and monitoring requirements.
- **[frontend-debug](../frontend-debug/SKILL.md)** — Local browser debugging for front-end projects. Reference in AGENTS.md to tell agents how to verify UI changes with agent-browser.
