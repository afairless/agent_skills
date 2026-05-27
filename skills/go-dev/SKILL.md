---
name: go-dev
description: Go development conventions using Go modules, gofmt, golangci-lint, and idiomatic error handling. Use when writing Go code in any project.
---

# Go Development Conventions

## Tooling and Environment
- Use Go modules exclusively. All dependency modifications must be tracked via `go.mod` and `go.sum`.
- Use `go get <package_path>` to add dependencies. Always run `go mod tidy` after modifying imports to prune unused dependencies and update the build graph.
- Do not commit a `vendor/` directory unless the project configuration explicitly requires it.

## Code Quality, Linting, and Formatting
- You must run the formatting and linting pipelines locally before presenting code or generating a commit. Zero warnings or errors are permitted.
- Use the official `go fmt` tool (or `goimports` to automatically clean up import blocks). Never commit unformatted code.
- Use `golangci-lint` for comprehensive static analysis.
  - Run checks via: `golangci-lint run ./...`
  - Rule: Do not bypass lints using `nolint` directives unless a false positive is explicitly confirmed and a human grants permission.

## Idiomatic Go Architecture and Style
- Follow standard Go project layout conventions.
  - Publicly exposing packages/libraries belongs under `/pkg`.
  - Private application-specific code belongs under `/internal`.
  - Application entry points (binaries) belong under `/cmd/<binary-name>/main.go`.
- Errors are values in Go. Handle them explicitly.
  - Do not discard errors using the blank identifier (`_`). Always check `if err != nil`.
  - Do not use `panic()` or `recover()` for normal control flow or expected application errors. Reserve `panic()` strictly for unrecoverable system states (e.g., failed critical initialization).
  - Use `fmt.Errorf("context: %w", err)` to wrap upstream errors, allowing callers to query them using `errors.Is` or `errors.As`.
- Concurrency (Goroutines and Channels):
  - Leak Prevention: Every time you spawn a goroutine using the `go` keyword, you must have a deterministic plan for how and when it terminates.
  - Always accept a `context.Context` as the first argument in functions executing network, database, or asynchronous operations to ensure cancellation signals propagate properly.

## Testing (`testing` package)
- Place unit tests in the same package directory as the code being tested. The file name must append `_test.go` to the target file name (e.g., `auth.go` is tested by `auth_test.go`).
- Prefer table-driven testing layouts using structs for test cases to iterate cleanly over multiple inputs and expected outcomes.
- Run tests using `go test -v -race ./...`. The race detector (`-race`) flag must always pass with zero warnings.
- Define slim, focused interfaces at the consuming site rather than the implementing site to make mocking and unit testing easy without external mocking frameworks.

## Performance and Allocation Hygiene
- Pointers vs. Values: Pass small structs (like configuration objects) by value. Use pointers (`*`) only when the struct is large, needs to be mutated, or represents a stateful resource (e.g., a database connection pool).
- Slice and Map Pre-allocation: When the size of a slice or map is known beforehand, explicitly pre-allocate its capacity using `make([]Type, 0, capacity)` to prevent frequent, expensive memory reallocations during runtime.