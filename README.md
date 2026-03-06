# opencode-skills
Skills and agents for OpenCode

## Available Skills

### git-commit
Smart git commit with branch protection, session-aware staging, and conventional commits.

**Requirements:** git

### git-pr
Create GitHub pull requests with smart title and description from branch commits.

**Requirements:** git, GitHub CLI (`gh`)

### git-push
Push commits to feature branch and update open PR description with new changes.

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
Submit AI-generated code review from `.opencode/review/` to GitHub PR. Validates branch matching, handles forks, allows user to choose from multiple reviews, and adds AI-generated warning header before submission.

**Requirements:** git, GitHub CLI (`gh`)

### make-changelog
Create initial CHANGELOG.md with unreleased features using Keep a Changelog format. Extracts up to 10 major features from README.md, commit history, and codebase structure.

**Requirements:** git

### save-plan
Save or update the agent's current plan to `.opencode/plans/` in the working project.

**Requirements:** none

### session-note
Capture current work session into a markdown note for continuity.

**Requirements:** none

## Available Agents

### code-review
Reviews feature branch diffs for quality, bugs, performance, and security. Writes a structured review to `.opencode/review/`.

**Requirements:** git

## Requirements

- rsync (for sync script)

## Usage

Sync all skills and agents from this repository to your OpenCode configuration:

```bash
./sync.sh
```

Preview changes without applying them (dry-run):

```bash
./sync.sh --dry-run
```

The script will:
- Install new skills that don't exist in `~/.config/opencode/skills/`
- Install new agents that don't exist in `~/.config/opencode/agents/`
- Update existing skills/agents if the repository version is different
- Skip items that are already up-to-date
- Preserve file permissions and timestamps

## Documentation

- **Creating OpenCode Skills**: https://opencode.ai/docs/skills/
- **Creating OpenCode Agents**: https://opencode.ai/docs/agents/
- **Agent Skills Specification**: https://agentskills.io/ - An open format for creating reusable agent skills.
