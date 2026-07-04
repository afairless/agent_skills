---
name: security-guardrails
description: Non-negotiable security principles across all languages, frameworks, and repositories. Covers secrets management, input validation, dependency auditing, secure failure handling, and least privilege. Use when writing new code, reviewing changes, or configuring CI/build pipelines.
---

# Language-Agnostic Security Guardrails

You must adhere to these non-negotiable security principles across all languages, frameworks, and repositories. Code that violates these guardrails will be rejected immediately.

## Secrets and Credential Management

- Never hardcode API keys, passwords, bearer tokens, encryption keys, certificates, or database credentials into the source code, configuration files, or test suites.
- Access runtime configuration strictly via the environment (`process.env`, `os.environ`, `std::env`, etc.) or an approved external secrets manager.
- Ensure that any local configuration files containing actual secrets (e.g., `.env`, `config.json`) are explicitly listed in the `.gitignore` before making a commit. Only commit `.env.example` templates containing sanitized placeholder values.

## Input Validation and Sanitization (Injection Prevention)

- Treat all data originating from outside the application boundary (HTTP payloads, URL parameters, database results, file uploads, CLI arguments) as hostile.
- Never construct SQL, NoSQL, or graph database queries using string concatenation or raw string interpolation with user inputs. You must use parameterized inputs, prepared statements, or object-relational mapping (ORM) abstractions.
- Avoid executing system shell commands (`system()`, `exec()`, `popen`). If shell execution is mandatory, pass arguments as a strict array/list of arguments to the runtime's sub-process utility; never pass a raw, unescaped string to a shell interpreter.
- Before rendering untrusted input into a user interface, file export, or HTML structure, encode the output using the context-appropriate escaping mechanism to prevent Cross-Site Scripting (XSS).

## Dependency Security and Auditing

- Whenever you introduce, upgrade, or modify a third-party package or dependency, you must run the local ecosystem's security scanner (e.g., `npm audit`, `cargo audit`, `go list -m all`) to verify that the library contains no known vulnerabilities.
- Double-check package names carefully before adding them to prevent typosquatting attacks (installing a malicious package designed to mimic a popular library).
- Import only the specific modules required for the task. Avoid pulling in large, multi-purpose dependencies if a lightweight or native language feature can accomplish the goal safely.

## Secure Failures and Logging

- When handling errors and exceptions, never return raw system stack traces, database schemas, internal network paths, or underlying library errors to the end-user or API consumer. Catch exceptions and map them to sanitized, generic error responses.
- Never write sensitive data to application logs, standard output (`stdout`), or crash reports. Proactively mask or strip the following data from log payloads:
  - Plaintext passwords and authentication tokens
  - Credit card numbers or financial account details
  - Personally Identifiable Information (PII) such as emails, phone numbers, or government IDs.

## Principle of Least Privilege

- When writing code that reads or writes to the disk, restrict file access to the narrowest directory scope possible. Do not request root or administrator-level execution privileges unless explicitly authorized in the architecture design.
- Only open network ports, initiate external socket connections, or expose API routes that are strictly documented as requirements for the current feature.

## Related Skills

- **[data-contracts](../data-contracts/SKILL.md)** — Data quality contract validation at ingestion boundaries. Complements security-focused input validation with domain-level contract enforcement.
- **[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)** — The three-stage model places validation at the ingestion boundary, aligned with the principle of treating all external input as hostile.
