---
name: mir-skills-install
description: Install all skills from mir-am/skills-agents-ai-coding globally for Codex, Claude Code, GitHub Copilot, and OpenCode without interactive prompts
license: MIT
metadata:
  audience: developers
  workflow: setup
  category: project-setup
---

## What I do

- Check that `npx` is available
- Install all repository skills globally for four explicit agent targets
- Report success or the install command's error

## When to use me

Use when the user wants to install this repository's skills, including newly added skills, for Codex, Claude Code, GitHub Copilot, and OpenCode. Invocation authorizes the global installation without another confirmation prompt.

## Workflow

Run this exact command after checking for `npx`:

```bash
(
set -e
if ! command -v npx >/dev/null 2>&1; then
  echo 'Error: npx not found. Install Node.js and npm, then retry.' >&2
  exit 1
fi

npx -y skills@latest add mir-am/skills-agents-ai-coding \
  -g --skill '*' -a codex claude-code github-copilot opencode -y
)
```

Keep the quoted `'*'`, both `-y` flags, global scope, and all four explicit agent targets; do not replace them with `--all`.

- On exit code `0`, report that the repository skills were installed globally for Codex, Claude Code, GitHub Copilot, and OpenCode.
- If `npx` is missing, report the prerequisite error and stop.
- On any other failure, report the exit code and command error without claiming success or silently retrying with different flags.
