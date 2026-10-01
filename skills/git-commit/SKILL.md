---
name: git-commit
description: Smart git commit with branch protection, session-aware staging, and conventional commits
license: MIT
metadata:
  audience: developers
  workflow: git
  category: git-workflow
---

## What I do

- Prevent commits to main/master by auto-creating feature branches
- Stage only files created/modified in current agent session
- Generate messages following Conventional Commits 1.0.0
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

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```text
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

- Use `feat` for a new feature and `fix` for a bug fix. Other common types are `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`, and `revert`; the specification does not restrict commits to this list.
- Include a scope in parentheses when it clarifies the affected area, such as `fix(parser): handle empty input`. Omit the scope when it adds no useful context.
- Require a colon and space before the short description. Prefer lowercase types, a concise imperative description (e.g., "add", "fix"), and no trailing period. These style preferences and any project-specific length limits are separate from the specification, which imposes no 50-character limit.
- Add a body when useful to explain the change and its rationale, separated from the subject by a blank line. Separate footers from the body (or subject when there is no body) with a blank line; use trailer syntax such as `Refs: #123`.
- Mark breaking changes with `!` immediately before the colon, an uppercase `BREAKING CHANGE: <explanation>` footer, or both. Breaking changes can occur with any type. When using only `!`, describe the breaking change in the subject; use a footer for additional impact or migration guidance.

Examples:

```text
feat: add CSV export
```

```text
fix(parser): handle empty input
```

```text
feat(api)!: require authentication for exports

Protect exported data by requiring an authenticated request.

BREAKING CHANGE: anonymous exports are no longer supported. Send an access token with each export request.
```

## CI Skip Detection

1. Check if project has `AGENTS.md` file with CI skip rules
2. If rules exist, add `[skip ci]` suffix when changes only affect:
   - Documentation files (`*.md`, `README`)
   - Config files (`.gitignore`, IDE settings)
   - Non-production scripts (e.g., `benchmark/`, `scripts/`)
3. If no `AGENTS.md` or no CI rules found → do not add `[skip ci]`
4. Example with skip: `docs: update README [skip ci]`

## Final Commit Step

Execute the commit with the formatted message. For a subject-only commit:

```bash
git commit -m 'fix(parser): handle empty input'
# With CI skip when project rules allow it:
git commit -m 'docs: update installation guide [skip ci]'
```

For a body or footers, use a quoted heredoc to preserve blank lines and literal text. Adapt the message to the staged changes; omit optional sections when unnecessary. If CI skip applies, append it to the subject only.

```bash
git commit -F - <<'COMMIT_MESSAGE'
feat(api)!: require authentication for exports

Protect exported data by requiring an authenticated request.

BREAKING CHANGE: anonymous exports are no longer supported. Send an access token with each export request.
COMMIT_MESSAGE
```
