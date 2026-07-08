---
name: how-to-write-a-skill
description: How to create and package skills for AI coding agents following the Agent Skills specification. Covers directory structure, SKILL.md frontmatter, progressive disclosure, optional directories (scripts, references, assets), validation, and best practices. Use when writing, reviewing, or packaging any skill.
---

# How to Write a Skill

This skill teaches you how to create a skill — a self-contained package of instructions and resources that AI coding agents can activate when a task matches its description.

## 1. Directory Structure

A skill is a directory containing, at minimum, a `SKILL.md` file:

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── ...               # Any additional files or directories
```

The directory name **must** match the `name` field in frontmatter (see below).

## 2. The `SKILL.md` File

The `SKILL.md` file must contain YAML frontmatter followed by Markdown body content.

### 2.1 Frontmatter Fields

| Field           | Required | Constraints                                                                                                       |
| --------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| `name`          | Yes      | Max 64 chars. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen. Must match the parent directory name. |
| `description`   | Yes      | Max 1024 chars. Non-empty. Describes what the skill does **and** when to use it.                                  |
| `license`       | No       | License name or reference to a bundled license file.                                                              |
| `compatibility` | No       | Max 500 chars. Indicates environment requirements (intended product, system packages, network access, etc.).      |
| `metadata`      | No       | Arbitrary key-value mapping for additional metadata (author, version, etc.).                                      |
| `allowed-tools` | No       | Space-separated string of pre-approved tools the skill may use. (Experimental)                                    |

**Minimal example:**

```markdown
---
name: my-skill
description: A description of what this skill does and when to use it.
---
```

**Full example:**

```markdown
---
name: pdf-processing
description: Extract PDF text, fill forms, merge files. Use when handling PDFs.
license: Apache-2.0
compatibility: Requires Python 3.14+ and uv
metadata:
  author: example-org
  version: "1.0"
---
```

#### `name` field rules

- Must be 1–64 characters
- Only lowercase unicode alphanumeric (`a-z`) and hyphens (`-`)
- Must not start or end with a hyphen
- Must not contain consecutive hyphens (`--`)
- Must match the parent directory name

✅ Valid: `pdf-processing`, `data-analysis`, `code-review`
❌ Invalid: `PDF-Processing` (uppercase), `-pdf` (leading hyphen), `pdf--processing` (double hyphen)

#### `description` field rules

- Must be 1–1024 characters
- Describe **both** what the skill does **and** when to use it
- Include keywords that help agents identify relevant tasks

✅ Good: `"Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction."`
❌ Poor: `"Helps with PDFs."`

### 2.2 Body Content Guidelines

After the frontmatter, write whatever helps agents perform the task effectively. Recommended sections:

- **Step-by-step instructions** — Walk through the task procedurally
- **Examples of inputs and outputs** — Show concrete before/after examples
- **Common edge cases** — Cover pitfalls and how to handle them
- **Related skills** — Cross-reference other skills at the end

Keep the main `SKILL.md` under **500 lines** (under 5000 tokens recommended). Move detailed reference material to separate files in `references/`.

## 3. Progressive Disclosure

Agents load skills in stages, pulling in more detail only as needed:

1. **Metadata** (~100 tokens): The `name` and `description` fields are loaded at startup for all skills
2. **Instructions** (< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill is activated
3. **Resources** (as needed): Files in `scripts/`, `references/`, or `assets/` are loaded only when required

Structure your skill to take advantage of this — put the most important guidance early in the body.

## 4. Optional Directories

### `scripts/`

Contains executable code that agents can run. Scripts should:

- Be self-contained or clearly document dependencies
- Include helpful error messages
- Handle edge cases gracefully

Common options: Python, Bash, JavaScript (language support depends on agent implementation).

### `references/`

Contains additional documentation that agents can read when needed:

- `REFERENCE.md` — Detailed technical reference
- `FORMS.md` — Form templates or structured data formats
- Domain-specific files (`finance.md`, `legal.md`, etc.)

Keep individual reference files focused. Agents load these on demand, so smaller files save context.

### `assets/`

Contains static resources:

- Templates (document templates, configuration templates)
- Images (diagrams, examples)
- Data files (lookup tables, schemas)

## 5. File References

When referencing other files in your skill, use relative paths from the skill root:

```markdown
See [the reference guide](references/REFERENCE.md) for details.

Run the extraction script:
scripts/extract.py
```

Keep file references one level deep from `SKILL.md`. Avoid deeply nested reference chains.

The agent will resolve relative paths against the skill directory when loading referenced files.

## 6. Validation

Use the [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) reference library to validate your skills:

```bash
skills-ref validate ./my-skill
```

This checks that your `SKILL.md` frontmatter is valid and follows all naming conventions.

Manual checks before considering a skill complete:

- [ ] `name` is lowercase, hyphen-separated, matches the directory name
- [ ] `description` clearly states what the skill does **and** when to use it
- [ ] Frontmatter YAML is valid (no syntax errors)
- [ ] Body is under 500 lines
- [ ] No deeply nested reference chains (keep to one level)
- [ ] All relative file paths resolve correctly
- [ ] Scripts have documented dependencies

## 7. Best Practices

- **Write the description for discovery**: Include keywords an agent would match against when deciding whether to activate this skill
- **Front-load the body**: Put the most important instructions early, since agents may stop reading after the first few sections
- **Use progressive disclosure**: Keep `SKILL.md` concise and push detailed reference material into `references/`
- **Cross-reference related skills**: At the end of the body, list related skills with relative links (e.g. `[related-skill](../related-skill/SKILL.md)`)

## 8. Related Skills

- **[architecture-doc](../architecture-doc/SKILL.md)** — Writing ARCHITECTURE.md documentation for projects.
- **[documentation-practices](../documentation-practices/SKILL.md)** — General documentation conventions (docstrings, README, inline comments).
