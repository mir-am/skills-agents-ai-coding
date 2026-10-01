---
name: gh-pr-review
description: Review a GitHub Pull Request using gh CLI and provide structured feedback
license: MIT
metadata:
  audience: developers
  workflow: code-review
  category: git-workflow
---

## What I do

- Validate GitHub CLI (`gh`) is installed and authenticated
- Fetch PR metadata (title, body, author, branches, state)
- Retrieve full diff and list of changed files
- Generate structured code review with severity-based feedback
- Write review to `.opencode/review/` directory as markdown
- Warn on large PRs (>20 files) and ask user to confirm

## When to use me

Use this skill when the user asks to review a GitHub Pull Request by its number.

**Trigger examples:**
- "Review PR #123"
- "Review pull request 456"
- "Analyze PR 789"

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

## PR Number Extraction

Extract the PR number from user input:
- Pattern: `#?(\d+)` (supports with or without `#`)
- Examples: "#123" → 123, "PR 456" → 456, "pull request 789" → 789
- If no number found: "Error: Please provide a valid PR number (e.g., 'review PR #123')."

## Validation Workflow

1. **Validate prerequisites** (run in parallel):
   ```bash
   command -v gh >/dev/null 2>&1 && echo "gh found" || echo "gh not found"
   ```
   ```bash
   gh auth status
   ```
   ```bash
   gh repo view --json nameWithOwner -q .nameWithOwner
   ```

2. **Validate PR exists**:
   ```bash
   gh pr view <PR_NUMBER> --json number,state
   ```
   - If fails: "Error: PR #<number> not found. Verify the PR number and repository."

## Data Gathering Workflow

After validation passes, fetch PR data in parallel:

### 1. Get PR Metadata
```bash
gh pr view <PR_NUMBER> --json title,body,author,baseRefName,headRefName,number,state,url,additions,deletions
```

Parse the JSON output to extract:
- `title` - PR title
- `body` - PR description
- `author.login` - Author username
- `baseRefName` - Base branch (e.g., main)
- `headRefName` - Head branch (e.g., feature-branch)
- `number` - PR number
- `state` - open/closed/merged
- `url` - PR URL
- `additions` - Lines added
- `deletions` - Lines deleted

### 2. Get Changed Files with Stats
```bash
gh pr view <PR_NUMBER> --json files -q '.files[] | "\(.path) +\(.additions)/-\(.deletions)"'
```

Also get file count for large PR check:
```bash
gh pr view <PR_NUMBER> --json files -q '.files | length'
```

### 3. Get Full Diff
```bash
gh pr diff <PR_NUMBER>
```

This returns the unified diff for all changes in the PR.

## Large PR Check

After getting the file count:

```bash
FILE_COUNT=$(gh pr view <PR_NUMBER> --json files -q '.files | length')

if [ "$FILE_COUNT" -gt 20 ]; then
  # Inform user: "This PR has $FILE_COUNT files changed."
  # Ask: "Continue with review? Large PRs may take time to review thoroughly."
  # Wait for user confirmation (yes/no)
  # If no → exit with: "Review cancelled by user."
  # If yes → proceed and add note to General Observations:
  #   "Note: Large PR with $FILE_COUNT files. Review may not be exhaustive."
fi
```

## Review Guidelines

Focus your review on:

- **Code quality** - Clean code, proper abstractions, SOLID principles
- **Potential bugs** - Edge cases, null checks, error handling, race conditions
- **Performance** - Inefficient algorithms, unnecessary loops, memory leaks
- **Security** - SQL injection, XSS, auth bypass, sensitive data exposure
- **Maintainability** - Readability, documentation, test coverage

### Review Principles

- Be specific: reference exact lines and code snippets
- Be constructive: suggest fixes, don't just point out problems
- Be concise: every comment should be short and to the point
- Stay proportional: prioritize critical issues over nitpicks
- Skip files with no issues: don't write "no issues found"
- **No positive feedback**: only document issues, no "good job" comments

## Severity Levels

Use these labels in issue descriptions:

- **[critical]** - Bugs, security vulnerabilities, data loss risks. Must fix before merge.
- **[warning]** - Potential problems, performance issues, bad patterns. Should fix.
- **[suggestion]** - Style improvements, better approaches, minor enhancements. Nice to have.
- **[question]** - Unclear intent, needs clarification from the author.

## Code Reference Lookups

When reviewing diffs, you may need to look up code not visible in the diff:

### When to Look Up

- Function signature unclear from diff
- Need to verify how a shared constant/type is used
- Import statement references unfamiliar module
- Unclear how a called function behaves

