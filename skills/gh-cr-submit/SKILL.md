---
name: gh-cr-submit
description: Submit AI-generated code review from .opencode/review/ to GitHub PR
license: MIT
metadata:
  audience: developers
  workflow: code-review
  category: git-workflow
---

## What I do

- Extract PR number from user input (supports `#123`, `PR 123`, `pull request 123`)
- Validate GitHub CLI installed and authenticated
- Validate GitHub remote exists
- Verify PR exists on GitHub
- Get current local branch and PR target branch
- Handle fork scenarios (cross-repo PRs)
- Ask user approval if local branch doesn't match PR target
- Search for review file in `.opencode/review/` matching PR number
- Handle multiple review files (ask user to choose)
- Read review file content
- Prepend AI-generated warning header at the very top
- Submit review as comment (neutral stance) to GitHub PR
- Report success with PR URL

## When to use me

Use this skill when the user asks to submit a code review to a GitHub Pull Request.

**Trigger examples:**
- "Submit review for PR #123"
- "Post the review to PR 456"
- "Submit code review for pull request 789"
- "Upload review to PR #123"

## Prerequisites

1. **GitHub CLI installed**: `gh` must be available
   - Check: `command -v gh >/dev/null 2>&1`
   - If not found: "Error: GitHub CLI not found. Install from: https://cli.github.com/"

2. **Authenticated with GitHub**: User must be logged in
   - Check: `gh auth status`
   - If not authenticated: "Error: Not authenticated with GitHub. Run: gh auth login"

3. **GitHub remote**: Repository must have a GitHub remote configured
   - Check: `gh repo view --json nameWithOwner`
   - If fails: "Error: This repository does not have a GitHub remote configured."

4. **Review file exists**: Must have review file in `.opencode/review/`
   - Check: `.opencode/review/` directory exists
   - If not: "Error: .opencode/review/ directory not found. Generate a review first using the gh-pr-review skill."

## PR Number Extraction

Extract the PR number from user input:
- Pattern: `#?(\d+)` (supports with or without `#`)
- Examples: "#123" → 123, "PR 456" → 456, "pull request 789" → 789
- If no number found: "Error: Please provide a valid PR number (e.g., 'submit review for PR #123')."

## Validation Workflow

### Step 1: Validate prerequisites (run in parallel)

```bash
command -v gh >/dev/null 2>&1 && echo "gh found" || echo "gh not found"
```

```bash
gh auth status
```

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

```bash
test -d .opencode/review && echo "review dir exists" || echo "review dir missing"
```

### Step 2: Validate PR exists

```bash
gh pr view <PR_NUMBER> --json number,state
```

- If fails: "Error: PR #<number> not found. Verify the PR number and repository."
- If state is "CLOSED" or "MERGED": Warn user but allow continuation (see Edge Cases section)

## Branch Validation Workflow

### Step 1: Get repository info and check for forks

```bash
gh repo view --json nameWithOwner,isFork,parent -q '.'
```

### Step 2: Get current branch

```bash
git branch --show-current
```

If empty (detached HEAD):
- Warn: "You are in detached HEAD state. PR #<number> targets `<target>`. Continue with submission? (yes/no)"
- Wait for user response
- If no → exit with "Submission cancelled by user."

### Step 3: Get PR target branch and check for cross-repo scenario

```bash
gh pr view <PR_NUMBER> --json baseRefName,headRefName,headRepository,headRepositoryOwner,isCrossRepository
```

Parse output:
- `baseRefName` - Target branch (e.g., "main")
- `headRefName` - Source branch (e.g., "feature-branch")
- `isCrossRepository` - Boolean indicating if PR is from a fork
- `headRepository.nameWithOwner` - Full source repository name for fork-based PRs
- `headRepositoryOwner.login` - Owner of the source repository

### Step 4: Branch comparison logic

