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
- Link GitHub issue if working on one in current session
- Create GitHub PR using `gh` CLI and self-assign it to the authenticated GitHub user
- Update root `CHANGELOG.md` when present with one PR-linked unreleased bullet

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

## Assignee Resolution

- Always self-assign the PR to the authenticated GitHub CLI account
- Use `--assignee @me` with `gh pr create`
- Do not derive the assignee from local git config such as `git config user.name` or email

## Issue Linking

If the agent is working on a GitHub issue in the current session:
1. Check session context for issue number (e.g., working on issue #123)
2. Add issue reference to PR body footer:
   ```markdown
   ---
   Closes #<issue-number>
   ```

## Create PR

Execute the pull request creation:
```bash
gh pr create --base <master-or-main> --assignee @me --title "<title>" --body "<description>"
```

- If working on an issue, append `Closes #<issue-number>` to the description
- Always include `--assignee @me` so the PR is assigned to the signed-in `gh` user
- Capture the created PR number and URL for any follow-up changelog sync
- Return the PR URL to the user

## CHANGELOG.md Sync

After the PR is created, optionally sync the repository root `CHANGELOG.md`.

### When to sync

- Only if `CHANGELOG.md` exists at the repository root
- Only if `## [Unreleased]` exists exactly once
- Only if the unreleased section already contains the target subsection heading
- If any of the above checks fail, skip changelog editing without failing PR creation

### Changelog Entry Format

- Write exactly one bullet for the PR in this format:
  ```markdown
  - <high-level PR summary> (#<pr-number>)
  ```
- Keep it to one line
- Use changelog-style wording, not PR-body wording
- Focus on the high-level thing the PR does, not an implementation checklist

### Section Selection

Choose the best matching subsection under `## [Unreleased]` based on the PR's high-level purpose:

- `### Added` for new user-facing capabilities or first-time integrations
- `### Changed` for meaningful behavior changes or enhancements to existing functionality
- `### Fixed` for user-visible bug fixes
- `### Deprecated`, `### Removed`, or `### Security` when clearly applicable
- `### Misc` only when the PR is notable but does not fit the standard Keep a Changelog sections

### Update Rules

- Treat changelog state as one PR = one bullet
- If a bullet ending with `(#<pr-number>)` already exists, update that line instead of appending a second one
- If the PR's high-level purpose is now better represented by a different subsection, move the bullet to that subsection
- Never create duplicate bullets for the same PR number
- If multiple matching `(#<pr-number>)` bullets already exist, treat the changelog as ambiguous and skip editing

## Error Handling

- Not on feature branch → "Error: Cannot create PR from master/main branch"
- No commits ahead → "Warning: No commits to create PR for"
- `gh` not installed → "Error: GitHub CLI not found. Install: https://cli.github.com/"
- `gh` not authenticated / `gh auth status` fails → "Error: GitHub CLI not authenticated. Run: gh auth login"
- Self-assignment fails (for example, assignees unsupported or user not assignable) → surface the `gh` error clearly and do not claim the PR was self-assigned
- `CHANGELOG.md` missing, malformed, or missing the needed unreleased subsection → skip changelog sync and continue
