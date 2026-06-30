---
name: documentation-practices
description: Core conventions for writing project documentation — docstrings, inline comments, README files, and documentation lifecycle management. For architecture or agent-specific docs, use the companion skills. Use when writing code comments, generating project docs, or creating README files.
---

# Documentation Practices

## 1. Docstrings

### 1.1 When to Write a Docstring

Write a docstring for every **public-facing** function and every **non-trivial internal** function. A function is trivial when its name and signature make its behavior completely obvious — for example, a simple getter (`def name(self) -> str`), a `__repr__` method, or a one-line delegation to another function. For those, the docstring adds noise rather than clarity.

When in doubt, write the docstring. The cost of removing an unnecessary docstring is far lower than the cost of a missing one.

### 1.2 What to Include

A good docstring answers three questions without repeating information already visible in the signature:

| Question | What to write |
|---|---|
| **What** does this function do? | A single sentence describing the operation (active voice, imperative). |
| **What** does it return? | Describe the return value or state "Returns None" for void-like functions. |
| **What** special cases or edge behaviors exist? | Mention behavior on empty input, nulls, boundary values, or error conditions. |

**Bad:**

```python
def add(a, b):
    """Returns the sum of a and b."""
    return a + b
```

This docstring repeats the function name and signature without adding anything. Omit it.

**Good:**

```python
def merge_intervals(intervals: list[tuple[date, date]]) -> list[tuple[date, date]]:
    """Merge overlapping or touching date intervals.

    Returns a new list with all overlaps collapsed. Adjacent intervals
    (end of one equals start of the next) are also merged. The input
    order is preserved except that contained intervals are removed.
    Returns an empty list when given an empty list.
    """
```

### 1.3 Language-Specific Docstring Formats

Choose one format per project and apply it consistently. The most common conventions are:

| Language | Recommended Format | Tool |
|---|---|---|
| Python | Google style or NumPy/Sphinx | Sphinx, MkDocs, pdoc |
| TypeScript / JavaScript | JSDoc (`@param`, `@returns`) | TypeDoc |
| Rust | Rustdoc (`///`, `/// # Panics`, `/// # Errors`) | `cargo doc` |
| Go | `gofmt`-style comments on exported symbols | `go doc`, `pkgsite` |
| Ruby | YARD (`@param`, `@return`) | YARD |
| Java / Kotlin | Javadoc / KDoc (`@param`, `@return`) | Dokka, Javadoc |
| C++ | Doxygen (`\param`, `\return`) | Doxygen |

Do not include information that is already present in the language's type system or function signature (e.g., don't repeat `@param name str` in Python when the signature says `name: str`). In JSDoc-style systems where types are primarily documented in the doc comment, this rule does not apply.

### 1.4 Module-Level Docstrings

Every non-trivial module or file should have a top-level docstring explaining the module's purpose, what symbols it exports, and any side effects of importing it (e.g., logging configuration, monkey patches).

```python
"""Functions for merging overlapping date intervals.

Public API:
    merge_intervals   — collapse overlapping intervals
    flatten_intervals — remove nesting without merging
"""
```

### 1.5 Class Docstrings

Document every public class. Include:

- The class's responsibility in one sentence
- Usage pattern or lifecycle (how to construct, use, and clean up)
- Thread-safety guarantees, if any

```python
class IntervalMerger:
    """Merge overlapping date intervals for a single entity.

    Construct with an entity ID, then call .add(interval) for each
    interval. Call .result() to get the merged list. Not thread-safe.
    """
```

---

## 2. Inline Code Comments

Inline comments explain **why**, not **what**. The code itself expresses what it does; comments justify non-obvious choices.

### 2.1 When to Comment

- **Non-obvious trade-offs**: "We sort in descending order here because the API requires newest-first and paginates from the top."
- **Bug workarounds**: "Workaround for library v2.3 bug #418: call flush() twice to clear the buffer."
- **Complex algorithms**: A one-line summary of a non-trivial algorithm, potentially citing a reference.
- **Security or safety**: "This comparison is intentionally not constant-time; timing attacks are not a threat in this context."

### 2.2 When NOT to Comment

- **Obvious code**: `i += 1  # increment i by 1` — this is noise.
- **Commented-out code**: Never check in commented-out code. Delete it; version control preserves history.

### 2.3 TODO/FIXME/HACK Conventions

| Marker | Meaning |
|---|---|
| `TODO` | Something missing or incomplete (ideally with a ticket link). |
| `FIXME` | Known bug or incorrect behavior. |
| `HACK` | A brittle but expedient workaround; explain why it's acceptable. |
| `XXX` | Dangerous or fragile code; reviewer should scrutinize. |

Every marker should include a brief explanation and, where possible, a reference to a tracking issue:

```python
# TODO(#312): Handle daylight saving time transitions for timezone-aware dates.
```

---

## 3. README

### 3.1 When to Write

Write the README **iteratively during development**, not at the end. Start with a skeleton early (project purpose, how to run it) and refine it as the project grows. A README written after "coding is complete" is almost always rushed, incomplete, or skipped entirely. Finalize it before the first public release.

