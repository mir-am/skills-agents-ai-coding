---
name: gh-copilot-review-read
description: Read GitHub Copilot PR review comments, pair them with diff context, and write a markdown digest to .opencode/review/
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
  category: github-workflow
---

## What I do

- Accept a GitHub pull request URL or PR number
- Fetch PR metadata, diff, reviews, and review comments via GitHub CLI (`gh`)
- Detect comments authored by GitHub Copilot or Copilot-related bot accounts
- Render a GitHub-style location header for each comment from the API line metadata
- Write a readable markdown digest to `.opencode/review/`
- Return the saved file path to the user

## When to use me

Use this skill when:
- User wants a local markdown summary of Copilot review comments on a PR
- User wants Copilot feedback preserved outside GitHub for later review
- User wants AI review feedback exported from GitHub into a clean local markdown file
- User wants the raw Copilot wording and inline code suggestions copied exactly into a local note

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- If given only a PR number, the current repository must have a GitHub `origin` remote
- The target PR must be accessible with the current GitHub credentials
- If `gh` not installed -> error: `Error: GitHub CLI not found. Install: https://cli.github.com/`
- If not authenticated -> error: `Error: Not authenticated with GitHub. Run: gh auth login`

## Input Handling

Accept either of these forms:

- Full GitHub PR URL
  - Example: `https://github.com/owner/repo/pull/123`
- PR number
  - Example: `123`

### Resolution Rules

1. If input is a full PR URL:
   - Use it directly with `gh pr view <url>` and related `gh` commands.
2. If input is a PR number:
   - Resolve repository from `git remote get-url origin`
   - Derive `owner/repo`
   - Build the API path from that repository and PR number
3. If the input is neither a valid URL nor a PR number:
   - Error: `Error: Provide a GitHub PR URL or PR number`

## Workflow

1. **Validate GitHub access**
   ```bash
   gh auth status
   ```

2. **Resolve PR and fetch metadata**
   - For PR URL, use:
     ```bash
     gh pr view <pr> --json number,title,url,author,baseRefName,headRefName,changedFiles,additions,deletions
     ```
   - For PR number in current repo, verify remote:
     ```bash
     git remote get-url origin
     gh pr view <number> --json number,title,url,author,baseRefName,headRefName,changedFiles,additions,deletions
     ```

3. **Fetch reviews and review comments**
   ```bash
   gh api repos/<owner>/<repo>/pulls/<number>/reviews --paginate
   gh api repos/<owner>/<repo>/pulls/<number>/comments --paginate
   ```

4. **Identify Copilot-authored feedback**
   - Match exact known Copilot review identities first, including `Copilot` and `copilot-pull-request-reviewer[bot]`
   - Then match review/comment authors whose login contains `copilot`
   - Treat likely bot/service accounts as Copilot feedback when the login clearly indicates Copilot
   - Ignore human reviewer comments

5. **Preserve comment text exactly**
   - Copy each Copilot comment body exactly as returned by GitHub
   - Do not paraphrase, rewrite, or normalize the wording
   - Preserve markdown, fenced code blocks, suggestion blocks, bullets, and links exactly
   - Keep suggestion blocks inside `Original Copilot Comment`; do not split them into a separate section

6. **Render comment location from API metadata**
   - Use the structured comment fields such as `path`, `line`, `start_line`, `side`, `start_side`, and `subject_type`
   - Do not claim this exact header came from a single API field; it is composed from the metadata
   - Render a GitHub-style location header such as:
     - `sync.sh`
     - `Comment on lines +42 to +50`
   - For single-line comments, render a concise variant such as:
     - `Comment on line +141`
   - Use `+` for right-side/new lines and `-` for left-side/old lines when deriving the displayed line marker
   - If both `start_line` and `line` are present and different, show a range; otherwise show a single line

7. **Create output directory**
   ```bash
   mkdir -p .opencode/review
   ```

8. **Generate filename**
   - Format: `YYYY-MM-DD-HHmm-pr-<number>-copilot-review-digest.md`
   - Timestamp command:
     ```bash
     date +%Y-%m-%d-%H%M
     ```

9. **Write digest**
      - Save markdown to `.opencode/review/<filename>.md`
      - Return the saved path to the user

## Output Structure

Write the review digest using this structure:

```markdown
# Copilot Review Digest: PR #<number> <title>

**PR:** <url>
**Author:** <author>
**Branch:** <head> -> <base>
**Files changed:** <count>
**Lines:** +<additions> / -<deletions>
**Generated:** YYYY-MM-DD HH:mm

## Overview

<2-4 sentence summary of what the PR changes and what Copilot flagged>

## Copilot Findings

### `path/to/file.ext`

Comment on lines +42 to +50

#### Finding 1

**Original Copilot Comment:**
<exact Copilot review comment body copied unchanged>

**GitHub link:** <comment html url if available>

#### Finding 2

...

## General Notes

- <cross-cutting observation>
- <pattern across multiple comments>

## Raw Review Stats

- Total reviews fetched: <n>
- Total review comments fetched: <n>
- Copilot comments included: <n>
```

## Writing Guidelines

- Keep the markdown readable and skimmable
- Group findings by file path when possible
- Preserve the original Copilot wording exactly; do not rewrite or summarize the comment body
- Preserve any code fences, suggestion blocks, and markdown formatting exactly as GitHub returned them inside `Original Copilot Comment`
- Treat the comment `body` as source text; copy it exactly as returned by the API, including punctuation, quotes, and whitespace-sensitive markdown
- Add a short synthesized overview, but do not invent issues not present in the review data
- If multiple Copilot comments hit the same file, keep them under one file heading
- If no Copilot comments are found, still write a digest file with an overview and a note saying no Copilot-authored feedback was detected

## Suggested Title and Filename Style

- Document title: `Copilot Review Digest: PR #123 Improve sync reporting`
- Filename: `2026-03-06-1530-pr-123-copilot-review-digest.md`

## Data Sources

Prefer structured API data over scraped terminal text:

- PR metadata: `gh pr view --json ...`
- Reviews: `gh api repos/<owner>/<repo>/pulls/<number>/reviews --paginate`
- Review comments: `gh api repos/<owner>/<repo>/pulls/<number>/comments --paginate`

Never replace raw Copilot material with a paraphrased version.

## Error Handling

- Invalid input -> `Error: Provide a GitHub PR URL or PR number`
- `gh` missing -> `Error: GitHub CLI not found. Install: https://cli.github.com/`
- Not authenticated -> `Error: Not authenticated with GitHub. Run: gh auth login`
- No GitHub remote for PR number mode -> `Error: No GitHub remote found. Provide a full PR URL or set origin`
- PR not found or inaccessible -> `Error: Unable to access the pull request with current GitHub credentials`
- No Copilot comments found -> write the digest anyway and state that no Copilot-authored comments were detected

## Notes

- Use `gh` CLI only; no separate GitHub SDK is required
- Favor raw GitHub-provided comment text over synthesized summaries
- This skill is read-oriented: it should not modify code, update the PR, or post replies
