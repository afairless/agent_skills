---
name: lua-dev
description: Lua development conventions covering tooling, luacheck, StyLua formatting, local scoping, and the module pattern. Use when writing Lua code (including LuaJIT, Luau, or OpenResty) in any project.
---

# Lua Development Conventions

## Tooling and Environment
- Write code compliant with the target runtime engine specified in the project configurations (e.g., standard Lua 5.1/5.4, Luau, or LuaJIT/OpenResty). Do not use features from newer Lua versions unless compatibility is verified.
- Use `Luarocks` for dependency management. Ensure all required rocks are documented in the project's rockspec file.

## Code Quality, Linting, and Formatting (`luacheck` & `StyLua`)
You must format and lint all Lua files locally before presenting code or generating a commit. Zero warnings or errors are permitted.
- Use `StyLua` for code formatting. Run `stylua --check .` to verify, and `stylua .` to automatically apply project style guidelines.
- Use `luacheck` for static analysis. Run checks via `luacheck .`.
  - Pay strict attention to warnings regarding mutating global variables, unused variables, and accessing undefined fields. Fix the underlying code; do not append inline `inline luacheck: ignore` annotations without human permission.

## Scoping and Architecture Standards
- Never declare variables in the global namespace. Every variable, function, and imported module must be explicitly declared using the `local` keyword.
- To enforce local scoping boundaries, avoid implicitly initializing variables. If a variable's value is determined conditionally later, initialize it explicitly as `local var = nil`.
- Structure all source files as explicit modules. A file must instantiate a local table, assign functions to that table, and return the table at the very end.
  ```lua
  local M = {}

  function M.process_data(payload)
      -- Implementation
      return true
  end

  return M
  ```