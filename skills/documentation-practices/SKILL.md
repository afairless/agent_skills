---
name: documentation-practices
description: Conventions for writing project documentation, including docstrings for functions, README files, and ARCHITECTURE documentation. Use when writing code comments, generating project docs, or creating README files.
---

# Documentation Practices

## Docstrings

Write a doc string for every function that describes the purpose and operation of the function. Do not repeat type annotations in the doc string, unless it is useful to describe how the function operates.

## README

When the coding of the project is complete, write a human-readable `README.md` in the project root. Include:
- The purpose of the project
- Its features
- Its directory and file structure
- Its dependencies
- How to run it

## Language Standards Integration

When a programming language is chosen for a project, load the corresponding language skill (e.g., `python-dev`, `typescript-dev`, `rust-dev`) for project-specific coding conventions, tooling, and testing setup.