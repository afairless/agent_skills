# Skills

A collection of [Agent Skills](https://agentskills.io) for use with compatible AI agents.

## What this is

Each skill is a directory under `skills/` containing a `SKILL.md` file that gives an agent step-by-step instructions for a specific task. When a relevant task comes up, the agent loads the skill and follows its instructions rather than improvising from scratch. Skills produce more consistent, predictable results than prompt engineering alone.

## How to use

Point an AI agent at this repository as a skills source. The agent reads each skill's `name` and `description` at startup to know what's available, then loads the full `SKILL.md` only when a matching task arises.

To add a skill, create a new directory under `skills/` whose name matches the `name` field in its `SKILL.md` frontmatter. See `skill_specification.md` for the full format reference, including optional `scripts/`, `references/`, and `assets/` subdirectories.