### How to Look Up (conservatively)

1. **Use Grep first** to pinpoint definitions:
   ```bash
   grep -r "function functionName" .
   grep -r "class ClassName" .
   grep -r "type TypeName" .
   ```

2. **Use Glob** to locate related files:
   ```bash
   glob "**/*test*.{ts,js}"  # Find test files
   glob "**/*.types.{ts,d.ts}"  # Find type definitions
   ```

3. **Use Read only when necessary**:
   - Read specific files to understand context
   - Avoid reading all changed files upfront
   - Avoid reading large dependency files

### Important: Load Context Conservatively

- **Do NOT** read all changed files or their imports upfront
- **Do NOT** load many files at the start (saturates context window)
- **Only** read when you have a specific, concrete reason
- **Prefer** Grep to pinpoint a single definition first
- Repositories can be large - fetch minimum context, exactly when needed

## Review Output

### Output Location

Write the review to: `.opencode/review/<filename>.md`

1. **Create directory** (if it doesn't exist):
   ```bash
   mkdir -p .opencode/review
   ```

2. **Generate filename**:
   - Format: `YYYY-MM-DD-HHmm-pr-<NUMBER>-<sanitized-title>.md`
   - Get timestamp: `date +%Y-%m-%d-%H%M`
   - Sanitize PR title:
     - Lowercase
     - Spaces → hyphens
     - Remove special characters (keep alphanumeric and hyphens)
     - Take first 5 words max
   - Example: `2026-02-23-1545-pr-123-add-csv-export-feature.md`

### Review Structure

```markdown
# PR Review: #<NUMBER> - <TITLE>

**Date:** YYYY-MM-DD HH:mm
**Repository:** <owner/repo>
**Author:** @<author>
**Branch:** <head> -> <base>
**PR URL:** <url>
**Files changed:** <count> (+<additions>/-<deletions>)
**State:** <open/closed/merged/draft>

## PR Summary

<2-3 sentence overview of what the PR does, based on title and body>

## File Reviews

### `path/to/file1.ext`

**Changes:** <brief description of what changed in this file>

#### Issues

- **[severity]** <description of issue>
  - Line(s): <line reference in the diff or file>
  - Suggestion: <how to fix or improve>

- **[severity]** <description of issue>
  - Line(s): <line reference>
  - Suggestion: <how to fix>

(Repeat for each file with meaningful review comments.
Skip files with no issues - do NOT write "no issues found".)

## General Observations

- <cross-cutting concern 1>
- <cross-cutting concern 2>
- <pattern noticed across files>

(Only include if there are observations that span multiple files.
Omit this section if not applicable.)

## Verdict

**<APPROVE | REQUEST_CHANGES | COMMENT>**

<1-2 sentence justification>
```

### Verdict Guidelines

- **APPROVE**: No critical or warning issues. Only suggestions/questions if any.
- **REQUEST_CHANGES**: Has critical issues or multiple warning-level issues that must be fixed.
- **COMMENT**: Has some suggestions/questions but no blocking issues.

## Permissions

### Allowed

- **Write** markdown review files ONLY to `.opencode/review/` directory
- **Read** any source file in the repository for context (to understand code referenced in diffs)
- **Run bash** commands limited to:
  - `gh pr view`, `gh pr diff`, `gh repo view` (read-only GitHub CLI commands)
  - `command -v gh` (check gh installation)
  - `mkdir -p .opencode/review` (create output directory)
  - `date` (timestamp generation)
- **Use tools**: Grep, Glob for code lookups

### NOT Allowed

- Do NOT write files to any location other than `.opencode/review/`
- Do NOT edit any existing source code files
- Do NOT run `gh pr review` commands (no posting to GitHub)
- Do NOT run any git commands that modify the repository
- Do NOT run build, test, or install commands
- Do NOT create or modify any files outside `.opencode/review/`

## Workflow Summary

1. Extract PR number from user input
2. Validate `gh` CLI installed and authenticated
3. Validate GitHub remote exists
4. Fetch PR metadata and validate PR exists
5. Get changed files count
6. If file count >20, warn user and ask to confirm; exit if declined
7. Fetch full PR diff and file stats
8. Create `.opencode/review/` directory if needed
9. Review each file's changes, looking up code references conservatively as needed
10. Generate review filename with timestamp and sanitized title
11. Write structured review markdown to `.opencode/review/`
12. Report file path to user

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

- **PR not found**:
  ```
  Error: PR #<number> not found. Verify the PR number and repository.
  ```

- **No GitHub remote**:
  ```
  Error: This repository does not have a GitHub remote configured.
  ```

- **Invalid PR number**:
  ```
  Error: Please provide a valid PR number (e.g., 'review PR #123').
  ```

- **User declined large PR review**:
  ```
  Review cancelled by user.
  ```

## Edge Cases

### Draft PRs

- Note in review header: `**State:** draft`
- Proceed with review normally
- Consider adding note: "PR is in draft state; may change significantly."

### Closed or Merged PRs

- Note the state in header: `**State:** closed` or `**State:** merged`
- Proceed with review (historical review is still valuable)

### Binary Files

- Skip binary files in file reviews
- Add note in General Observations if many binary files:
  ```
  Note: Skipped binary files: image.png, data.bin, font.woff2
  ```

### Generated Files

Identify and skip auto-generated files:
- `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- `dist/`, `build/`, `.next/`, `.nuxt/`
- `*.min.js`, `*.bundle.js`
- Files with header comments like "DO NOT EDIT" or "AUTO-GENERATED"

Add note if significant:
```
Note: Skipped generated files: package-lock.json (12,000 lines)
```

### Very Large Diffs

If individual file diff exceeds 200 lines:
- Include first 100 lines in review context
- Add note in file review:
  ```
  Note: Diff truncated (500+ lines). Run `gh pr diff <PR_NUMBER> -- path/to/file` for full changes.
  ```

### Empty PR

If PR has 0 files changed:
```
Error: PR #<number> has no file changes to review.
```

### Cross-Repo PRs (from forks)

- `gh` handles this automatically
- Note in General Observations if relevant: "PR from fork: <fork-owner>/<repo>"

## Example Complete Review

```markdown
# PR Review: #123 - Add CSV Export Functionality

**Date:** 2026-02-23 15:45
**Repository:** acme/analytics-app
**Author:** @jane-dev
**Branch:** feat/csv-export -> main
**PR URL:** https://github.com/acme/analytics-app/pull/123
**Files changed:** 5 (+312/-28)
**State:** open

## PR Summary

This PR adds CSV export functionality for user analytics data with configurable column selection and validation for large datasets. Includes new exporter class, UI updates to the export button, and basic error handling.

## File Reviews

### `src/exporters/csv-exporter.ts`

**Changes:** New file implementing CSVExporter class with column configuration and data formatting

#### Issues

- **[warning]** Missing error handling for invalid column names
  - Line(s): 23-27 (formatRow method)
  - Suggestion: Add validation to check if column exists in data object before accessing. Throw descriptive error or skip invalid columns with warning.

- **[warning]** No escaping for special CSV characters (quotes, commas, newlines)
  - Line(s): 31 (escapeValue method stub)
  - Suggestion: Implement proper CSV escaping: wrap values with quotes in quotes, escape embedded quotes as double quotes.

- **[suggestion]** Hard-coded comma delimiter
  - Line(s): 15, 32
  - Suggestion: Make delimiter configurable via ExportOptions (support tabs, semicolons for international use).

### `src/components/ExportButton.tsx`

**Changes:** Updated component to use new CSVExporter with hardcoded column configuration

#### Issues

- **[critical]** Hard-coded column names will break if data structure changes
  - Line(s): 12 (columns: ['name', 'email', 'role'])
  - Suggestion: Accept columns as prop from parent component or derive from data object keys dynamically.

- **[question]** No loading state during export
  - Line(s): 10-14 (handleExport function)
  - Suggestion: For large datasets, export may block UI. Consider adding loading indicator or async processing.

### `src/types/export.types.ts`

**Changes:** Added ExportOptions interface

#### Issues

- **[suggestion]** Missing JSDoc comments
  - Line(s): 1-4
  - Suggestion: Add JSDoc to document what each option does, especially `columns` field purpose and format.

### `tests/csv-exporter.test.ts`

**Changes:** Basic unit tests for CSVExporter class

#### Issues

- **[warning]** Missing edge case tests
  - Line(s): Overall test coverage
  - Suggestion: Add tests for: empty dataset, null values, special characters in data, invalid columns, large datasets (performance).

## General Observations

- Missing error handling is a recurring theme across the implementation. Add comprehensive validation and error messages.
- No integration test for the full export flow (UI button → exporter → file download).
- Consider extracting export logic to a service/hook to keep ExportButton component focused on UI.
- Documentation for the export feature is not included. Update user-facing docs if applicable.

## Verdict

**REQUEST_CHANGES**

Critical issue with hard-coded columns in ExportButton must be fixed. Multiple warning-level issues around error handling and CSV escaping should be addressed before merge to ensure robustness.
```
