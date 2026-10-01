---
name: gh-pr-merge
description: Squash-merge a GitHub pull request, verify the result, and delete its remote source branch unless the user requests retaining it
license: MIT
metadata:
  audience: developers
  workflow: github
  category: github-workflow
---

## What I do

- Resolve a PR number, URL, or the current branch's PR
- Check authentication, PR state, required checks, and review requirements
- Squash-merge the verified PR head without bypassing branch protection
- Delete the source branch on GitHub after a verified merge unless the user requests retaining it
- Preserve local branches and uncommitted work
- Verify and report the merge result and resulting commit

## When to use me

Use when the user asks to merge or squash-merge a GitHub PR. Squash is the default merge method for this skill. Do not merge merely because the user asks to create, review, or inspect a PR, or asks how merging works.

An explicit request to merge authorizes the merge and subsequent remote source-branch cleanup without another routine confirmation. Honor requests to retain the branch or requests limited to checking readiness. If the user explicitly requests a different merge method, do not silently squash it; explain this skill's scope or follow that request outside this workflow.

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
3. Keep the resolved PR URL, full `headRefOid`, `headRefName`, and source repository (`headRepositoryOwner.login` and `headRepository.name`) before merging; the source repository can be a fork and its metadata may disappear after automatic branch deletion. Retain the GitHub hostname from the PR URL for API calls. Briefly identify the PR, its base branch, the squash strategy, and planned remote branch cleanup (or the user's retention request). Local uncommitted work is not included in a server-side merge; do not commit or push it as part of this skill.

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
- Leave `--delete-branch` off the merge command because it can delete local branches too. Perform remote-only cleanup in Step 5 after verifying the merge; do not switch branches, delete local branches, or discard local changes.
- A repository requiring a merge queue may queue the PR instead of completing the merge immediately. Respect the queue and verify the outcome; do not bypass it with `--admin`. Queue processing follows repository policy, so do not promise a particular resulting commit until it is available.

## 4. Verify the Merge

After the merge attempt, including a timeout or ambiguous error, read the PR state before deciding whether to retry:

```bash
gh pr view <pr-url> --json url,state,mergedAt,mergeCommit,baseRefName,autoMergeRequest
```

- Continue to cleanup only when `state` is `MERGED`. Report the PR URL, base branch, and `mergeCommit.oid` when available.
- If still open, report that the merge has not completed and stop without deleting the source branch. Mention queued or scheduled status only when the CLI/API confirms it; an accepted request or zero exit code alone does not prove a merge.
- If verification fails, report the uncertainty and the exact error instead of claiming success, deleting the branch, or blindly rerunning the merge.

## 5. Delete the Remote Source Branch and Report

Skip cleanup when the user requested retaining the branch. Otherwise, after Step 4 confirms the merge, use the captured source repository and branch, not the current local branch or the base repository of a fork PR. If source metadata is missing or ambiguous, report that cleanup could not be performed instead of guessing.

1. Check the source repository's default branch and current remote references:
   ```bash
   gh api --hostname <github-host> "repos/<head-owner>/<head-repo>" --jq '.default_branch'
   gh api --hostname <github-host> "repos/<head-owner>/<head-repo>/git/matching-refs/heads/<url-encoded-head-branch>" --jq '.[] | {ref: .ref, sha: .object.sha}'
   ```
   Substitute the captured values and URL-encode the branch name for the endpoint, including any `#` or `%` characters. Compare returned refs against the full, unencoded `refs/heads/<headRefName>`: this endpoint also returns branches sharing a prefix, so those are not matches. Never delete the source repository's default branch or the PR's base branch in the same repository. If the exact ref is absent from a successful response, report it as already absent (for example, GitHub auto-deleted it) and skip deletion. If its SHA differs from the verified PR head, preserve the branch and report that it changed after the merge. API/authentication errors do not prove absence; report them and stop cleanup.
2. Delete only the verified source branch on GitHub:
   ```bash
   gh api --hostname <github-host> --method DELETE "repos/<head-owner>/<head-repo>/git/refs/heads/<url-encoded-head-branch>"
   ```
   Use the same endpoint values checked in Step 1. A permission or protection error is a cleanup failure; do not bypass it or substitute a local branch deletion.
3. Verify remote absence by repeating the reference query, including after a timeout or ambiguous deletion error:
   ```bash
   gh api --hostname <github-host> "repos/<head-owner>/<head-repo>/git/matching-refs/heads/<url-encoded-head-branch>" --jq '.[] | {ref: .ref, sha: .object.sha}'
   ```
   Report cleanup as verified only when this request succeeds and the exact source ref is absent. If the ref still exists or verification fails, report the remaining branch or uncertainty; do not blindly retry deletion.

Report merge and cleanup results separately: merged commit plus remote branch deleted, already absent, retained on request, or cleanup skipped/failed with the reason. A cleanup failure does not undo a successful merge; never rerun the merge to retry cleanup. Local branches and uncommitted work remain untouched.

## Error Handling

- Missing `gh`: report `GitHub CLI not found. Install: https://cli.github.com/`.
- Authentication failure: report the `gh` error and direct the user to `gh auth login` for the relevant host; never print credentials.
- Missing PR, insufficient permissions, rejected merge, or disabled squash merging: report the cause and leave repository settings unchanged.
- Do not bypass required checks, reviews, merge queues, or execution permissions. Do not manually close linked issues; GitHub handles applicable closing references after merge.

References: [gh pr merge](https://cli.github.com/manual/gh_pr_merge), [gh pr checks](https://cli.github.com/manual/gh_pr_checks), [GitHub Git references API](https://docs.github.com/en/rest/git/refs).
