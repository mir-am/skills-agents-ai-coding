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

## OpenCode Documentation

- **Creating Skills**: https://opencode.ai/docs/skills/
- **Creating Agents**: https://opencode.ai/docs/agents/
