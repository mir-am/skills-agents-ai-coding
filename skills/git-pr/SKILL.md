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
- Update root `CHANGELOG.md` when present with one PR-linked unreleased bullet using the PR URL, then commit and push that changelog update back to the same branch

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
4. If a follow-up changelog sync creates a new `CHANGELOG.md` commit after PR creation, push that commit to the same branch as well

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
- Capture the created PR number and URL for any follow-up changelog sync, commit, and push
- Return the PR URL to the user

## CHANGELOG.md Sync

After the PR is created, optionally sync the repository root `CHANGELOG.md`.

### When to sync

- Only if `CHANGELOG.md` exists at the repository root
- Only if `## [Unreleased]` exists exactly once
- Only if the unreleased section already contains the target subsection heading
- If any of the above checks fail, skip changelog editing without failing PR creation

### Changelog Commit and Push Workflow

After the PR exists and its number is known:

1. Update or insert the single PR-linked unreleased bullet using the PR number and PR URL
2. If `CHANGELOG.md` is unchanged after the sync logic, stop here
3. If `CHANGELOG.md` changed, stage only that file:
   ```bash
   git add CHANGELOG.md
   ```
4. Verify the staged set contains only `CHANGELOG.md` before committing:
   ```bash
   git diff --cached --name-only
   ```
   If any staged path other than `CHANGELOG.md` appears, warn and skip the changelog commit rather than risking unrelated files in the commit.
5. Create a dedicated changelog commit:
   ```bash
   git commit -m "docs: add changelog entry for PR #<pr-number>"
   ```
   If the skill updated an existing bullet rather than adding a new one, use:
   ```bash
   git commit -m "docs: update changelog entry for PR #<pr-number>"
   ```
6. Push that new changelog commit to the same branch that backs the PR:
   ```bash
   git push
   ```

Rules:

- Only create the follow-up changelog commit when `CHANGELOG.md` actually changed
- Stage only `CHANGELOG.md`; never use broad staging like `git add .`
- Verify the staged set contains only `CHANGELOG.md` before `git commit`; otherwise warn and skip the changelog commit
- Keep the changelog commit dedicated to the changelog sync so the PR history is easy to understand
- If `CHANGELOG.md` already has unrelated local edits that make the sync unsafe or ambiguous, skip changelog editing and warn the user instead of guessing
- Do not fail PR creation just because changelog commit or push steps are skipped

### Changelog Entry Format

- Write exactly one bullet for the PR in this format:
  ```markdown
  - <high-level PR summary> ([#<pr-number>](<pr-url>))
  ```
- Keep it to one line
- Use changelog-style wording, not PR-body wording
- Focus on the high-level thing the PR does, not an implementation checklist

### Section Selection

Choose the best matching subsection under `## [Unreleased]` based on the PR's high-level purpose:

- `### Added` for new user-facing capabilities or first-time integrations
- `### Changed` for meaningful behavior changes or enhancements to existing functionality
- `### Deprecated` when marking functionality as discouraged but still available
- `### Removed` when functionality is no longer available to users
- `### Fixed` for user-visible bug fixes
- `### Security` for security-relevant fixes or improvements
- `### Misc` only when the PR is notable but does not fit the standard Keep a Changelog sections

### Update Rules

- Treat changelog state as one PR = one bullet
- Within the `## [Unreleased]` section, if a bullet already references that PR number using either `(#<pr-number>)` or `([#<pr-number>](<pr-url>))`, update that line instead of appending a second one
- Only move bullets within the `## [Unreleased]` section (between its subsections) when the PR's high-level purpose is better represented elsewhere
- Never create duplicate bullets for the same PR number within `## [Unreleased]`
- If multiple matching bullets for the same PR number exist within `## [Unreleased]`, or if matching bullets are found only outside `## [Unreleased]`, treat the changelog as ambiguous and skip editing
- If an existing plain `(#<pr-number>)` suffix is found, rewrite it to the linked `([#<pr-number>](<pr-url>))` form during the update
- If changelog sync succeeds and produces a file change, commit and push that `CHANGELOG.md` change to the same PR branch

## Error Handling

- Not on feature branch → "Error: Cannot create PR from master/main branch"
- No commits ahead → "Warning: No commits to create PR for"
- `gh` not installed → "Error: GitHub CLI not found. Install: https://cli.github.com/"
- `gh` not authenticated / `gh auth status` fails → "Error: GitHub CLI not authenticated. Run: gh auth login"
- Self-assignment fails (for example, assignees unsupported or user not assignable) → surface the `gh` error clearly and do not claim the PR was self-assigned
- `CHANGELOG.md` missing, malformed, ambiguous, or missing the needed unreleased subsection → skip changelog sync and continue
- Staged set contains files other than `CHANGELOG.md` after sync → warn and skip the changelog commit to avoid committing unrelated staged changes
- `git commit` for `CHANGELOG.md` fails → warn user but keep the PR: "Warning: PR created but changelog commit failed."
- `git push` for the follow-up changelog commit fails → warn user but keep the PR: "Warning: PR created but changelog commit was not pushed."
