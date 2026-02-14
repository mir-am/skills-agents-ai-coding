---
name: git-commit
description: Smart git commit with branch protection, session-aware staging, and conventional commits
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: git
  category: git-workflow
---

## What I do

- Prevent commits to main/master by auto-creating feature branches
- Stage only files created/modified in current agent session
- Generate conventional commit messages with proper formatting
- Auto-detect when to add `[skip ci]` based on project rules

## When to use me

Use this skill when the user asks to commit changes made during the current session.

## Branch Protection Workflow

1. Check current branch: `git branch --show-current`
2. If on `main` or `master`:
   - Analyze `git diff` and agent conversation context
   - Generate descriptive branch name (format: `<type>/<brief-description>`)
   - Examples: `feat/add-csv-export`, `fix/npe-in-builder`, `docs/update-readme`
   - If context is unclear, ask user for branch name
   - Create and switch: `git checkout -b <branch-name>`

## Staging Workflow

1. Stage only files that the agent created or modified in this session
2. Use specific file paths: `git add <file1> <file2> <file3>`
3. Show what will be committed: `git diff --cached --stat`

## Commit Message Format

- **Format**: `<type>: <description>`
- **Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- **Requirements**: Under 50 characters, no period, present tense
- **Examples**: 
  - `feat: add CSV export`
  - `fix: resolve NPE in builder`
  - `docs: update installation guide`

## CI Skip Detection

1. Check if project has `AGENTS.md` file with CI skip rules
2. If rules exist, add `[skip ci]` suffix when changes only affect:
   - Documentation files (`*.md`, `README`)
   - Config files (`.gitignore`, IDE settings)
   - Non-production scripts (e.g., `benchmark/`, `scripts/`)
3. If no `AGENTS.md` or no CI rules found → do not add `[skip ci]`
4. Example with skip: `docs: update README [skip ci]`

## Final Commit Step

Execute the commit with the formatted message:
```bash
git commit -m "<type>: <description>"
# or with CI skip if applicable:
git commit -m "<type>: <description> [skip ci]"
```
