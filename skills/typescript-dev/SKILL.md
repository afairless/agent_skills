---
name: typescript-dev
description: TypeScript development conventions using tsc, eslint, prettier, and strict type safety architecture. Use when writing TypeScript code in any project.
---

# TypeScript Development Conventions

## Tooling and Runtime Environment

- Use the project's native package manager (`npm`, `pnpm`, or `yarn`) as specified by the lockfile (`package-lock.json`, `pnpm-lock.yaml`, or `yarn.lock`). Do not mix package managers.
- Verify type correctness locally before committing by running the TypeScript compiler in no-emit mode: `npx tsc --noEmit`.

## Code Quality, Linting, Formatting (`eslint` & `prettier`)

- You must format and lint all files locally before presenting code or generating a commit. Zero warnings or errors are permitted.
- Use `prettier`. Run `npx prettier --write .` to format files automatically.
- Use `eslint` with `@typescript-eslint/parser`. Run checks via `npm run lint` (or package equivalent).
  - Rule: Do not bypass lint rules using `/* eslint-disable */` comments unless resolving a verified compiler-level macro conflict.

## Strict Type Safety Architecture

- You must write fully typed code. The use of `any` is strictly prohibited. If a type is genuinely unknown, use `unknown` and implement type guards before interacting with the variable.
- Never use type-assertion overrides like `// @ts-ignore` or `// @ts-expect-error` to silence the compiler. Fix the underlying type mismatch instead.
- Avoid type assertions using the `as` keyword (e.g., `data as User`). Use explicit type annotations during initialization or validate data shapes at runtime.
- Never use the non-null assertion operator (`!`). If a value can be `null` or `undefined`, use optional chaining (`?.`), nullish coalescing (`??`), or an explicit `if` block condition.

## Modern TypeScript Syntax and Paradigms

- Types vs. Interfaces:
  - Use `interface` for defining public API contracts, data models, or component properties that benefit from declaration merging or extension.
  - Use `type` for unions, intersections, primitives, tuples, or complex mapped types.
- Prefer utility types like `Readonly<T>` or `readonly` arrays for function parameters where the arguments must not be mutated.
- Avoid numeric `enum`. Use string-based enums, or prefer const objects with literal types for better tree-shaking performance:

  ```typescript

const Direction = { Up: 'UP', Down: 'DOWN' } as const;
type Direction = typeof Direction[keyof typeof Direction];

```

## Related Skills

- **[frontend-debug](../frontend-debug/SKILL.md)** — Debug TypeScript front-ends in a local browser using agent-browser automation. Use after lint/type-check when a visual verification step is needed.
