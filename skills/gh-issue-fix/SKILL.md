---
name: gh-issue-fix
description: Pick up a GitHub issue and implement a fix or feature with a user-approved plan
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
  category: development
---

## What I do

- Fetch a GitHub issue by number or URL using the `gh` CLI
- Ask clarifying questions if the issue description is too vague to act on
- Explore the codebase to identify affected files and root causes
- Generate a structured implementation plan and present it to the user
- Wait for explicit user approval before making any code changes
- Create a new branch (if on `main`/`master`) after plan approval
- Implement the fix or feature following the approved plan
- Run relevant tests and summarize changes
- Optionally hand off to `git-commit` and `git-pr` skills

## When to use me

- A GitHub issue number or URL is provided by the user
- The user says "fix issue #123", "implement issue #456", or similar
- The user wants a structured, plan-first approach before touching code

---

## Phase 1: Issue Intake

1. If the user provided an issue number or URL, use it directly.
   If not, ask:
   > "Which GitHub issue should I work on? Please provide the issue number or URL."

2. Fetch the issue details:
   ```bash
   gh issue view <number> --json number,title,body,labels,comments,assignees,state
   ```

3. Evaluate the issue description:
   - If the title and body clearly describe the problem or feature, proceed to Phase 2.
   - If the description is thin (e.g. one-liners, missing reproduction steps, no acceptance criteria), ask targeted clarifying questions before continuing. Examples:
     - "Can you describe the expected vs actual behavior?"
     - "Is there a specific file or area of the codebase involved?"
     - "What does 'done' look like for this feature?"
   - Collect answers and incorporate them into the plan.

---

## Phase 2: Codebase Exploration

Use Read, Glob, and Grep tools to explore the codebase relevant to the issue:

1. Search for keywords from the issue title and body:
   ```bash
   rg "<keyword>" -l
   ```

2. Identify:
   - Files most likely to need changes
   - Related tests
   - Entry points, interfaces, or API contracts involved
   - Any existing error handling or edge cases nearby

3. Read the relevant files to understand the current implementation before forming the plan.

---

## Phase 3: Plan & Approval

Present a structured plan to the user. Do NOT make any code changes yet.

Format the plan as follows:

```
## Plan for Issue #<number>: <title>

### Root Cause / Requirements
<For bugs: explain the root cause found during exploration.>
<For features: list the requirements and acceptance criteria.>

### Files to Change
- `path/to/file.ts` — reason
- `path/to/test.ts` — reason

### Implementation Steps
1. <Step one>
2. <Step two>
3. ...

### Test Strategy
- <How the fix/feature will be verified>
- <Existing tests to run, new tests to add>
```

Then ask:
> "Does this plan look good? Reply 'yes' to proceed, or let me know what to change."

**Do not proceed until the user explicitly approves.**

---

## Phase 3b: Branch Creation

After the user approves the plan:

1. Check the current branch:
   ```bash
   git branch --show-current
   ```

2. If the current branch is `main` or `master`:
   - Determine the branch prefix from the issue labels:
     - `bug` label → `fix/`
     - `enhancement` or `feature` label → `feat/`
     - anything else → `chore/`
   - Derive a short slug from the issue title (lowercase, hyphenated, max 5 words).
   - Proposed branch name format: `<prefix><issue-number>-<slug>`
     - Example: `fix/123-null-pointer-on-login`
     - Example: `feat/456-add-dark-mode`
   - Inform the user of the branch name and create it:
     ```bash
     git checkout -b <branch-name>
     ```

3. If already on a feature branch (not `main`/`master`), skip branch creation silently and continue.

---

## Phase 4: Implementation

Execute the approved plan step by step:

1. Make code changes using Edit and Write tools, following the existing code style and conventions of the project.
2. After completing changes, run the relevant tests:
   ```bash
   # Adapt to the project's test runner (npm test, pytest, go test, etc.)
   ```
3. If tests fail, diagnose and fix before proceeding.
4. Do a final review of all changes to ensure correctness and completeness.

---

## Phase 5: Wrap-up

1. Summarize the changes made:
   - Which files were modified and why
   - How the fix addresses the issue or the feature meets requirements
   - Test results

2. Offer next steps:
   > "Changes are ready. Would you like me to:
   > - Commit using the `git-commit` skill?
   > - Open a pull request using the `git-pr` skill?
   > - Both?"

3. Invoke the appropriate skills based on the user's response.
