---
name: gh-issue-fix
description: Implement a GitHub issue end to end through testing, commits, and a linked pull request without routine approval pauses
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
  category: development
---

## What I do

- Fetch an issue and investigate the relevant code
- Present a concise implementation plan and continue without waiting for approval
- Create or resume a dedicated issue branch
- Implement, test, and review the changes
- Use `git-commit` and `gh-pr` to commit, push, and open a linked PR
- Verify the PR targets the default branch and closes the issue when merged

## When to use me

Use when the user asks to fix or implement a GitHub issue by number or URL. The default outcome is a tested change published as a PR, with merging left as a separate action.

Honor a narrower user request, such as planning only or leaving changes uncommitted. Otherwise, invocation authorizes the issue-to-PR workflow without additional plan, commit, push, or PR confirmation prompts. Continue to respect tool permissions, branch protections, and execution-mode restrictions.

## Phase 1: Issue Intake

1. Use the supplied issue number or URL; ask for it only if missing.
2. Check GitHub CLI access and identify the issue repository and its default branch. Resolve `<owner/repo>` from the supplied URL, or from the current checkout for a bare issue number:
   ```bash
   gh auth status
   git remote -v
   gh repo view <owner/repo> --json nameWithOwner,defaultBranchRef
   gh issue view <number-or-url> --repo <owner/repo> --json number,url,title,body,labels,comments,assignees,state
   ```
   For an issue URL, resolve its repository explicitly and use `--repo <owner/repo>` for subsequent GitHub commands. Confirm the working checkout belongs to that repository or its fork; do not apply the issue to an unrelated checkout.
3. Keep the issue number, URL, repository, and detected default branch available throughout the workflow. Do not assume the default branch is named `main` or `master`.
4. Investigate unclear requirements in the code before asking questions. Ask only for missing information that prevents a correct implementation; choose reasonable defaults for routine decisions.

## Phase 2: Exploration and Plan

Read the repository instructions and relevant code, tests, entry points, and interfaces. Identify the root cause or feature requirements and the smallest coherent change that satisfies the issue.

Present a brief plan covering the affected files, implementation steps, and validation. Proceed immediately to branch preparation and implementation; do not ask the user to approve the plan.

## Phase 3: Dedicated Issue Branch

1. Inspect the current work before changing branches:
   ```bash
   git status --short
   git branch --show-current
   ```
2. Reuse a feature branch only when its commits and issue/PR context establish that it belongs to this issue and its PR has not been merged or closed. A feature branch for unrelated or completed work must not be reused.
3. Otherwise, fetch the target repository's default branch and create `<prefix><issue-number>-<short-slug>` from that remote branch. Use `fix/` for bugs, `feat/` for enhancements, and `chore/` otherwise; keep the slug short and descriptive.
   ```bash
   git fetch <base-remote>
   git switch --no-track -c <issue-branch> <base-remote>/<default-branch>
   ```
   Select the remote that corresponds to the target repository; for a fork this may differ from the push remote. If the proposed branch name already belongs to other work, choose an unused suffix without resetting it.
4. Preserve unrelated staged and unstaged changes. Use an isolated worktree when needed to keep the issue work separate; do not discard user changes or silently include them in the issue commit.

## Phase 4: Implementation and Validation

1. Implement the plan using the repository's existing conventions.
2. Run checks appropriate to the change and fix failures introduced by the work.
3. Review the final diff against the issue's requirements and confirm it contains only intended changes.
4. If a failure or missing dependency prevents required validation, investigate it and report the unresolved blocker; do not claim a tested result or proceed to publication with known unresolved validation failures. Report checks that are not applicable separately.

## Phase 5: Commit, Push, and Linked PR

Continue automatically when implementation and validation are complete:

1. Invoke `git-commit` to stage only the issue changes and create an appropriate commit, following repository commit and CI-skip rules. If the helper skill is unavailable, perform those same steps directly using explicit file paths; never include unrelated staged files.
2. Check whether the issue branch already has an open PR in the target repository:
   ```bash
   gh pr list --repo <owner/repo> --head <issue-branch> --state open --json number,url,headRefName,headRepository,headRepositoryOwner,baseRefName,body
   ```
   For forks, identify the head repository as well as the branch so a similarly named branch is not mistaken for this work. Surface API/authentication errors instead of treating them as an empty result.
3. Prepare the PR body with `Closes #<issue-number>` before creation so merging into the default branch closes the issue. For an explicitly requested cross-repository issue reference, use `Closes <owner/repo>#<issue-number>`.
4. If no matching PR exists, invoke `gh-pr` with the issue context and the detected default branch as the explicit base, overriding that helper's `master`/`main` fallback. Let it push the branch, self-assign the PR, and perform its conditional changelog sync. If the helper is unavailable, push the issue branch and create the PR directly:
   ```bash
   git push -u <push-remote> <issue-branch>
   gh pr create --repo <owner/repo> --base <default-branch> --head <head> --assignee @me --title "<title>" --body-file <pr-body-file>
   ```
   Use the branch name for a same-repository head and `<fork-owner>:<issue-branch>` for a fork. Write a concise summary, key changes, and validation results to the body file.
5. If a matching open PR already exists, update that PR instead of creating a duplicate, preserve unrelated description content, and ensure its base and closing reference are correct. Push new commits to its existing head branch; follow the helper skills' conditional changelog rules where applicable.
6. Verify publication:
   ```bash
   gh pr view <pr-number> --repo <owner/repo> --json url,state,baseRefName,headRefName,headRefOid,body,closingIssuesReferences
   git rev-parse HEAD
   ```
   Confirm the PR is open, targets the detected default branch, contains the latest committed work, and lists the intended issue in `closingIssuesReferences`. Fix a missing closing reference and verify again; report any unresolved verification failure accurately.

Do not merge the PR or close the issue manually as part of this workflow. GitHub closes the linked issue when the PR is merged into the default branch; see [GitHub's issue-linking documentation](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue).

## Completion and Blockers

- Return the PR URL, a concise change summary, and validation results without offering commit/PR creation as optional next steps.
- Explain that the linked issue remains open until merge.
- If authentication, permissions, a rejected push, or PR creation blocks publication, preserve completed work and report the exact failed step and remaining work. Respect branch protection and do not force-push to overcome rejection.
- Before retrying PR creation after an ambiguous response, check for an existing PR to avoid duplicates. If no issue change is needed and no existing PR completes it, report that finding rather than creating an empty commit or PR.
