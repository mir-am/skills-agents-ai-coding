---
name: git-push
description: Push commits to feature branch and update open PR description with new changes
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: git
  category: git-workflow
---

## What I do

- Push new local commits on a feature branch to the remote
- Detect if an open PR exists for the current branch
- Update the PR's "Changes" section only when the push adds significant new functionality
- Skip PR updates for commits that fix bugs or mistakes from earlier commits in the same branch
- Preserve the existing PR Summary while appending new change entries

## When to use me

Use this skill when the user asks to push commits and/or update the PR with the latest changes.

## Prerequisites

- Must be on a feature branch (not master/main)
- Branch must have unpushed commits ahead of remote
- GitHub CLI (`gh`) must be installed and authenticated
- If `gh` not installed → error: "GitHub CLI not found. Install: https://cli.github.com/"

## Validation Workflow

1. Check current branch: `git branch --show-current`
2. If on `master` or `main` → error: "Error: Cannot push directly to master/main. Switch to a feature branch."
3. Check for unpushed commits:
   ```bash
   git log origin/<branch>..HEAD --oneline
   ```
4. If no unpushed commits → inform user: "Nothing to push — branch is up-to-date with remote."

## Push Workflow

1. Check if branch exists on remote:
   ```bash
   git ls-remote --heads origin <branch-name>
   ```
2. If not on remote: `git push -u origin <branch-name>`
3. If exists on remote: `git push`

## PR Update Workflow

After pushing, check if an open PR exists for this branch and update its description.
Only update the PR description when the push adds something new. Do not update it for fixes to earlier work in the same branch.

### Detect Open PR

```bash
gh pr view --json number,body --jq '{number: .number, body: .body}' 2>/dev/null
```

- If no open PR exists → skip PR update, just report the push
- If PR found → proceed to analyzing the new commits

### Analyze New Commits

1. Get the commits that were just pushed (use the range from before the push):
   ```bash
   git log origin/<branch>..HEAD --oneline
   ```
   Note: Capture this **before** pushing to know which commits are new.
2. Get the diffs for those commits to understand what changed:
   ```bash
   git diff <pre-push-sha>..HEAD --stat
   ```

### Decide Whether to Update the PR

Look at the new commits and decide: **do they add something new to the branch, or do they fix/correct earlier work in the same branch?**

**Update the PR Changes section** when the new commits:
- Add a new feature, capability, or behavior
- Add new files, components, or modules
- Introduce a new integration or API
- Make a meaningful enhancement that changes what the PR delivers

**Skip the PR Changes update** when the new commits:
- Fix a bug introduced by an earlier commit in this same branch
- Fix typos, linting errors, or test failures from earlier branch work
- Refactor or clean up code that was added in this branch
- Address code review feedback on existing branch changes

The simple rule: if the commit makes the PR do something it didn't do before, update Changes. If it fixes or polishes what the PR already does, skip the update.

When skipping, just report the push: "Pushed to `<branch>`. PR not updated (commit fixes/polishes existing branch work)."

### Update PR Description

Only reach this step if the new commits are significant (see above).

1. Fetch the current PR body:
   ```bash
   gh pr view <number> --json body --jq .body
   ```
2. Analyze the new commits and session context
3. Generate new bullet points for the `## Changes` section (same style as `git-pr` skill)
4. Append the new bullet points to the existing `## Changes` section
5. Keep the `## Summary` section unchanged unless it no longer reflects the PR accurately — if so, update it
6. Write the updated body back:
   ```bash
   gh pr edit <number> --body "<updated body>"
   ```

### Updated Description Format

Preserve the existing structure from the `git-pr` skill:

```markdown
## Summary
<existing or updated 2-3 sentence overview>

## Changes
- <existing change 1>
- <existing change 2>
- <new change from latest push>
- <new change from latest push>
```

## Error Handling

- On master/main → "Error: Cannot push directly to master/main. Switch to a feature branch."
- No unpushed commits → "Nothing to push — branch is up-to-date with remote."
- `gh` not installed → "Error: GitHub CLI not found. Install: https://cli.github.com/"
- No open PR → push succeeds, inform user: "Pushed to <branch>. No open PR found to update."
- `gh pr edit` fails → warn user but do not fail the push: "Warning: Push succeeded but PR description update failed."