**Case A: Same repository PR** (`isCrossRepository` = false)
- Compare current branch with `headRefName`
- If match → proceed
- If different → Ask: "Your current branch is `<current>`, but PR #<number> source branch is `<headRefName>` targeting `<baseRefName>`. Continue with submission? (yes/no)"

**Case B: Cross-repo PR from fork** (`isCrossRepository` = true)
- Note this is a fork-based PR
- Compare current branch with `headRefName` (the feature branch from fork)
- If match → proceed
- If different → Ask: "This is a cross-repo PR from fork `<headRepository.nameWithOwner>`. Your current branch is `<current>`, but the PR source branch is `<headRefName>` targeting `<baseRefName>`. Continue with submission? (yes/no)"

### Step 5: Handle user response

- If user says "no" or "cancel" → exit with "Submission cancelled by user."
- If user says "yes" → proceed to file lookup

## Review File Lookup Workflow

### Step 1: Search for review files

```bash
ls -1 .opencode/review/*-pr-<PR_NUMBER>-*.md 2>/dev/null | sort -r
```

The `sort -r` ensures most recent files appear first (reverse chronological by filename timestamp).

### Step 2: Count matches

```bash
FILE_COUNT=$(ls -1 .opencode/review/*-pr-<PR_NUMBER>-*.md 2>/dev/null | wc -l)
```

### Step 3: Handle based on count

**0 files:**
```
Error: No review found for PR #<number> in .opencode/review/
```

**1 file:**
- Get filename: `ls -1 .opencode/review/*-pr-<PR_NUMBER>-*.md`
- Inform user: "Found review file: <filename>"
- Proceed to read and submit

**2+ files:**
- List all files with numbers:
  ```
  Multiple reviews found for PR #<number>:
  1. 2026-02-23-1545-pr-123-add-csv-export.md
  2. 2026-02-23-1620-pr-123-add-csv-export.md
  3. 2026-02-23-1650-pr-123-add-csv-export.md
  
  Which one should I submit? (Enter 1, 2, 3, or 'cancel')
  ```
- Wait for user input
- Parse choice:
  - Valid number (1-N) → use that file
  - "cancel" or invalid → exit with "Submission cancelled by user."

## Review Content Preparation

### Step 1: Read review file

```bash
cat .opencode/review/<chosen-filename>.md
```

### Step 2: Check if file is empty or too small

```bash
FILE_SIZE=$(wc -l < .opencode/review/<chosen-filename>.md)

if [ "$FILE_SIZE" -lt 10 ]; then
  # Warn user: "Review file appears empty or very short (<10 lines). Continue with submission? (yes/no)"
  # Wait for user response
  # If no → exit with "Submission cancelled by user."
fi
```

### Step 3: Prepend AI warning header

Add this exact text at the very top (before all existing content):

```markdown
> ⚠️ **AI-Generated Review**: This review was generated by an AI assistant. Please use as guidance and verify findings independently.

```

**Note:** There must be a blank line after the warning block.

### Step 4: Prepare final content

Store the warning + original content for submission.

## Submission Workflow

Submit review as comment (always use `--comment` flag):

```bash
gh pr review <PR_NUMBER> --comment --body "$(cat <<'EOF'
> ⚠️ **AI-Generated Review**: This review was generated by an AI assistant. Please use as guidance and verify findings independently.

<original review content here>
EOF
)"
```

**Handle submission errors:**
- If command fails, capture error message
- Report: "Error: Failed to submit review to PR #<number>. <error details>"

## Success Confirmation

After successful submission:

### Step 1: Get PR URL

```bash
gh pr view <PR_NUMBER> --json url -q .url
```

### Step 2: Report to user

```
✓ Review submitted successfully to PR #<number>
  PR URL: <url>
  Review file: <filename>
```

## Permissions

### Allowed

