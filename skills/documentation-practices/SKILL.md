---
name: documentation-practices
description: Conventions for writing project documentation, including docstrings for functions, README files, ARCHITECTURE documentation, and AGENTS documentation. Use when writing code comments, generating project docs, creating README files, or documenting system architecture and agent configurations.
---

# Documentation Practices

## Docstrings

Write a doc string for every function that describes the purpose and operation of the function. Do not repeat type annotations in the doc string, unless it is useful to describe how the function operates.

## README.md

When the coding of the project is complete, write a human-readable `README.md` in the project root. Include:

- The purpose of the project
- Its features
- Its directory and file structure
- Its dependencies
- How to run it

## docs/ARCHITECTURE.md

The `docs/ARCHITECTURE.md` file documents the system's architecture for human maintainers and AI agents. It lives at `docs/ARCHITECTURE.md` in the project root. It must never be deleted or renamed without updating every reference to it.

Include the following sections in `docs/ARCHITECTURE.md`:

### 1. Purpose and Scope

Explain what this document covers and who the audience is. State whether this is a greenfield system, a migration, or a retrofit of an existing codebase.

### 2. High-Level Architecture

Describe the overall system structure. Use one or more of the following:

- A bullet-list summary of the major components and their responsibilities
- An ASCII diagram or PlantUML block showing component relationships
- A brief narrative explaining how the pieces fit together

Avoid diving deeply into any single component at this point — that belongs in the component-specific sections or sub-documents (see *Splitting ARCHITECTURE.md* below).

### 3. Technology Stack

List the key technologies (languages, frameworks, databases, message brokers, deployment infrastructure) with a brief rationale for each choice. Include version constraints where they matter.

### 4. Component Descriptions

For each major component, describe:

- **Responsibility** — what this component does
- **Entry points** — the files, modules, or endpoints that define its public surface
- **Key data it owns or consumes** — schemas, message formats, database tables
- **Dependencies** — other components or external services it relies on
- **Lifecycle** — how it starts, runs, and shuts down (relevant for services/daemons)

### 5. Data Flow

Describe the critical paths through the system. For each major flow (e.g., user signup, report generation, API request):

- The initiating event or trigger
- The sequence of components involved, in order
- The shape of data as it moves between components (include key fields or message types)
- Error / failure paths and how they are handled

Use numbered lists or sequence diagrams for complex flows.

### 6. Key Design Decisions and Trade-offs

Record architecture decisions that new contributors (human or AI) need to understand. For each decision, describe:

- The context and the problem being solved
- The options considered
- The chosen approach and why
- The trade-offs accepted

You may embed or reference Architecture Decision Records (ADRs) from `docs/adr/` if they exist.

### 7. Security Model

Document the boundaries of trust:

- Authentication and authorization mechanisms
- How secrets are managed
- Network segmentation and firewall rules (if applicable)
- Data encryption (in transit and at rest)
- Output sanitization and injection prevention

### 8. Deployment and Operations

A brief description of how the system is built, packaged, and deployed:

- Build pipeline (CI/CD steps, artifact types)
- Infrastructure (cloud provider, container orchestration, bare metal)
- Environment configuration (env files, feature flags, secrets injection)
- Monitoring, logging, and alerting touchpoints

### Splitting ARCHITECTURE.md

If `docs/ARCHITECTURE.md` grows beyond a manageable size (roughly 300–500 lines or when any single section becomes too deep to skim), **split the detailed component documentation into separate files** so that `ARCHITECTURE.md` itself remains a broad overview.

When splitting:

1. **Keep the overview compact.** The main `ARCHITECTURE.md` should contain:
   - The *Purpose and Scope* and *High-Level Architecture* sections in full
   - A *Component Map* table listing each sub-document with its file path and a one-line summary
   - A summary of deployment architecture
   - Remaining sections trimmed to a summary paragraph each, with links to the dedicated documents

