---
name: work-report
description: Write a self-contained markdown report of the work done, changed files, concise decision steps, and applied patches
license: MIT
metadata:
  audience: developers
  workflow: productivity
  category: reporting
---

## What I do

- Create `.opencode/notes/` directory in the project if it doesn't exist
- Generate one timestamped markdown report file: `YYYY-MM-DD-HHmm-<description>.md`
- Explain the user's problem, the proposed solution, and why the change matters
- Add enough project and code context for humans and other AI agents to review the work without digging deeply into the repository
- List changed files visible in git, grouped by created, modified, renamed, and deleted
- Capture a concise step-by-step work log describing what the agent inspected, decided, and changed
- Include per-file patch sections with fenced `diff` blocks
- Use hybrid patch handling: full patches for small files, truncated patches for large files with a `git diff` reference
- Record tests or validations that were run, if any

## When to use me

Use this skill when:
- User asks for a report of the work completed
- User wants a self-contained handoff artifact for later continuation or review
- Agent finishes meaningful code, docs, or config changes and the result should be documented in one place

## Report Workflow

1. **Create directory**:
   ```bash
   mkdir -p .opencode/notes
   ```

2. **Generate filename**:
   - Extract the main task from conversation context
   - Format: `YYYY-MM-DD-HHmm-<brief-description>.md`
   - Example: `2026-04-01-1430-add-work-report.md`
   - Description should be kebab-case, concise, and no more than 4-5 words
   - Fallback: `work-report`

3. **Gather task context**:
   - Identify the problem the user wanted solved
   - Identify the scope of work the agent completed
   - Summarize the proposed solution chosen by the agent
   - Capture why this change matters to the user or project

4. **Gather project context**:
   - Identify the subsystem, feature area, or workflow touched
   - Summarize how the relevant part of the project worked before the change
   - Note important constraints, conventions, or related files reviewers should know
   - Include only context that helps understand or review the change; avoid dumping unrelated repo background

5. **Detect file changes**:
   - If git repo: run `git status --short`
   - Parse statuses into created, modified, renamed, and deleted
   - Prefer git-visible files over conversational guesses when both are available
   - If not a git repo: extract changed files from the session/tool history and say so clearly in the report

6. **Collect patches**:
   - For modified, renamed, and deleted files: `git diff -- <file>`
   - For staged new files: `git diff --cached -- <file>` if needed
   - For untracked new files: include key file content sections instead of an unavailable git diff
   - Use full patch blocks for small diffs
   - Use truncated patch blocks for large diffs and add `Run \`git diff -- <file>\` for the full patch.`

7. **Capture concise thought process**:
   - Do not expose raw private chain-of-thought
   - Write a short, observable step log instead
   - Each step should describe:
     - what was inspected or inferred
     - what decision was made
     - what change followed
   - Keep it concise and factual

8. **Write the report** using the structure below

9. **Confirm**:
   - Tell the user the report path
   - Briefly mention the kind of context captured

## Report Structure

```markdown
# Work Report: <Descriptive Title>

**Date:** YYYY-MM-DD HH:mm
**Branch:** <current-branch> (only if git repo)

## Problem To Solve
<1-3 short paragraphs explaining what the user wanted solved>

## Why This Matters
<brief explanation of impact, motivation, or pain point>

## Proposed Solution
<concise explanation of the selected approach>

## Project Context
<self-contained context about the relevant part of the project, prior behavior, touched workflow, and key related files>

## What Changed
- <high-value change 1>
- <high-value change 2>
- <high-value change 3>

## Files Changed

### Created
- `path/to/new-file.ext` - <what role it plays>

### Modified
- `path/to/existing-file.ext` - <what changed and why>

### Renamed
- `old/path.ext` -> `new/path.ext` - <why>

### Deleted
- `path/to/old-file.ext` - <why removed>

(Only include sections that apply)

## Step-by-Step Work Log
1. Inspected `<file or area>` to understand <relevant behavior or constraint>.
2. Decided to <chosen approach> because <brief reason>.
3. Updated `<file>` to <change>.
4. Added or adjusted `<tests/docs/config>` to keep the change coherent.

## Patches Applied

### `path/to/file1.ext`
Role: <why this file matters to the change>

```diff
<full patch for small change, or truncated patch for large change>
```

Short explanation: <what this patch accomplishes>

### `path/to/file2.ext`
Role: <why this file matters to the change>

```diff
<patch>
... (patch truncated, run `git diff -- path/to/file2.ext` for the full patch)
```

Short explanation: <what this patch accomplishes>

## Validation
- `<command>` - <result>
- Manual check: <result>

(Only include if validations were run)

## Next Steps
1. <follow-up step>
2. <follow-up step>
3. <follow-up step>

(Only include if meaningful follow-up exists)
```

## Patch Handling Rules

- **Hybrid mode**:
  - Include the full patch when the file diff is small and readable
  - Truncate larger patches to the most relevant first section plus a clear `git diff` reference
- **Large diff threshold**:
  - If a patch exceeds about 80 lines, truncate it unless the full patch is still easy to review
- **New untracked files**:
  - Show the most relevant first 30-60 lines or key sections
  - Make clear that the block is file content context when a git diff is unavailable
- **Binary files**:
  - Do not dump binary output; describe the file and its role instead
- **Generated files**:
  - Prefer summarizing their purpose unless the generated output itself is the important artifact

## File Change Detection

**With git:**
```bash
git status --short
```

Parse output:
- `M  file.ext` or `MM file.ext` -> Modified
- `A  file.ext` or `?? file.ext` -> Created
- `R  old.ext -> new.ext` -> Renamed
- `D  file.ext` -> Deleted

**Without git:**
- Extract changed files from session context and tool usage
- State clearly: `Files listed from session activity because git status was unavailable.`

## Context Guidance

The report should be self-sufficient for review. Include enough context so a reviewer can understand:
- what the user asked for
- what part of the project was touched
- how the relevant code or workflow behaved before the change
- why the chosen approach is plausible
- where to look if something seems off

Do not try to summarize the entire project. Include only the context needed to review this work responsibly.

## Edge Cases

- **No files changed**: Still write the report, focusing on analysis, plan, or investigation completed
- **No git repo**: Omit branch info and explain that file tracking came from session activity
- **No validations run**: Omit the `Validation` section entirely
- **No meaningful next steps**: Omit the `Next Steps` section entirely
- **Multiple calls in one session**: Create a new timestamped report each time
- **Very large multi-file change**: Keep the top-level summary compact and make each file subsection do the explanatory work
- **Deleted file**: Explain what replaced it or why it was no longer needed

## Example Title And Filename

- Title: `Work Report: Add Self-Contained Change Reporting Skill`
- Filename: `2026-04-01-1430-add-change-reporting.md`
