---
name: testing-guide
description: General methodology for writing tests across all languages and frameworks. Covers Arrange-Act-Assert structure, unit/integration/property-based testing, the None-One-Many parameter principle, and test quality standards. Use when writing or reviewing tests in any project.
---

# Testing

- Place new tests in the `tests/` directory corresponding to the module structure (e.g., tests for `app/utils.*` go in `tests/app/test_utils.*`).
- Tests must be deterministic and free of external side effects. Always mock file systems, databases, network requests, and external APIs to guarantee reproducibility.
- Structure every test using **Arrange, Act, Assert**. Keep them visually separated.
- Write one test for one behavior. Do not combine multiple unrelated assertions into a single test block.
- Prefer explicit, specific matchers (e.g., `toBe()`, `toEqual()`) over loose type or truthy checks (e.g., `toBeTruthy()`, `isNotNull()`).
- When expecting an error, explicitly assert both the **Error Class** and the **Error Message**.
- Use object factories or fixtures instead of duplicating large payload setups between tests.
- Include a doc string for each test:
  - If the input parameters in the test are expected to produce an error, include `Invalid input` in the doc string.
  - If the input parameters in the test are valid and should not produce an error, include `Valid input` in the doc string.
  - Write one or more phrases in the doc string describing what the test is testing in a way that distinguishes it from other tests (e.g., `Tests empty list as input parameter`)

## Unit tests

- Write small, focused unit tests for a large majority of functions and other units of code whenever possible.
- Each unit test should test one thing. A unit test may assert several characteristics of that one thing. Additional things require additional unit tests.
- Do not write a test that asserts only the type of a function's result, because this would duplicate the function's type annotation. Do assert specific, correct result values, which implicitly includes the values' types.
- Test function input parameters based on the principle of "None, One, Many":
    1. None: test the input parameter for empty and/or null values.
        - For an integer or float, None values might be zero or NULL or NaN.
        - For a string, a None value is an empty string: '' or "".
        - For a type that can hold multiple elements, like a tuple or list or struct or dict, a None value is an instance of that type with zero elements.
    2. One: test the input parameter for a single value.
        - For an integer or float, One values are 1 and, if applicable, -1.
        - For a type that can hold multiple elements, like a tuple or list or struct or dict, a One value is an instance of that type with one element.
    3. Many: test the input parameter for multiple values.
        - For an integer or float, Many values are 2 or more and, if applicable, -2 or less.
        - For a type that can hold multiple elements, like a tuple or list or struct or dict, a Many value is an instance of that type with two or more elements.

## Integration tests

- Write integration tests for multiple functions or modules that form a logical unit of work.
- Write enough integration tests to cover the high-value nominal paths, primary workflows, and major failure modes.
- Do not write integration tests for complex conditional logic or input validation.

## Property-Based Testing

- Write property-based tests only when a function exhibits "invariants"—rules that must always remain true regardless of the input.
- Ideal Scenarios for Property-Based Testing:
  - Round-tripping (De/Serialization): Ensuring that `deserialize(serialize(data)) === data` holds true for all possible valid data shapes.
  - Pure Algorithmic Logic: Complex sorting, filtering, math operations, or financial calculations where the output must always satisfy a specific mathematical or logical property (e.g., a sorted list's length never changes).
  - Idempotency Operations: Verifying that calling a function multiple times yields the same result as calling it once: `f(x) === f(f(x))`.
  - State Machine Transitions: Validating that a system state cannot transition into an invalid or illegal state under any sequence of random user actions.
- Do not use Property-Based Testing for:
  - Integration tests or code involving external I/O, network requests, or database queries.
  - Simple CRUD logic or straight data-mapping operations.
  - UI or layout verification.

## Related Skills

- **[data-contracts](../data-contracts/SKILL.md)** — Testing data quality contracts: one test per constraint, verifying that contract boundaries reject invalid inputs.
- **[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)** — Testing pipeline stages in isolation with mocked upstream outputs.
- **[data-pipeline-reliability](../data-pipeline-reliability/SKILL.md)** — Property-based tests for idempotency and determinism in data pipelines.