- **Read** files from `.opencode/review/` directory
- **Run bash** commands limited to:
  - `gh pr view`, `gh pr review --comment`, `gh repo view`, `gh auth status` (GitHub CLI read + submit comment)
  - `command -v gh` (check gh installation)
  - `git branch --show-current` (read current branch)
  - `ls`, `wc`, `sort` (file operations for review lookup)
  - `cat` (read review file content)
  - `test -d` (directory existence check)

### NOT Allowed

- Do NOT edit any source code files
- Do NOT modify or delete review files in `.opencode/review/`
- Do NOT run `gh pr review --approve` or `--request-changes` (only `--comment`)
- Do NOT run any git commands that modify repository (commit, push, merge, rebase, etc.)
- Do NOT write files anywhere
- Do NOT create directories

## Error Handling

Handle these common errors gracefully:

- **`gh` not found**:
  ```
  Error: GitHub CLI not found. Install from: https://cli.github.com/
  ```

- **Not authenticated**:
  ```
  Error: Not authenticated with GitHub. Run: gh auth login
  ```

- **No GitHub remote**:
  ```
  Error: This repository does not have a GitHub remote configured.
  ```

- **PR not found**:
  ```
  Error: PR #<number> not found. Verify the PR number and repository.
  ```

- **Review directory missing**:
  ```
  Error: .opencode/review/ directory not found. Generate a review first using the gh-pr-review skill.
  ```

- **No review file**:
  ```
  Error: No review found for PR #<number> in .opencode/review/
  ```

- **User cancelled**:
  ```
  Submission cancelled by user.
  ```

- **Invalid PR number**:
  ```
  Error: Please provide a valid PR number (e.g., 'submit review for PR #123').
  ```

- **Submission failed**:
  ```
  Error: Failed to submit review to PR #<number>. <gh error message>
  ```

## Edge Cases

### Closed or Merged PR

- Detect via `gh pr view <PR_NUMBER> --json state -q .state`
- If state is "CLOSED" or "MERGED":
  - Warn user: "Note: PR #<number> is <closed/merged>. Review will still be posted as a comment."
  - Ask: "Continue? (yes/no)"
  - If no → exit with "Submission cancelled by user."

### Detached HEAD state

- Detected when `git branch --show-current` returns empty
- Warn: "You are in detached HEAD state. PR #<number> targets `<target>`. Continue with submission? (yes/no)"
- If no → exit with "Submission cancelled by user."

### Cross-repo PR from fork

- Use `isCrossRepository` field from `gh pr view`
- Inform user about fork scenario
- Compare current branch with `headRefName` instead of `baseRefName`
- Include fork owner in confirmation message

### Empty or malformed review file

- Check line count < 10
- Warn: "Review file appears empty or very short. Continue with submission? (yes/no)"
- If no → exit with "Submission cancelled by user."

### Network/API errors

- Catch GitHub API errors from `gh` commands
- Report with context: "Error: GitHub API request failed. Check your internet connection and try again."

### Permission errors

- If user doesn't have write access to repository
- `gh` will return permission error
- Report: "Error: You don't have permission to comment on this PR. Contact the repository maintainer."

## Workflow Summary

1. Extract PR number from user input
2. Validate `gh` CLI installed and authenticated
3. Validate GitHub remote exists
4. Validate `.opencode/review/` directory exists
5. Fetch PR metadata and validate PR exists
6. Handle closed/merged PR state (warn and ask confirmation)
7. Get current branch (handle detached HEAD)
8. Get PR info (base branch, head branch, fork status)
9. Compare branches based on fork status; ask user confirmation if mismatch
10. Search for review file(s) matching PR number
11. If multiple files, ask user to choose; if none, error
12. Read review file and check if empty
13. Prepend AI warning header at the very top
14. Submit review using `gh pr review --comment`
15. Get PR URL and confirm success to user

## Complete Workflow Example

**Scenario:** User wants to submit a review for PR #456 in a repository where they're on a different branch than the PR target.

**User command:**
```
submit review for PR #456
```

