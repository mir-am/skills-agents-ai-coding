---
name: gh-copilot-review
description: Request a GitHub Copilot review for a pull request, or post a scoped @copilot review/comment request
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
- Support a scoped best-effort mode by posting an `@copilot` PR comment for a specific file or user-provided scope
- Keep scoped requests limited to review/comments only, not code changes
- Return a concise result describing what was triggered

## When to use me

Use this skill when:
- User wants to request GitHub Copilot review on a pull request
- User wants a simple Copilot review request for the whole PR
- User wants Copilot to focus on one file or a narrower scope inside the PR
- User wants to trigger the request using `gh` CLI if possible

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- If given only a PR number, the current repository must have a GitHub `origin` remote
- The target PR must be accessible with the current GitHub credentials
- The caller must have permission to request reviewers or post PR comments in the target repository
- If `gh` not installed -> error: `Error: GitHub CLI not found. Install: https://cli.github.com/`
- If not authenticated -> error: `Error: Not authenticated with GitHub. Run: gh auth login`

## Input Handling

Accept either of these forms:

- Full GitHub PR URL
  - Example: `https://github.com/owner/repo/pull/123`
- PR number
  - Example: `123`

Optional scope handling:

- Default: no scope specified -> request standard Copilot review for the full PR
- Scoped mode: if the user specifies a file or narrower scope -> post a PR comment mentioning `@copilot`
- The scoped mode should ask for review/comments only
- The scoped mode should explicitly say `Do not make changes.`

### Resolution Rules

1. If input is a full PR URL:
   - Use it directly with `gh pr view <pr>` and related `gh` commands.
2. If input is a PR number:
   - Resolve repository from `git remote get-url origin`
   - Derive `owner/repo`
3. If the input is neither a valid URL nor a PR number:
   - Error: `Error: Provide a GitHub PR URL or PR number`

## Mode Selection

### Mode 1: Standard PR-wide Copilot review

Use this when the user asks for a normal Copilot review and does not narrow the scope.

- Preferred behavior: request Copilot as a PR reviewer
- This is the official PR review flow
- Copilot reviews the pull request changes and leaves comment-style review feedback

### Mode 2: Scoped `@copilot` review/comment request

Use this only when the user explicitly narrows the scope, such as:

- a single file
- a directory or file pattern
- a specific concern inside the PR

Important behavior:

- This is a best-effort prompt flow, not the same as assigning Copilot as a reviewer
- Use a PR comment that mentions `@copilot`
- Ask for review/comments only
- Explicitly instruct: `Do not make changes.`
- Do not claim that GitHub guarantees strict file-only behavior

## Workflow

1. **Validate GitHub access**
   ```bash
   gh auth status
   ```

2. **Resolve PR and fetch metadata**
   - For PR URL:
     ```bash
     gh pr view <pr> --json id,number,title,url,author,baseRefName,headRefName
     ```
   - For PR number in current repo, verify remote:
     ```bash
     git remote get-url origin
     gh pr view <number> --json id,number,title,url,author,baseRefName,headRefName
     ```

3. **Decide the mode**
   - If no explicit scope is provided -> use standard PR-wide review mode
   - If explicit scope is provided -> use scoped `@copilot` comment mode

4. **Trigger standard PR-wide Copilot review**
   - Prefer GitHub GraphQL with a review-request mutation:
     ```bash
     query=$(cat <<'EOF'
     mutation($pullRequestId: ID!, $botLogins: [String!]) {
       requestReviewsByLogin(input: {
         pullRequestId: $pullRequestId,
         botLogins: $botLogins,
         union: false
       }) {
         clientMutationId
       }
     }
     EOF
     )

     gh api graphql \
       -f query="$query" \
       -F pullRequestId='<pr-node-id>' \
       -f botLogins[]='copilot-pull-request-reviewer[bot]'
     ```
   - If the exact Copilot bot login differs in a target environment, adapt the login string to the repository's working Copilot reviewer identity
   - If GitHub rejects the request because Copilot review is unavailable in that repo, return a clear error rather than silently falling back

5. **Trigger scoped `@copilot` review/comment request**
   - Create a PR comment with wording like:
     ```text
     @copilot Please review/comment only on `path/to/file` in this pull request. Focus on issues, risks, and improvements in that scope only. Do not make changes.
     ```
   - Post the comment with:
     ```bash
     cat <<'EOF' | gh pr comment <pr> --body-file -
     @copilot Please review/comment only on `path/to/file` in this pull request. Focus on issues, risks, and improvements in that scope only. Do not make changes.
     EOF
     ```
   - If the user supplied a custom scoped prompt, pass it via `--body-file` rather than embedding it directly in shell quotes
   - Preserve the user's intent but keep the instruction `Do not make changes.` unless they explicitly ask for a different behavior

6. **Report results**
   - Return whether the skill triggered:
     - full PR reviewer request, or
     - scoped `@copilot` comment request
   - Include the PR URL
   - If a scoped comment was posted, include the scope that was requested

## Scoped Prompt Construction

When building a scoped prompt:

- Keep it short and explicit
- Mention the file or scope exactly as the user provided it when reasonable
- Ask for review/comments, not implementation
- End with `Do not make changes.`

### Recommended Prompt Template

```text
@copilot Please review/comment only on `<scope>` in this pull request. Focus on issues, risks, correctness, maintainability, and improvements in that scope only. Do not make changes.
```

### If the user names a file

Use the file path directly in `<scope>`.

Example:

```text
@copilot Please review/comment only on `src/server/auth.ts` in this pull request. Focus on issues, risks, correctness, maintainability, and improvements in that file only. Do not make changes.
```

## Output Format

Return a concise result like:

```text
Requested GitHub Copilot review for PR #123.
- Mode: PR-wide reviewer request
- PR: https://github.com/owner/repo/pull/123
```

Or:

```text
Requested scoped GitHub Copilot review for PR #123.
- Mode: @copilot scoped comment
- Scope: src/server/auth.ts
- PR: https://github.com/owner/repo/pull/123
```

## Error Handling

- Invalid input -> `Error: Provide a GitHub PR URL or PR number`
- `gh` missing -> `Error: GitHub CLI not found. Install: https://cli.github.com/`
- Not authenticated -> `Error: Not authenticated with GitHub. Run: gh auth login`
- No GitHub remote for PR number mode -> `Error: No GitHub remote found. Provide a full PR URL or set origin`
- PR not found or inaccessible -> `Error: Unable to access the pull request with current GitHub credentials`
- Cannot request reviewers -> `Error: Unable to request Copilot review on this pull request`
- Cannot post scoped comment -> `Error: Unable to post the scoped @copilot comment on this pull request`
- Copilot unavailable for repository or plan -> `Error: GitHub Copilot review is not available for this repository or account`

## Notes

- Prefer `gh` CLI for all interactions
- Use standard reviewer-request mode by default
- Use `@copilot` scoped comment mode only when the user explicitly narrows scope
- Scoped mode is best-effort and prompt-driven; it is not guaranteed to behave exactly like reviewer assignment
- Keep scoped requests limited to review/comments only unless the user explicitly asks for a different Copilot behavior
