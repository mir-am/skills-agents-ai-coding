---
name: gh-issue
description: Create a GitHub issue for a bug or feature idea found during an agent session
license: MIT
metadata:
  audience: developers
  workflow: github
  category: github-workflow
---

## What I do

- Ask user if this is a bug or feature request (if not already stated)
- Draft a concise, AI-agent-readable title and body from session context
- Apply `bug` or `enhancement` label (GitHub creates it if missing)
- Create the issue via `gh issue create` and return the URL

## When to use me

Use this skill when:
- User discovers a bug or has a feature idea during a session
- User wants to log it as a GitHub issue without losing the session context

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- Must be inside a git repo with a GitHub remote
- If `gh` not installed → error: "Error: GitHub CLI not found. Install: https://cli.github.com/"
- If no GitHub remote found → error: "Error: No GitHub remote found. Is this a GitHub repository?"

## Workflow

1. **Determine issue type**
   - If user did not specify → ask: "Is this a **bug** or a **feature request**?"
   - Map to label: bug → `bug`, feature request → `enhancement`

2. **Draft the issue from session context**
   - **Title**: short, imperative, ≤60 chars
     - Bug examples: `Fix null pointer in auth handler`, `Handle empty state in user list`
     - Feature examples: `Add dark mode toggle to settings`, `Support CSV export for reports`
   - **Body**: use the 3-field format below
   - **Label**: `bug` or `enhancement`

3. **Validate prerequisites**
   ```bash
   gh auth status
   git remote get-url origin
   ```

4. **Create the issue**
   ```bash
   gh issue create --title "<title>" --label "<bug|enhancement>" --body "<body>"
   ```

5. Return the issue URL to the user

## Issue Body Format

```
**Type:** Bug | Feature Request
**Context:** <1-2 sentences — what was happening in the session when this was found>
**Description:** <What needs to be done, written concisely for an AI agent to act on later>
```

## Title Guidelines

- Imperative mood, present tense (e.g. "Fix", "Add", "Support", "Handle")
- ≤60 characters
- No period at end
- Specific enough for an AI agent to understand the scope without extra context

## Body Guidelines

- Keep the entire body under 5 sentences total
- **Context**: what triggered this — what the agent/user was doing when the issue was discovered
- **Description**: actionable and self-contained — an AI agent should be able to open this issue cold and know what to do

## Error Handling

- `gh` not installed → `"Error: GitHub CLI not found. Install: https://cli.github.com/"`
- No GitHub remote → `"Error: No GitHub remote found. Is this a GitHub repository?"`
- Not authenticated → `"Error: Not authenticated with GitHub. Run: gh auth login"`
- Insufficient context to draft the issue → ask the user to describe it in 1-2 sentences
