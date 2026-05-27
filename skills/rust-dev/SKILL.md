---
name: rust-dev
description: Rust development conventions using cargo, clippy, rustfmt, thiserror/anyhow for error handling, and idiomatic ownership/borrowing. Use when writing Rust code in any project.
---

# Rust Development Conventions

## Tooling and Environment
- Always use the toolchain specified in the project's `rust-toolchain.toml`. Do not manually alter the toolchain channel (e.g., switching to nightly) unless explicitly instructed.
- Always execute operations through Cargo:
  - Compilation: `cargo build`
  - Execution: `cargo run`
  - Testing: `cargo test`

## Code Quality, Linting, and Formatting (`clippy` & `rustfmt`)
- You must run the linting and formatting suites locally before presenting code or creating a commit. Zero warnings or errors are permitted.
- Formatting: Use `rustfmt`. Run `cargo fmt --check` to verify, and `cargo fmt` to automatically fix formatting. Never check in unformatted code.
- Linting: Use `clippy` for static analysis. Run `cargo clippy --all-targets --all-features -- -D warnings`.
  - Rule: The pipeline treats Clippy warnings as errors (`-D warnings`). Fix all lints; do not use `#[allow(...)]` attributes to bypass them unless a macro expansion conflict leaves no other alternative.

## Idiomatic Rust Architecture
- Memory Safety: `unsafe` code is strictly prohibited. You must write 100% safe, managed Rust. If you believe a task requires `unsafe`, stop and request human intervention.
- Error Handling: Avoid panicking mechanisms:
  - DO NOT use `unwrap()`, `expect()`, or `panic!()` in production application logic.
  - DO use the `Result<T, E>` and `Option<T>` types. Use the `?` operator to propagate errors up the call stack gracefully.
  - Error Libraries: Use `thiserror` for defining domain-specific, derivable errors in libraries, and `anyhow` for flexible error handling in application binaries.
- Ownership and Borrowing:
  - Prefer borrowing (`&` or `&mut`) over cloning (`.clone()`) data unnecessarily to avoid memory allocation overhead.
  - Only implement explicit lifetimes (`'a`) when the compiler cannot automatically elide them. Keep lifetimes as narrow as possible.

## Testing Standards (`cargo test`)
- Place unit tests in the same file as the implementation code, housed inside a conditional `mod tests` module flagged with `#[cfg(test)]`.
- Place integration tests in a separate `tests/` directory at the root of the crate.
- Write runnable documentation tests inside triple-backtick blocks in your outer (`//!`) and inner (`///`) doc comments to verify examples remain valid.
- If working with asynchronous execution, use the runtime's native test attributes (e.g., `#[tokio::test]`) instead of the standard `#[test]`.

## Dependency Architecture (`Cargo.toml`)
- Always specify explicit, semantic versions for dependencies in `Cargo.toml`. Avoid using wildcard (`*`) or overly loose version constraints.
- Keep the binary lean. Disable default features (`default-features = false`) for dependencies if the project only requires a specific sub-feature.
- In a workspace environment, manage shared dependencies strictly within the root `Cargo.toml` using the `[workspace.dependencies]` table, and inherit them in sub-crates using `dependency_name = { workspace = true }`.