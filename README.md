# Mir's Agents & Skills for AI Coding Assistants

Reusable Agent Skills and agents for CLI coding assistants.

This repository stores skills in the open Agent Skills format and supports syncing them to multiple CLIs:

- OpenCode (`oc`)
- GitHub Copilot CLI (`ghc`)

It also includes OpenCode-specific agents in `agents/`.

## Available Skills

### git-commit
Smart git commit with branch protection, session-aware staging, and conventional commits.

**Requirements:** git

### git-pr
Create GitHub pull requests with a smart title and description from branch commits.

**Requirements:** git, GitHub CLI (`gh`)

### git-push
Push commits to the feature branch and update the open PR description with new changes.

**Requirements:** git, GitHub CLI (`gh`)

### gh-issue
Create a GitHub issue for a bug or feature idea found during an agent session.

**Requirements:** git, GitHub CLI (`gh`)

### gh-issue-fix
Pick up a GitHub issue and implement a fix or feature with a user-approved plan. Fetches issue details, explores codebase, generates implementation plan, creates feature branch, and implements changes.

**Requirements:** git, GitHub CLI (`gh`)

### gh-pr-review
Review a GitHub Pull Request using gh CLI and provide structured feedback. Fetches PR metadata, diffs, and changed files, then generates a comprehensive code review focusing on quality, bugs, performance, and security.

**Requirements:** git, GitHub CLI (`gh`)

### gh-cr-submit
Submit AI-generated code review from `.opencode/review/` to GitHub PR. Validates branch matching, handles forks, allows the user to choose from multiple reviews, and adds an AI-generated warning header before submission.

**Requirements:** git, GitHub CLI (`gh`)

### make-changelog
Create an initial CHANGELOG.md with unreleased features using Keep a Changelog format. Extracts up to 10 major features from README.md, commit history, and codebase structure.

**Requirements:** git

### save-plan
Save or update the agent's current plan to `.opencode/plans/` in the working project.

**Requirements:** none

### session-note
Capture the current work session into a markdown note for continuity.

**Requirements:** none

## Available Agents

### code-review
Reviews feature branch diffs for quality, bugs, performance, and security. Writes a structured review to `.opencode/review/`.

**Requirements:** git

## Requirements

- rsync (for sync script)

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

Preview all supported targets without applying changes:

```bash
./sync.sh --sync-all --dry-run
```

The script will:
- Install new skills that don't exist in the selected target skills directory
- Install new OpenCode agents that don't exist in `~/.config/opencode/agents/`
- Update existing skills/agents if the repository version is different
- Skip items that are already up-to-date
- Preserve file permissions and timestamps

## Sync Targets

- OpenCode (`oc`)
  - Skills: `~/.config/opencode/skills`
  - Agents: `~/.config/opencode/agents`
- GitHub Copilot CLI (`ghc`)
  - Skills: `~/.copilot/skills`
  - Agents: not synced by this script

## Documentation

- **Creating OpenCode Skills**: https://opencode.ai/docs/skills/
- **Creating OpenCode Agents**: https://opencode.ai/docs/agents/
- **Agent Skills Specification**: https://agentskills.io/ - An open format for creating reusable agent skills.
