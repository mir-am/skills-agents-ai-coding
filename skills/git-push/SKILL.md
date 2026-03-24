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
- Update the existing PR-linked `CHANGELOG.md` entry only when the PR's high-level scope materially changes, then commit that changelog change to the same branch before pushing
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
2. If the branch already exists on remote, treat the next push as the final push for this batch of local commits
3. If the branch does not exist on remote yet, push it first:
   ```bash
   git push -u origin <branch-name>
   ```
4. Only run pre-push PR detection, PR body updates, and changelog sync when the remote branch already exists and an open PR can already be associated with it
5. If the branch was just published and a later changelog sync creates a dedicated `CHANGELOG.md` commit, push a second time so that new changelog commit reaches the same branch
6. If the branch already existed on remote, finish with the normal push:
   ```bash
   git push
   ```

## PR Update Workflow

When the remote branch already exists, check for an open PR before the final push and update its description when needed.
If the branch was not yet on remote, do the initial `git push -u` first; only then try PR detection and any follow-up sync work.
Only update the PR description when the outgoing commits add something new. Do not update it for fixes to earlier work in the same branch.

### Detect Open PR

```bash
gh pr view --json number,body --jq '{number: .number, body: .body}' 2>/dev/null
```

- If no open PR exists → skip PR update, just report the push
- If PR found → proceed to analyzing the new commits

### Analyze New Commits

1. If the branch already exists on remote, get the commits that are about to be pushed using the existing remote range:
   ```bash
   git log origin/<branch>..HEAD --oneline
   ```
   Note: Capture this **before** the final push to know which commits are new.
2. If the branch was not yet on remote, use the local commit batch that existed before the initial `git push -u` as the basis for PR update analysis instead of relying on `origin/<branch>`.
3. Get the diffs for those commits to understand what changed:
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

### Update CHANGELOG.md and Commit It

Only reach this step if an open PR exists for the current branch and the outgoing commits materially change what the PR delivers.

1. Check whether root `CHANGELOG.md` exists and contains exactly one `## [Unreleased]` section
2. Within the `## [Unreleased]` section, find the existing changelog bullet ending with `(#<pr-number>)`
3. Re-evaluate the PR's high-level purpose after the push
4. Update that one-line bullet only if the old wording no longer reflects the PR's overall scope
5. If the best matching changelog subsection changed, move the bullet to the better subsection
6. If `CHANGELOG.md` changed, stage only that file:
   ```bash
   git add CHANGELOG.md
   ```
7. Verify the staged set contains only `CHANGELOG.md` before committing:
   ```bash
   git diff --cached --name-only
   ```
   If any staged path other than `CHANGELOG.md` appears, warn and skip the changelog commit rather than risking unrelated files in the commit.
8. Create a dedicated changelog commit before the branch push:
   ```bash
   git commit -m "docs: update changelog entry for PR #<pr-number>"
   ```

Rules:

- Do not touch `CHANGELOG.md` if there is no open PR in the current agent context or no open PR for the branch
- Do not create a new changelog bullet from `git-push`; this skill only updates an existing PR-linked bullet
- Reuse the same high-level classification rules as `git-pr`: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`, then `Misc` if none fit well
- Only move the bullet if the newly selected subsection already exists under `## [Unreleased]`; otherwise skip changelog editing
- Keep the changelog entry in this format:
  ```markdown
  - <high-level PR summary> (#<pr-number>)
  ```
- Keep the `(#<pr-number>)` suffix unchanged when rewriting text
- If the push only fixes, polishes, refactors, or addresses review feedback on existing branch work, leave the changelog unchanged
- If no matching `(#<pr-number>)` bullet exists, skip changelog editing
- If multiple matching `(#<pr-number>)` bullets exist, treat the changelog as ambiguous and skip editing
- Only create the dedicated changelog commit when `CHANGELOG.md` actually changed
- Stage only `CHANGELOG.md`; never use broad staging like `git add .`
- Verify the staged set contains only `CHANGELOG.md` before `git commit`; otherwise warn and skip the changelog commit
- Keep the changelog commit dedicated to the changelog sync so it can be pushed with the same branch work cleanly
- If `CHANGELOG.md` already has unrelated local edits that make the sync unsafe or ambiguous, skip changelog editing and warn the user instead of guessing
- If the branch already exists on remote, include any changelog commit in that same final push
- If the branch was just published with `git push -u`, do a second push only when a changelog commit was created afterward

## Error Handling

- On master/main → "Error: Cannot push directly to master/main. Switch to a feature branch."
- No unpushed commits → "Nothing to push — branch is up-to-date with remote."
- `gh` not installed → "Error: GitHub CLI not found. Install: https://cli.github.com/"
- No open PR → push succeeds, inform user: "Pushed to <branch>. No open PR found to update."
- `gh pr edit` fails → warn user but do not fail the push: "Warning: Push succeeded but PR description update failed."
- `CHANGELOG.md` missing, malformed, ambiguous, or missing the needed unreleased subsection → skip changelog sync and continue
- Staged set contains files other than `CHANGELOG.md` after sync → warn and skip the changelog commit to avoid committing unrelated staged changes
- `git commit` for `CHANGELOG.md` fails → warn user and continue with the branch push without the changelog update: "Warning: Changelog update was prepared but could not be committed."
