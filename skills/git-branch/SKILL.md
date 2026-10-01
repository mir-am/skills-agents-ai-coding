---
name: git-branch
description: Create a descriptive feature branch from the repo default branch using session context and current git changes
license: MIT
metadata:
  audience: developers
  workflow: git
  category: git-workflow
---

## What I do

- Detect the repository default branch from `origin/HEAD`, then fall back to local `main`, `master`, or `develop`
- Review the current session context plus staged and unstaged git changes to infer the branch purpose
- Generate a short branch name in `<type>/<brief-description>` format
- Create and switch to the new branch while preserving local changes when safe
- Ask the user instead of guessing when the intent or safe branching base is ambiguous

## When to use me

Use this skill when the user asks to create a new git branch for the current work and wants the branch name derived from the session context and current git changes.

## Prerequisites

- `git` must be installed
- Use `git switch` when available; if the installed Git is too old to support it, use `git checkout` / `git checkout -b` instead
- The repository should have a detectable default branch from `origin/HEAD` or local `main`, `master`, or `develop`
- If the current branch is not the detected default branch and the worktree is dirty, ask the user before switching branches

## Default Branch Detection

1. Check the current branch:
   ```bash
   git branch --show-current
   ```

2. Detect the remote default branch first:
   ```bash
   default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
   default_branch="${default_branch#origin/}"
   ```

3. If the remote default branch is unavailable, fall back in this order:
   ```bash
   for candidate in main master develop; do
     if git show-ref --verify --quiet "refs/heads/$candidate"; then
       default_branch="$candidate"
       break
     fi
   done
   ```

4. If no default branch can be determined, stop and ask the user which branch should be used as the base.

## Change Analysis

1. Review the current agent session context and the user's latest request.
2. Inspect the current git-visible work:
   ```bash
   git status --short
   git diff --cached --stat
   git diff --stat
   ```
3. Prefer the user request and session goal over raw filenames when naming the branch.
4. Use changed files and diff summaries as supporting context to infer the branch type and slug.
5. If there are no local changes yet, derive the branch name from the session goal alone.

## Branch Name Generation

- **Format**: `<type>/<brief-description>`
- **Types**:
  - `feat/` for new capabilities or additions
  - `fix/` for bugs, regressions, or broken behavior
  - `docs/` for documentation-only work
  - `test/` for test-only work
  - `refactor/` for structural changes without intended behavior changes
  - `chore/` for maintenance, tooling, config, or fallback cases
- **Slug rules**:
  - Keep it lowercase and hyphenated
  - Prefer 3-5 words when possible
  - Use the session goal first, with changed files as supporting evidence
  - Avoid vague slugs like `updates` or `misc-fixes`
- **Examples**:
  - `feat/add-git-branch-skill`
  - `fix/handle-default-branch-detect`
  - `docs/update-skill-readme`

If the intent is still unclear after reviewing the session and git changes, ask the user for the branch name instead of guessing.

If the generated local branch name already exists, append a short numeric suffix until it is unique:
```bash
git show-ref --verify --quiet "refs/heads/<branch-name>"
```

## Branch Creation Workflow

1. Detect the current branch and the default branch.
2. Generate a descriptive branch name from the session context and current git changes.
3. If already on the detected default branch, create the new branch directly from the current state:
   ```bash
   git switch -c <branch-name>
   # Fallback for older Git versions:
   git checkout -b <branch-name>
   ```
   This preserves staged and unstaged changes on the new branch.

4. If on a different branch and the worktree is clean, return to the default branch first, then create the new branch:
   ```bash
   git switch <default-branch>
   # Fallback for older Git versions:
   git checkout <default-branch>

   git switch -c <branch-name>
   # Fallback for older Git versions:
   git checkout -b <branch-name>
   ```

5. If on a different branch and the worktree is dirty:
   - Do not stash, reset, or discard changes automatically
   - Ask the user whether to branch from the current state or first return to `<default-branch>`

6. After creating the branch, confirm the result:
   ```bash
   git branch --show-current
   git status --short
   ```

## Error Handling

- Could not detect default branch → "Error: Could not determine the default branch from `origin/HEAD` or local `main`/`master`/`develop`."
- Branch intent still unclear → ask the user for the desired branch name
- Dirty worktree on a non-default branch → ask before switching branches
- Branch switch/create command fails due to uncommitted changes, conflicts, or unsupported git subcommands → surface the git error and stop
- Generated branch name already exists locally → add a numeric suffix like `-2` or `-3`
- Never use destructive commands like `git reset --hard` and never discard the user's changes automatically
