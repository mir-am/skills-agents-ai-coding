---
name: gh-protect-default-branch
description: Protect the default branch from direct pushes so changes land only via pull requests
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
  category: github-workflow
---

## What I do

- Detect the repository's default branch automatically
- Apply minimal branch protection: require a pull request before merging, block force pushes and deletions
- Verify the protection was applied correctly
- Optionally remove protection if the user asks

## When to use me

Use this skill when the user wants to protect the default branch from direct pushes so that changes can only be merged through pull requests.

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- Must be inside a git repo with a GitHub remote
- The authenticated user must have **admin** permissions on the repository
- If `gh` not installed -> error: `Error: GitHub CLI not found. Install: https://cli.github.com/`
- If not authenticated -> error: `Error: Not authenticated with GitHub. Run: gh auth login`
- If not admin -> error: `Error: Admin permissions required to set branch protection`

## Apply Protection Workflow

1. **Validate GitHub access**
   ```bash
   gh auth status
   ```

2. **Detect default branch and repo**
   ```bash
   gh repo view --json nameWithOwner,defaultBranchRef --jq '"\(.nameWithOwner) \(.defaultBranchRef.name)"'
   ```
   Parse the output to get `OWNER/REPO` and `BRANCH`.

3. **Apply minimal branch protection**
   ```bash
   gh api -X PUT \
     -H "Accept: application/vnd.github+json" \
     "repos/{owner}/{repo}/branches/{branch}/protection" \
     --input - <<'EOF'
   {
     "required_status_checks": null,
     "enforce_admins": true,
     "required_pull_request_reviews": {
       "required_approving_review_count": 0
     },
     "restrictions": null,
     "allow_force_pushes": false,
     "allow_deletions": false
   }
   EOF
   ```
   Replace `{owner}/{repo}` and `{branch}` with the values from step 2.

4. **Verify protection**
   ```bash
   gh api -H "Accept: application/vnd.github+json" \
     "repos/{owner}/{repo}/branches/{branch}/protection" \
     --jq '{pr_required: (.required_pull_request_reviews != null), force_push_blocked: (.allow_force_pushes.enabled == false), deletions_blocked: (.allow_deletions.enabled == false)}'
   ```
   All three fields should be `true`.

5. **Report result**
   ```text
   Protected {owner}/{repo}@{branch}: PRs required, force pushes blocked, deletions blocked.
   ```

## Remove Protection Workflow

Use this only when the user explicitly asks to remove protection.

1. **Detect default branch** (same as step 2 above)

2. **Remove branch protection**
   ```bash
   gh api -X DELETE \
     -H "Accept: application/vnd.github+json" \
     "repos/{owner}/{repo}/branches/{branch}/protection" \
     --silent
   ```

3. **Report result**
   ```text
   Removed branch protection from {owner}/{repo}@{branch}.
   ```

## Error Handling

- `gh` not installed -> `Error: GitHub CLI not found. Install: https://cli.github.com/`
- Not authenticated -> `Error: Not authenticated with GitHub. Run: gh auth login`
- No GitHub remote -> `Error: No GitHub remote found. Is this a GitHub repository?`
- 403/404 from API -> `Error: Admin permissions required to set branch protection`
- Protection already exists -> safe to re-apply (PUT is idempotent)
- Protection does not exist on remove -> safe (DELETE returns 204 or 404)
