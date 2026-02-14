---
name: git-pr
description: Create GitHub pull requests with smart title and description from branch commits
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: git
  category: git-workflow
---

## What I do

- Validate feature branch has commits ahead of master/main
- Push branch to remote if needed
- Generate PR title summarizing all commits + session work (no type prefix)
- Create concise PR description with summary and 3-5 key changes
- Create GitHub PR using `gh` CLI

## When to use me

Use this skill when the user asks to create a pull request from the current feature branch.

## Prerequisites

- Must be on a feature branch (not master/main)
- Branch must have commits ahead of base branch
- GitHub CLI (`gh`) must be installed and authenticated
- If `gh` not installed → error: "GitHub CLI not found. Install: https://cli.github.com/"

## Validation Workflow

1. Check current branch: `git branch --show-current`
2. If on `master` or `main` → error message and exit
3. Check for commits ahead of base:
   - Try: `git log master..HEAD --oneline`
   - Fallback: `git log main..HEAD --oneline`
4. If no commits ahead → warn user and exit

## Push Workflow

1. Check if branch exists on remote: `git ls-remote --heads origin <branch-name>`
2. If not on remote: `git push -u origin <branch-name>`
3. If exists on remote: `git push`

## PR Title Generation

- Analyze all commit messages in the branch
- Analyze agent's session context and work completed
- Summarize into one cohesive title (no type prefix)
- If commits use conventional format (`feat:`, `fix:`), strip type prefixes
- Capitalize first letter
- Examples:
  - `Add CSV export functionality and update documentation`
  - `Resolve NPE in call graph builder`
  - `Implement parallel test execution`

## PR Description Generation

- Analyze commits, diffs, and session context
- Summarize many commits into 3-5 key points (avoid listing every commit)
- Format (only these sections):
  ```markdown
  ## Summary
  <2-3 sentence overview of what was accomplished>
  
  ## Changes
  - <key change 1>
  - <key change 2>
  - <key change 3>
  - <key change 4 (if needed)>
  - <key change 5 (if needed)>
  ```

## Base Branch Detection

- Primary: `master`
- Fallback: `main` (if master doesn't exist)
- Check: `git rev-parse --verify master 2>/dev/null && echo "master" || echo "main"`

## Create PR

Execute the pull request creation:
```bash
gh pr create --base <master-or-main> --title "<title>" --body "<description>"
```

Return the PR URL to the user.

## Error Handling

- Not on feature branch → "Error: Cannot create PR from master/main branch"
- No commits ahead → "Warning: No commits to create PR for"
- `gh` not installed → "Error: GitHub CLI not found. Install: https://cli.github.com/"
