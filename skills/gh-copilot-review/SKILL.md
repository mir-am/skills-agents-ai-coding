---
name: gh-copilot-review
description: Request a GitHub Copilot review for a pull request via gh CLI
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
  category: github-workflow
---

## What I do

- Accept a GitHub pull request URL or PR number
- Validate GitHub CLI (`gh`) access and PR visibility
- Request a standard GitHub Copilot review for the whole PR
- Return a concise result with the PR URL

## When to use me

Use this skill when the user wants to request a GitHub Copilot review on a pull request.

## Prerequisites

- GitHub CLI (`gh`) v2.88.0 or later must be installed and authenticated
- If given only a PR number, the current repository must have a GitHub `origin` remote
- The target PR must be accessible with the current GitHub credentials
- If `gh` not installed -> error: `Error: GitHub CLI not found. Install: https://cli.github.com/`
- If not authenticated -> error: `Error: Not authenticated with GitHub. Run: gh auth login`

## Input Handling

Accept either of these forms:

- Full GitHub PR URL
  - Example: `https://github.com/owner/repo/pull/123`
- PR number
  - Example: `123`

Resolution rules:

1. If input is a full PR URL, use it directly with `gh pr view <pr>`.
2. If input is a PR number, resolve the repository from `git remote get-url origin`.
3. If the input is neither a valid URL nor a PR number, error with `Error: Provide a GitHub PR URL or PR number`.

## Workflow

1. **Validate GitHub access**
   ```bash
   gh auth status
   ```

2. **Resolve PR metadata**
   - For PR URL:
     ```bash
     gh pr view <pr> --json number,title,url,author,baseRefName,headRefName
     ```
   - For PR number in current repo:
     ```bash
     git remote get-url origin
     gh pr view <number> --json number,title,url,author,baseRefName,headRefName
     ```

3. **Request Copilot review for the full PR**
   ```bash
   gh pr edit <pr> --add-reviewer @copilot

   # or, for PR number in the current repository
   gh pr edit <number> --add-reviewer @copilot
   ```

4. **Report results**
   ```text
   Requested GitHub Copilot review for PR #123.
   - Mode: Added @copilot as reviewer via gh CLI
   - PR: https://github.com/owner/repo/pull/123
   ```

## Error Handling

- Invalid input -> `Error: Provide a GitHub PR URL or PR number`
- `gh` missing -> `Error: GitHub CLI not found. Install: https://cli.github.com/`
- `gh` too old -> `Error: GitHub CLI v2.88.0+ is required for @copilot reviewer requests`
- Not authenticated -> `Error: Not authenticated with GitHub. Run: gh auth login`
- No GitHub remote for PR number mode -> `Error: No GitHub remote found. Provide a full PR URL or set origin`
- PR not found or inaccessible -> `Error: Unable to access the pull request with current GitHub credentials`
- Reviewer add failed -> `Error: Unable to add @copilot as a reviewer on this pull request`
- Copilot unavailable for repository or plan -> `Error: GitHub Copilot review is not available for this repository or account`

## Notes

- This skill requests a PR-wide Copilot review only
- Use `gh` CLI for all interactions
- This skill uses native reviewer support through `gh pr edit --add-reviewer @copilot`
- Do not use this skill for file-scoped or comment-driven Copilot prompts
