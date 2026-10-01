---
name: mir-skills-update
description: Update globally installed skills using the Skills CLI command documented in README.md
license: MIT
metadata:
  audience: developers
  workflow: setup
  category: project-setup
---

## What I do

- Check that `npx` is available
- Run the documented command to update globally installed skills
- Report the update result or the command's error

## When to use me

Use when the user wants to update globally installed skills. Invocation authorizes the update without another confirmation prompt.

## Workflow

Run the exact README command after checking for `npx`:

```bash
(
set -e
if ! command -v npx >/dev/null 2>&1; then
  echo 'Error: npx not found. Install Node.js and npm, then retry.' >&2
  exit 1
fi

npx skills@latest update -g
)
```

- On exit code `0`, report success and summarize the command's output, including whether skills were updated or already up to date.
- If `npx` is missing, report the prerequisite error and stop.
- On any other failure, report the exit code and command error without claiming success or silently retrying with different flags.
