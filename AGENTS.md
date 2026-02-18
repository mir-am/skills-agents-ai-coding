# AGENTS.md

## Project Overview

This is **opencode-skills**, a collection of reusable skills and agents for [OpenCode](https://opencode.ai). Skills are markdown-based instruction sets that teach AI agents specific workflows. Agents are markdown-based definitions that create specialized AI assistants with custom prompts, tools, and permissions.

## Repository Structure

```
opencode-skills/
  skills/              # Skills: one directory per skill, each containing a SKILL.md
    git-commit/
      SKILL.md
    git-pr/
      SKILL.md
    session-note/
      SKILL.md
  agents/              # Agents: flat .md files, one per agent
    code-review.md
  sync.sh              # Installs/updates skills and agents to ~/.config/opencode/
  README.md
  AGENTS.md            # This file
```

## Skill Anatomy

Each skill is a **directory** under `skills/` containing a `SKILL.md` file.

1. **YAML frontmatter** with metadata:
   ```yaml
   ---
   name: <skill-name>
   description: <one-line description>
   license: MIT
   compatibility: opencode
   metadata:
     audience: developers
     workflow: <category>
     category: <category>
   ---
   ```

2. **Markdown body** with structured sections:
   - `## What I do` - Bullet list of capabilities
   - `## When to use me` - Trigger conditions
   - Workflow sections with step-by-step instructions
   - Code blocks with exact commands to run
   - Edge cases and error handling

## Agent Anatomy

Each agent is a **single `.md` file** in the `agents/` directory. The filename (minus `.md`) becomes the agent name.

1. **YAML frontmatter** with configuration:
   ```yaml
   ---
   description: <one-line description>
   mode: subagent          # or "primary"
   model: <provider/model-id>
   temperature: <0.0-1.0>
   tools:
     write: true/false
     edit: true/false
     bash: true/false
     read: true/false
     glob: true/false
     grep: true/false
   ---
   ```

2. **Markdown body** with agent instructions:
   - Role description and focus areas
   - Workflow steps with exact commands
   - Permissions (what the agent is/isn't allowed to do)
   - Output format and structure
   - Error handling

## Key Conventions

- **Skill names** use kebab-case (e.g., `git-commit`, `session-note`)
- **Skill directory name must match** the `name` field in its frontmatter
- **Agent filenames** use kebab-case (e.g., `code-review.md`)
- Each skill directory contains exactly one `SKILL.md` file
- Each agent is a single `.md` file directly in `agents/`
- Skills and agents are self-contained; all instructions live in their markdown file
- Commands should use `bash` code blocks with exact syntax
- Skills and agents target the OpenCode agent runtime and its tool set (Bash, Read, Write, Edit, Glob, Grep, etc.)

## sync.sh

The sync script installs skills and agents from this repo to `~/.config/opencode/`. It:
- Syncs skills (directories) to `~/.config/opencode/skills/` using `rsync`
- Syncs agents (flat `.md` files) to `~/.config/opencode/agents/` using `cp`
- Compares hashes (md5sum) to detect changes
- Supports `--dry-run` for previewing changes
- Reports installed/updated/up-to-date counts for both skills and agents
- Requires `rsync` to be installed

## Adding a New Skill

1. Create a new directory under `skills/` with the skill name
2. Add a `SKILL.md` following the frontmatter + markdown body pattern above
3. Update `README.md` to list the new skill under "Available Skills"
4. Test by running `./sync.sh --dry-run`

## Adding a New Agent

1. Create a new `.md` file in `agents/` with the agent name (e.g., `my-agent.md`)
2. Add YAML frontmatter with `description`, `mode`, `model`, `tools`, etc.
3. Write the agent instructions in the markdown body
4. Update `README.md` to list the new agent under "Available Agents"
5. Test by running `./sync.sh --dry-run`

## CI Skip Rules

The `git-commit` skill checks for `AGENTS.md` files in target projects for CI skip rules. Changes limited to docs, config, or non-production scripts may get `[skip ci]` appended to commit messages.

## Documentation

- Skills: https://opencode.ai/docs/skills/
- Agents: https://opencode.ai/docs/agents/
