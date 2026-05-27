---
name: python-dev
description: Python development conventions using uv/pixi for environment management, ruff for linting/formatting, pyright for type checking, and pytest for testing. Use when writing Python code in any project.
---

# Python Development Conventions

## Environment and Package Management (`uv`, `pixi`)
- Do not install packages into a global installation of Python. Always use virtual environments instead.
- You must use `uv` or `pixi` for all package management. Prefer `uv` for short scripts. Prefer `pixi` for more elaborate projects and packages. Do not use `pip`, `poetry`, or `conda` directly.
- To add a new package, use `pixi add <package_name>`. If it is a development dependency, use `pixi add --feature dev <package_name>`.
- Do put environment definitions, task runner aliases, and linting/testing execution arguments into `pixi.toml`.
- Do not populate `pyproject.toml` with tool settings unless a tool strictly requires it to function and cannot be configured via `pixi.toml` or CLI flags invoked by a `pixi` task.
- Always prefix execution commands with `pixi run`.
  - Example: Run the application via `pixi run python src/main.py`.

## Code Quality, Linting, Formatting (`ruff` & `pyright`)
- You must run linting and type-checking suites locally before presenting code or creating a commit.
- Linting & Formatting: Use `ruff`.
  - To check code: `pixi run ruff check .`
  - To automatically fix format/lint errors: `pixi run ruff check --fix .` and `pixi run ruff format .`
- Type Checking: Use `pyright` for static type analysis.
  - Run type checks via: `pixi run pyright`
  - Rule: Every function signature (arguments and return types) must be explicitly typed. Avoid the use of `Any` unless completely unavoidable; use `object` or generics instead.

## Testing (`pytest`)
- Always run tests using `pixi run python -m pytest`.
- Async Tests: If writing asynchronous code, use `pytest-asyncio` markers explicitly (`@pytest.mark.asyncio`).
- Place shared testing fixtures inside `tests/conftest.py`. Do not define global fixtures inside individual test files.

## Modern Python Architecture Standards
- Target the most recent stable Python version that provides all necessary stable dependencies for the project. Use modern syntax conventions:
  - Use native collection types for type hinting (e.g., `list[str]`, not `from typing import List`).
  - Use the `|` operator for union types (e.g., `str | None`, not `Optional[str]`).
- Logging: Do not use `print()` statements for application tracking. Use the standard `logging` library or an explicitly configured logger, ensuring correct log levels (`INFO`, `DEBUG`, `ERROR`).