2. **Create one document per component or logical group.** The split can follow the architecture naturally. Examples of possible divisions:

   | If the system has...                | The documents might be...                           |
   |-------------------------------------|-----------------------------------------------------|
   | A front-end and a back-end          | `docs/FRONTEND.md`, `docs/BACKEND.md`               |
   | A web UI and a database layer       | `docs/WEB_UI.md`, `docs/DATABASE.md`                |
   | Microservices                       | `docs/SERVICE_AUTH.md`, `docs/SERVICE_PAYMENTS.md`, etc. |
   | A pipeline with distinct stages     | `docs/INGESTION.md`, `docs/PROCESSING.md`, `docs/OUTPUT.md` |
   | API, workers, and data store        | `docs/API.md`, `docs/WORKERS.md`, `docs/STORAGE.md` |

3. **Each component document** should follow the same *Component Descriptions* and *Data Flow* patterns described above, scoped to that component.

4. **Keep the document tree shallow.** Component documents should live directly inside `docs/` (or at most one level deeper, e.g. `docs/components/`). Cross-reference with relative paths:

   ```markdown
   See the [front-end architecture](FRONTEND.md) for UI component details.
   ```

5. **Update ARCHITECTURE.md's *Component Map* every time a component document is added, removed, or renamed.**

## AGENTS.md

The `AGENTS.md` file tells AI agents how to work with the project. It lives at `AGENTS.md` in the project root. It should be written in clear, imperative prose so that any agent can act on it without ambiguity.

If `AGENTS.md` does not exist when an agent needs it, the agent should create it as part of the initial project setup.

Include the following sections in `AGENTS.md`:

### 1. Agent Roles

List every AI agent or persona that interacts with this codebase. For each agent, describe:

- **Name** — a short identifier (e.g. "frontend-agent", "reviewer")
- **Responsibility** — what tasks this agent performs
- **Scope boundaries** — what this agent should NOT do (e.g. "the frontend agent must never modify database migrations")
- **Trigger conditions** — when this agent is active (e.g. "when a PR touches `src/ui/`")

If the project only uses a single general-purpose agent, state that explicitly and describe the full scope of work.

### 2. Project Conventions

Document any project-specific rules that agents must follow:

- Naming conventions beyond those enforced by linters
- Branch naming and commit message format
- Required file headers or license blocks
- Any language or framework idioms that are preferred or forbidden

### 3. File Patterns and Ownership

Map file patterns to the agent responsible for them:

```markdown
| Pattern                          | Owner             | Notes                        |
|----------------------------------|-------------------|------------------------------|
| `src/frontend/**`                | frontend-agent    | All UI code                  |
| `src/backend/**`                 | backend-agent     | API and business logic       |
| `src/backend/migrations/**`      | backend-agent     | DB migrations; manual review |
| `docs/ARCHITECTURE.md`           | any agent         | Must keep in sync with code  |
| `AGENTS.md`                      | any agent         | Must keep in sync with code  |
```

### 4. Handoff Protocols

Describe how agents hand off work to each other. This is critical when multiple agents collaborate on the same project:

- **Inter-agent communication** — which channel or tool agents use (e.g. intercom, shared files, commit messages)
- **Handoff triggers** — what event causes a handoff (e.g. "when the backend agent finishes an API endpoint, it signals the frontend agent to consume it")
- **Artifact expectations** — what each agent leaves behind for the next (e.g. "the backend agent writes an OpenAPI spec to `docs/openapi.yaml` before handing off")

### 5. Agent Instructions

Additional instructions specific to how agents should behave in this project:

- Read-before-edit rules (which files must be read before modifying)
- Approval gates (which changes need human review)
- Documentation update obligations (e.g. "any change to an API endpoint MUST update `docs/ARCHITECTURE.md`")
- Testing requirements (which test suites to run before committing)

## Language Standards Integration

When a programming language is chosen for a project, load the corresponding language skill (e.g., `python-dev`, `typescript-dev`, `rust-dev`) for project-specific coding conventions, tooling, and testing setup.