### 3.2 What to Include

```
project-name/
├── README.md          ← this file
├── src/               ← application / library code
└── tests/             ← test suite
```

- **Project purpose**: What problem does this solve? Who is the audience?
- **Features**: Bullet list of key capabilities. Prefer short, scannable items.
- **Quick start / installation**: Exact commands to set up and run. Test these commands before release.
- **Directory structure**: A top-level tree view with one-line descriptions for each directory or module. Do not list every file — just the logical groupings.

    ```
    src/          — application code
    tests/        — test suite (mirrors src/ structure)
    docs/         — architecture and design documents
    scripts/      — build and CI helper scripts
    ```

- **Dependencies**: Runtime dependencies (language, database, external services) and how to install them. Link to a lockfile or environment definition file (`Cargo.toml`, `pyproject.toml`, `package.json`, etc.) rather than duplicating versions.
- **How to run**: Commands for development server, tests, linting, and building.
- **Configuration**: Environment variables, config files, or CLI flags the user needs to know about.
- (Optional) **Contributing guide**: Link to `CONTRIBUTING.md` if one exists.
- (Optional) **License**: Link to `LICENSE` if one exists.

### 3.3 Maintenance

- Update the README whenever dependencies, setup steps, or the public API surface changes.
- If a README instruction is wrong, fix it in the same commit that introduced the discrepancy.
- Test the quick-start instructions at least once per release cycle.

---

## 4. AGENTS.md

For AI-assisted development, always write an `AGENTS.md` that instructs coding agents on project conventions, build commands, and safety rules. See the **[agents-doc](../agents-doc/SKILL.md)** skill for detailed conventions.

---

## 5. ARCHITECTURE Documentation

For projects spanning multiple modules or involving non-obvious design decisions, write an `docs/ARCHITECTURE.md`. See the **[architecture-doc](../architecture-doc/SKILL.md)** skill for detailed conventions.

---

## 6. Keeping Documentation Current

Documentation that is out of date is worse than no documentation at all — it actively misleads. Apply these rules to every commit:

### 6.1 Documentation Is Part of the Change

Any commit that alters a function's signature, behavior, or dependencies MUST update the corresponding docstring, README, or architecture document in the same commit. Never leave documentation cleanup as a separate follow-up task.

### 6.2 Review for Drift

During code review, check that the documentation still matches the code. If a docstring describes parameters that no longer exist or a README gives instructions that don't work, the reviewer should flag it as a blocking issue.

### 6.3 Stale Documentation

When you encounter documentation that is out of date while working on unrelated code, fix the discrepancy immediately or add a TODO comment referencing the issue. Do not defer it to a future cleanup pass.

### 6.4 Deprecation Lifecycle

When an API is deprecated:

1. Add a deprecation notice to the docstring specifying the version of deprecation and the recommended replacement.
2. Keep the deprecated function for at least one major version after deprecation.
3. Before removal, update all callers within the project.

```python
def old_api():
    """Deprecated since v2.0. Use new_api() instead."""
```

---

## 7. When Not to Document

Over-documentation is harmful — it creates maintenance burden, obscures the important comments, and wastes reader time. Skip documentation in these cases:

- **Self-documenting code**: A function named `is_valid_email(s: str) -> bool` does not need a docstring that says "Check whether a string is a valid email."
- **Trivial getters/setters**: `def name(self) -> str` — the name and return type are enough.
- **Signatures that say everything**: `def add(a: int, b: int) -> int` — the type signature is the documentation.
- **README content that duplicates --help**: If `app --help` produces clear usage output, the README can say "Run `app --help` for full options" rather than reproducing the list.

Prefer clear, intention-revealing names over comments that explain what the code does. Good naming reduces the documentation surface that needs maintenance.

---

## 8. Documentation Generation Tools

When a project is large enough to warrant generated documentation, use the ecosystem-standard tool:

| Language | Tool | Primary Source |
|---|---|---|
| Python | Sphinx, MkDocs, pdoc | Docstrings (Google / NumPy / reST) |
| Rust | `cargo doc` / rustdoc | `///` doc comments |
| TypeScript / JavaScript | TypeDoc, JSDoc | `/** */` comments |
| Go | `go doc`, `pkgsite` | Go doc comments |
| Java / Kotlin | Dokka, Javadoc | `/** */` comments |
| C / C++ | Doxygen | `/**` or `///` comments |
| Ruby | YARD | `# @param` / `# @return` |

- Run the tool as part of CI to catch malformed doc comments.
- Do not commit generated output (HTML, etc.) to the repository unless the project explicitly requires it for static hosting.
- Configure the tool to warn about missing public API documentation where appropriate.

---

## 9. Related Skills

- **[architecture-doc](../architecture-doc/SKILL.md)** — Writing ARCHITECTURE.md: system design, module maps, and decision records.
- **[agents-doc](../agents-doc/SKILL.md)** — Writing AGENTS.md: AI agent instructions for a project.
- **[review-plan](../review-plan/SKILL.md)** — Reviewing architecture documents and feature plans.
