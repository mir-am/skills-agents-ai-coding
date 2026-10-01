# Mir's Agents & Skills for AI Coding Assistants 🤖

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Reusable skills for AI coding assistants like Claude Code, Codex, GitHub Copilot, Cursor, and OpenCode, plus OpenCode-specific agents.

## Install

Install skills globally:

```bash
npx skills add mir-am/skills-agents-ai-coding -g
```

<details>
<summary>Update installed skills</summary>

```bash
npx skills@latest update -g
```

</details>

For more installation options, see the [Skills CLI docs](https://github.com/vercel-labs/skills#readme).

## Available Skills 🧠

Skills are grouped by workflow to make related capabilities easier to discover.

### Git Workflow

| Skill | What it does | Requirements |
| --- | --- | --- |
| `git-branch` | Create a descriptive feature branch from the repo default branch using session context and current staged/unstaged changes. | `git` |
| `git-commit` | Smart git commit with branch protection, session-aware staging, and conventional commits. | `git` |
| `git-push` | Push commits to the feature branch, update the open PR description with new changes, and commit/push any synced `CHANGELOG.md` update to the same branch. | `git`, GitHub CLI (`gh`) |

### GitHub Workflow

| Skill | What it does | Requirements |
| --- | --- | --- |
| `gh-issue` | Create a GitHub issue for a bug or feature idea found during an agent session. | `git`, GitHub CLI (`gh`) |
| `gh-issue-fix` | Take a GitHub issue through planning, implementation, testing, commits, and a linked PR without routine approval pauses; the issue closes when the PR is merged. | `git`, GitHub CLI (`gh`) |
| `gh-pr` | Create GitHub pull requests with a smart title and description from branch commits, self-assign them to the authenticated `gh` user, and commit/push any synced `CHANGELOG.md` entry back to the same PR branch. | `git`, GitHub CLI (`gh`) |
| `gh-pr-merge` | Squash-merge a GitHub PR after checking merge requirements, verify the result, and delete the branch only when requested. | GitHub CLI (`gh`) |
| `gh-protect-default-branch` | Protect the default branch from direct pushes so changes land only via pull requests. | GitHub CLI (`gh`), repository admin permissions |

### Code Review

| Skill | What it does | Requirements |
| --- | --- | --- |
| `gh-pr-review` | Review a GitHub pull request using `gh`, fetch PR metadata and diffs, and generate structured feedback focused on quality, bugs, performance, and security. | `git`, GitHub CLI (`gh`) |
| `gh-cr-submit` | Submit AI-generated code review from `.opencode/review/` to GitHub PR, validate branch matching, handle forks, and add an AI-generated warning header before submission. | `git`, GitHub CLI (`gh`) |
| `gh-copilot-review` | Request a GitHub Copilot review for a PR via `gh` CLI. | GitHub CLI (`gh`) |
| `gh-copilot-review-read` | Read GitHub Copilot PR review comments, pair them with suggestions when present, and write a markdown digest to `.opencode/review/`. | GitHub CLI (`gh`) |
| `gh-copilot-review-resolve` | Resolve selected GitHub Copilot PR review threads with cautious defaults, posting `addressed` or `ignored` replies via `gh` GraphQL before resolving each thread. | GitHub CLI (`gh`) |

### Release & Changelog

| Skill | What it does | Requirements |
| --- | --- | --- |
| `changelog-bump-ver` | Promote `CHANGELOG.md` unreleased notes into the next release, infer the current SemVer bump style when possible, add a dated release heading, recreate an empty `[Unreleased]` template with `Misc` at the end, and update direct Maven project versions in `pom.xml` files to the next development `-SNAPSHOT` version. | none |
| `make-changelog` | Create an initial `CHANGELOG.md` with unreleased entries using Keep a Changelog format plus a `Misc` section for notable code changes that do not fit the standard sections. | `git` |
| `gh-release` | Create an annotated git tag and GitHub prerelease from the latest versioned `CHANGELOG.md` entry, preserve the repo's `Misc` subsection when present, and append a full changelog compare link. | `git`, GitHub CLI (`gh`) |

### Project Setup

| Skill | What it does | Requirements |
| --- | --- | --- |
| `mir-skills-install` | Install all repository skills globally for Codex, Claude Code, GitHub Copilot, and OpenCode without interactive prompts. | Node.js and npm (`npx`) |
| `python-venv` | Create or reuse a project-root `.venv`, preserve invalid existing paths, and ensure the root `.gitignore` excludes the environment without duplicate rules on repeated runs. | Python 3 with `venv`, `git`, Bash/POSIX environment |

### Planning & Notes

| Skill | What it does | Requirements |
| --- | --- | --- |
| `save-plan` | Save or update the agent's current plan to `.opencode/plans/` in the working project. | none |
| `session-note` | Capture the current work session into a markdown note for continuity. | none |
| `work-report` | Write a self-contained markdown report to `.opencode/notes/` describing the problem, solution, project context, git-visible changed files, concise step log, and per-file patches for review or handoff. | none |

> Note: Use GitHub CLI (gh) v2.88.0+ to get the latest supported gh functionality used by these skills.

## Available Agents

### code-review
Reviews feature branch diffs for quality, bugs, performance, and security. Writes a structured review to `.opencode/review/`.

**Requirements:** git

## Documentation

- [Creating OpenCode Skills](https://opencode.ai/docs/skills/)
- [Creating OpenCode Agents](https://opencode.ai/docs/agents/)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [GitHub Copilot Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Agent Skills Specification](https://agentskills.io/) - An open format for creating reusable agent skills.
