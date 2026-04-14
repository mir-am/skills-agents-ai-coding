# Mir's Agents & Skills for AI Coding Assistants

Reusable Agent Skills and agents for CLI coding assistants.

This repository stores skills in the open Agent Skills format and supports syncing them to multiple CLIs:

- OpenCode (`oc`)
- GitHub Copilot CLI (`ghc`)
- Claude Code (`cc`)

It also includes OpenCode-specific agents in `agents/`.

Skill source files in this repository keep OpenCode-style workspace paths like `.opencode/...`. During target-specific sync, `sync.sh` rewrites those skill instructions before installing them:

- `ghc` sync rewrites `.opencode/...` to `.copilot/...`
- `cc` sync rewrites `.opencode/...` to `.claude/...`

## Available Skills

Skills are grouped by workflow to make related capabilities easier to discover.

### Git Workflow

| Skill | What it does | Requirements |
| --- | --- | --- |
| `git-commit` | Smart git commit with branch protection, session-aware staging, and conventional commits. | `git` |
| `git-pr` | Create GitHub pull requests with a smart title and description from branch commits, self-assign them to the authenticated `gh` user, and commit/push any synced `CHANGELOG.md` entry back to the same PR branch. | `git`, GitHub CLI (`gh`) |
| `git-push` | Push commits to the feature branch, update the open PR description with new changes, and commit/push any synced `CHANGELOG.md` update to the same branch. | `git`, GitHub CLI (`gh`) |

### GitHub Workflow

| Skill | What it does | Requirements |
| --- | --- | --- |
| `gh-issue` | Create a GitHub issue for a bug or feature idea found during an agent session. | `git`, GitHub CLI (`gh`) |
| `gh-issue-fix` | Pick up a GitHub issue and implement a fix or feature with a user-approved plan. Fetch issue details, explore the codebase, generate an implementation plan, create a feature branch, and implement changes. | `git`, GitHub CLI (`gh`) |
| `gh-protect-default-branch` | Protect the default branch from direct pushes so changes land only via pull requests. | GitHub CLI (`gh`), repository admin permissions |

### Reviews

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

### Planning & Notes

| Skill | What it does | Requirements |
| --- | --- | --- |
| `save-plan` | Save or update the agent's current plan to `.opencode/plans/` in the working project. | none |
| `session-note` | Capture the current work session into a markdown note for continuity. | none |
| `work-report` | Write a self-contained markdown report to `.opencode/notes/` describing the problem, solution, project context, git-visible changed files, concise step log, and per-file patches for review or handoff. | none |

## Available Agents

### code-review
Reviews feature branch diffs for quality, bugs, performance, and security. Writes a structured review to `.opencode/review/`.

**Requirements:** git

## Requirements

- rsync (for sync script)
- python3 (required when syncing non-OpenCode targets: `ghc` and `cc`)

## Usage

Sync skills to OpenCode by default, plus OpenCode agents:

```bash
./sync.sh
```

Sync explicitly to OpenCode:

```bash
./sync.sh oc
```

Sync skills to GitHub Copilot CLI:

```bash
./sync.sh ghc
```

Sync skills to Claude Code:

```bash
./sync.sh cc
```

Sync all supported targets:

```bash
./sync.sh --sync-all
```

Preview changes without applying them (dry-run):

```bash
./sync.sh --dry-run
```

Preview a GitHub Copilot CLI sync without applying changes:

```bash
./sync.sh ghc --dry-run
```

Preview a Claude Code sync without applying changes:

```bash
./sync.sh cc --dry-run
```

Preview all supported targets without applying changes:

```bash
./sync.sh --sync-all --dry-run
```

The script will:
- Install new skills that don't exist in the selected target skills directory
- Install new OpenCode agents that don't exist in `~/.config/opencode/agents/`
- Update existing skills/agents if the repository version is different
- Use `python3` to prepare non-OpenCode skill copies before install by stripping extra frontmatter and rewriting workspace paths
- Rewrite skill workspace paths from `.opencode/...` to `.copilot/...` when syncing to `ghc`
- Rewrite skill workspace paths from `.opencode/...` to `.claude/...` when syncing to `cc`
- Skip items that are already up-to-date
- Preserve file permissions and timestamps

## Sync Targets

- OpenCode (`oc`)
  - Skills: `~/.config/opencode/skills`
  - Skill workspace paths stay as `.opencode/...`
  - Agents: `~/.config/opencode/agents`
- GitHub Copilot CLI (`ghc`)
  - Skills: `~/.copilot/skills`
  - Skill workspace paths are rewritten to `.copilot/...` during sync
  - Agents: not synced by this script
- Claude Code (`cc`)
  - Skills: `~/.claude/skills`
  - Skill workspace paths are rewritten to `.claude/...` during sync
  - Agents: not synced by this script

## Documentation

- **Creating OpenCode Skills**: https://opencode.ai/docs/skills/
- **Creating OpenCode Agents**: https://opencode.ai/docs/agents/
- **Claude Code Skills**: https://code.claude.com/docs/en/skills
- **Agent Skills Specification**: https://agentskills.io/ - An open format for creating reusable agent skills.