**Execution steps:**

### 1. Extract PR number
- Parsed: `456`

### 2. Validate prerequisites (parallel)

```bash
command -v gh >/dev/null 2>&1 && echo "gh found"
# Output: gh found

gh auth status
# Output: ✓ Logged in to github.com as user123

gh repo view --json nameWithOwner -q .nameWithOwner
# Output: acme/analytics-app

test -d .opencode/review && echo "review dir exists"
# Output: review dir exists
```

### 3. Validate PR exists

```bash
gh pr view 456 --json number,state
# Output: {"number":456,"state":"OPEN"}
```

### 4. Get current branch

```bash
git branch --show-current
# Output: feature/new-dashboard
```

### 5. Get PR info and check for forks

```bash
gh pr view 456 --json baseRefName,headRefName,headRepository,isCrossRepository,headRepositoryOwner
# Output: {
#   "baseRefName": "main",
#   "headRefName": "feat/add-metrics",
#   "headRepository": {"nameWithOwner": "acme/analytics-app"},
#   "isCrossRepository": false,
#   "headRepositoryOwner": {"login": "acme"}
# }
```

### 6. Branch comparison

- Current branch: `feature/new-dashboard`
- PR source branch: `feat/add-metrics`
- PR target branch: `main`
- Not a cross-repo PR
- **Branches don't match!**

**Agent asks user:**
```
Your current branch is `feature/new-dashboard`, but PR #456 source branch is `feat/add-metrics` targeting `main`.
Continue with submission? (yes/no)
```

**User responds:** `yes`

### 7. Search for review files

```bash
ls -1 .opencode/review/*-pr-456-*.md 2>/dev/null | sort -r
# Output:
# .opencode/review/2026-02-23-1620-pr-456-add-metrics-feature.md
# .opencode/review/2026-02-23-1545-pr-456-add-metrics-feature.md
```

### 8. Multiple files found

**Agent asks user:**
```
Multiple reviews found for PR #456:
1. 2026-02-23-1620-pr-456-add-metrics-feature.md (most recent)
2. 2026-02-23-1545-pr-456-add-metrics-feature.md

Which one should I submit? (Enter 1, 2, or 'cancel')
```

**User responds:** `1`

### 9. Read review file

```bash
cat .opencode/review/2026-02-23-1620-pr-456-add-metrics-feature.md
# (reads file content - 245 lines)
```

### 10. Check file size

```bash
wc -l < .opencode/review/2026-02-23-1620-pr-456-add-metrics-feature.md
# Output: 245
# (File is not empty, proceed)
```

### 11. Prepend AI warning and prepare final content

```markdown
> ⚠️ **AI-Generated Review**: This review was generated by an AI assistant. Please use as guidance and verify findings independently.

# PR Review: #456 - Add Metrics Feature

**Date:** 2026-02-23 16:20
**Repository:** acme/analytics-app
**Author:** @jane-dev
**Branch:** feat/add-metrics -> main
**PR URL:** https://github.com/acme/analytics-app/pull/456
**Files changed:** 8 (+456/-32)
**State:** open

## PR Summary

This PR adds comprehensive metrics tracking for user activity...
(rest of review content)
```

### 12. Submit review

```bash
gh pr review 456 --comment --body "$(cat <<'EOF'
> ⚠️ **AI-Generated Review**: This review was generated by an AI assistant. Please use as guidance and verify findings independently.

# PR Review: #456 - Add Metrics Feature
...
EOF
)"
# Output: (success, no output)
```

### 13. Get PR URL

```bash
gh pr view 456 --json url -q .url
# Output: https://github.com/acme/analytics-app/pull/456
```

### 14. Report success to user

```
✓ Review submitted successfully to PR #456
  PR URL: https://github.com/acme/analytics-app/pull/456
  Review file: 2026-02-23-1620-pr-456-add-metrics-feature.md
```

**End of workflow.**
