---
name: gh-pr-merge
description: Squash-merge a GitHub pull request using gh CLI when the user requests merging, and verify the result
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
  category: github-workflow
---

## What I do

- Resolve a PR number, URL, or the current branch's PR
- Check authentication, PR state, required checks, and review requirements
- Squash-merge the verified PR head without bypassing branch protection
- Delete the branch only when explicitly requested
- Verify and report the merge result and resulting commit

## When to use me

Use when the user asks to merge or squash-merge a GitHub PR. Squash is the default merge method for this skill. Do not merge merely because the user asks to create, review, or inspect a PR, or asks how merging works.

An explicit request to merge authorizes the merge without another routine confirmation. Honor requests limited to checking readiness. If the user explicitly requests a different merge method, do not silently squash it; explain this skill's scope or follow that request outside this workflow.

## 1. Resolve the PR

1. Confirm GitHub CLI is installed and authenticated:
   ```bash
   gh auth status
   ```
2. Use the supplied PR URL directly, or resolve a supplied number in the repository identified by the user or current checkout:
   ```bash
   gh pr view <number-or-url> --json number,url,title,state,isDraft,baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,isCrossRepository,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup
   ```
   With no number or URL, omit the positional argument to resolve the current branch's PR. If no PR or repository can be resolved unambiguously, ask for the PR number or URL rather than selecting an arbitrary open PR.
3. Keep the resolved PR URL and full `headRefOid` for all subsequent commands. Briefly identify the PR, its base branch, and the squash strategy before merging. Local uncommitted work is not included in a server-side merge; do not commit or push it as part of this skill.

## 2. Check Merge Requirements

- If already merged, report its existing merge result and stop without another merge or branch cleanup. If closed without merging or still a draft, report the state; do not reopen it or mark it ready automatically.
- If `mergeable` is `UNKNOWN`, refresh once; if still unknown, report that GitHub has not finished computing mergeability. Stop for conflicts rather than modifying the PR's code or history.
- Inspect the review decision and merge state. Stop for missing required reviews, requested changes, or unmet branch requirements; do not use `--admin` or weaken repository protections.
- Check required CI results:
  ```bash
  gh pr checks <pr-url> --required
  ```
  Failing or pending required checks block an immediate merge. Exit code `8` means checks are pending; do not start an indefinite watch or enable `--auto` implicitly. A response explicitly stating that no required checks exist is acceptable; authentication, network, and permission errors are not evidence that no checks are required.
- Confirm squash merging is enabled for the PR's base repository, using the owner/repository from the resolved PR URL:
  ```bash
  gh api repos/<owner>/<repo> --jq '.allow_squash_merge'
  ```
  If disabled, report it without changing repository settings or substituting another merge method. GitHub remains authoritative about merge eligibility when the merge command runs.

## 3. Squash-Merge

Use the head SHA captured during the checks:

```bash
gh pr merge <pr-url> --squash --match-head-commit <verified-head-sha>
```

- Never omit the head guard to get past a mismatch. If new commits arrive, inspect the new diff and rerun the readiness checks before attempting a merge of the new head; stop if the added changes make the user's intended scope unclear.
- Preserve the PR's current base branch; do not retarget it or push directly to the base branch.
- Keep branches by default. Append `--delete-branch` only when the user explicitly requests branch deletion; the flag can delete both local and remote branches. Preserve local work and do not force-delete a branch or discard changes if cleanup fails.
- A repository requiring a merge queue may queue the PR instead of completing the merge immediately. Respect the queue and verify the outcome; do not bypass it with `--admin`. Queue processing follows repository policy, so do not promise a particular resulting commit until it is available.

## 4. Verify and Report

After the merge attempt, including a timeout or ambiguous error, read the PR state before deciding whether to retry:

```bash
gh pr view <pr-url> --json url,state,mergedAt,mergeCommit,baseRefName,autoMergeRequest
```

- Report success only when `state` is `MERGED`; include the PR URL, base branch, and `mergeCommit.oid` when available.
- If still open, report that the merge has not completed. Mention queued or scheduled status only when the CLI/API confirms it; an accepted request or zero exit code alone does not prove a merge.
- If branch cleanup was requested, report its result separately. A cleanup failure does not undo a successful merge; do not retry the merge just to retry cleanup.
- If verification fails, report the uncertainty and the exact error instead of claiming success or blindly rerunning the merge.

## Error Handling

- Missing `gh`: report `GitHub CLI not found. Install: https://cli.github.com/`.
- Authentication failure: report the `gh` error and direct the user to `gh auth login` for the relevant host; never print credentials.
- Missing PR, insufficient permissions, rejected merge, or disabled squash merging: report the cause and leave repository settings unchanged.
- Do not bypass required checks, reviews, merge queues, or execution permissions. Do not manually close linked issues; GitHub handles applicable closing references after merge.

References: [gh pr merge](https://cli.github.com/manual/gh_pr_merge), [gh pr checks](https://cli.github.com/manual/gh_pr_checks).
