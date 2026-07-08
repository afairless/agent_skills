---
name: frontend-debug
description: Debug front-end code by running the project locally and inspecting it in a browser via agent-browser automation. Use when the user asks you to debug a UI, fix a visual issue, verify a front-end change renders correctly, check layout or component behavior, or test user-facing functionality in a browser.
---

# Front-End Debug with Agent-Browser

## When to Use This Skill

Activate this skill when any of these situations arise:

- The user asks you to debug a UI rendering issue, visual layout problem, or styling bug
- You need to verify that a front-end change you made looks correct in the browser
- The user reports a bug in the user interface and wants you to investigate
- You changed front-end code and need to confirm the component renders as expected
- The user asks you to "check the UI," "open the app," "see what this looks like," or "verify the front-end"

## Prerequisites

- The project's front-end must have a way to run locally (e.g., `npm run dev`, `pnpm dev`, `yarn dev`, etc.)
- [agent-browser](http://agent-browser.localhost) must be installed: `npm i -g agent-browser && agent-browser install`
- For detailed agent-browser usage instructions, run: `agent-browser skills get core`

## Workflow

### 1. Start the Front-End Dev Server

First, identify the correct command to start the local development server. Common patterns:

| Framework | Typical command |
|---|---|
| Next.js / React | `npm run dev` |
| Vite / Vue / Svelte | `npm run dev` |
| Angular | `npm start` or `ng serve` |
| General front-end | `npm run dev`, `npm start`, `npm run serve` |

Start the server **in the background** so you can run other commands while it's running:

```bash
npm run dev &
```

Wait a moment for the server to start, then verify it's listening (commonly on `http://localhost:3000`, `http://localhost:5173`, `http://localhost:8080`, or `http://localhost:4200`):

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
```

If a different port is expected, check the framework's default or any configuration file (e.g., `vite.config.ts`, `next.config.js`, `angular.json`).

### 2. Navigate to the Target Page with Agent-Browser

Open the page you want to inspect. If you already know the URL path (e.g., `/login`, `/dashboard`, `/settings`), navigate directly:

```bash
agent-browser open "http://localhost:3000/login"
```

If you don't know the URL path, start at the root and navigate from there:

```bash
agent-browser open "http://localhost:3000"
```

### 3. Interact and Inspect

Use agent-browser commands to explore the page, interact with elements, and gather information about the UI state:

| Goal | Command |
|---|---|
| See interactive page elements (accessibility tree) | `agent-browser snapshot -i` |
| Take a screenshot | `agent-browser screenshot debug.png` |
| Click a button or link | `agent-browser click @e<ref>` |
| Fill a form field (clear + type) | `agent-browser fill @e<ref> "text"` |
| Type into a field (no clear) | `agent-browser type @e<ref> "text"` |
| Get the page URL | `agent-browser get url` |
| Read the page title | `agent-browser get title` |
| Execute custom JS in the page | `agent-browser eval "document.title"` |
| Reload the page | `agent-browser reload` |
| Go back in history | `agent-browser back` |

> **Tip**: After a screenshot or snapshot, examine the output to identify what looks wrong. Use element refs (shown as `@eN` in snapshots) to target specific elements for clicks, fill, type operations, or further inspection.

### 4. Diagnose and Iterate

Use the information gathered from the browser to diagnose the issue:

1. **Check for page errors**: `agent-browser errors` — shows JavaScript errors, console exceptions, and network failures
2. **Check console messages**: `agent-browser console` — view console logs
3. **Check the network** for failed requests: `agent-browser network requests`
4. **Check the HTML/DOM** for unexpected structure: `agent-browser eval "document.querySelector('#root').innerHTML.substring(0, 2000)"`
5. **Verify CSS** by checking computed styles: `agent-browser eval "getComputedStyle(document.querySelector('button')).backgroundColor"`

### 5. Fix and Re-Verify

After diagnosing the issue:

1. Make the code change
2. The dev server should auto-reload (HMR). If not, restart it.
3. Use agent-browser to re-navigate to the page and verify the fix:

```bash
agent-browser reload
agent-browser snapshot -i
# or
agent-browser open "http://localhost:3000/<page>"
```

1. Confirm the visual issue is resolved.

### 6. Clean Up

When you're done, stop the dev server:

```bash
# Find the dev server process and kill it
kill %1  # if backgrounded with &
# or
pkill -f "npm run dev"
```

## Common Scenarios

### Debugging a Login Form

```bash
# Navigate to the login page
agent-browser open "http://localhost:3000/login"

# Check what's on the page (interactive elements only)
agent-browser snapshot -i

# Fill credentials (use @eN refs from snapshot)
agent-browser fill @e4 "user@example.com"
agent-browser fill @e6 "mypassword"
agent-browser click @e8

# Check what happened after submit
agent-browser snapshot -i
```

### Verifying a Component After a Fix

```bash
# Re-navigate
agent-browser open "http://localhost:3000/dashboard"
agent-browser snapshot -i

# Interact with the fixed component
agent-browser click @e12
agent-browser snapshot -i

# Optionally capture a screenshot for comparison
agent-browser screenshot dashboard-after-fix.png
```

## Related Skills

- **[testing-guide](../testing-guide/SKILL.md)** — General testing methodology. Combine automated tests with browser-based visual verification.
- **[typescript-dev](../typescript-dev/SKILL.md)** — TypeScript development conventions. Most front-end projects use TypeScript; use this skill for linting and type safety.
- **[incremental-development](../incremental-development/SKILL.md)** — Per-step implementation workflow. Browser verification fits into the "Verify" step of the loop.
- **[agents-doc](../agents-doc/SKILL.md)** — Writing AGENTS.md for projects. Recommend including browser-debugging instructions for front-end projects.
