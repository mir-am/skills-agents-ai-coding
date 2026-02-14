# opencode-skills
Skills for OpenCode

## Available Skills

### git-commit
Smart git commit with branch protection, session-aware staging, and conventional commits.

**Requirements:** git

### git-pr
Create GitHub pull requests with smart title and description from branch commits.

**Requirements:** git, GitHub CLI (`gh`)

### session-note
Capture current work session into a markdown note for continuity.

**Requirements:** none

## Requirements

- rsync (for sync script)

## Usage

Sync all skills from this repository to your OpenCode configuration:

```bash
./sync-skills.sh
```

Preview changes without applying them (dry-run):

```bash
./sync-skills.sh --dry-run
```

The script will:
- Install new skills that don't exist in `~/.config/opencode/skills/`
- Update existing skills if the repository version is different
- Skip skills that are already up-to-date
- Preserve file permissions and timestamps

## Creating Skills

For documentation on creating your own skills, see: https://opencode.ai/docs/skills/
