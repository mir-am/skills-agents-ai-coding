# AGENTS.md

## Project Overview

This is **Mir's Agents & Skills for AI Coding Assistants**, a collection of reusable Agent Skills and agents for CLI coding assistants, hosted in the `opencode-skills` repository. Skills are markdown-based instruction sets that teach AI agents specific workflows using the open Agent Skills format. Agents are markdown-based definitions that create specialized AI assistants with custom prompts, tools, and permissions.

## Repository Structure

```
opencode-skills/
  skills/              # Skills: one directory per skill, each containing a SKILL.md
    changelog-bump-ver/
      SKILL.md
    gh-copilot-review-read/
      SKILL.md
    gh-copilot-review/
      SKILL.md
    gh-copilot-review-resolve/
      SKILL.md
    gh-cr-submit/
    gh-issue/
    gh-issue-fix/
    gh-pr/
    gh-pr-merge/
    gh-pr-review/
    gh-release/
    git-branch/
    git-commit/
    git-push/
    make-changelog/
    mir-skills-install/
    mir-skills-update/
    python-venv/
    save-plan/
    work-report/
    session-note/
  agents/              # Agents: flat .md files, one per agent
    code-review.md
  README.md
  AGENTS.md            # This file
```

## Skill Anatomy

Each skill is a **directory** under `skills/` containing a `SKILL.md` file.

1. **YAML frontmatter** with metadata in the repository source format:
   ```yaml
   ---
   name: <skill-name>
   description: <one-line description>
   license: MIT
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
- Skills use the open Agent Skills format and are installed with the Skills CLI
- Source skills are authored once under `skills/`
- Skills that write project artifacts should use `.opencode/...` paths
- Agents target the OpenCode agent runtime and its tool set (Bash, Read, Write, Edit, Glob, Grep, etc.)
- Some GitHub-focused skills may combine official API flows with clearly labeled best-effort prompt/comment flows when GitHub features are partially exposed through `gh`
- Never commit directly on `main` or `master`; create or switch to a feature branch first
- Never push directly to `main` or `master`; changes must land through a pull request
- `gh-issue-fix` carries an issue through planning, implementation, validation, commits, and a linked PR without routine approval pauses, unless the user requests a narrower scope. Use a dedicated issue branch, target the detected default branch, and include a closing issue reference; merging remains a separate action, and tool permissions and branch protections still apply.
- `gh-pr-merge` deletes the remote source branch after verifying a successful merge unless the user requests retaining it. Preserve local branches and uncommitted work, use the source repository for fork PRs, and report merge and cleanup results separately.
- `python-venv` creates or reuses a project-root `.venv` and verifies exclusion by the root `.gitignore`. Preserve invalid existing environments and ignore-file content; repeated runs must reuse the environment and avoid duplicate ignore rules.
- `mir-skills-install` checks for `npx` and installs all repository skills globally without interactive prompts, targeting `codex`, `claude-code`, `github-copilot`, and `opencode` explicitly.
- `mir-skills-update` checks for `npx` and runs the README command `npx skills@latest update -g` to update globally installed skills, reporting the result or command error.

## Skill Installation

Install skills globally using the Skills CLI, as documented in README.md:

```bash
npx skills add mir-am/skills-agents-ai-coding -g
```

Update installed skills:

```bash
npx skills@latest update -g
```

The `mir-skills-install` and `mir-skills-update` skills provide these workflows for agent sessions. OpenCode agent definitions remain under `agents/`; see the [OpenCode agents documentation](https://opencode.ai/docs/agents/) for agent setup.

## Adding a New Skill

1. Create a new directory under `skills/` with the skill name
2. Add a `SKILL.md` following the frontmatter + markdown body pattern above
3. Update `README.md` to list the new skill under "Available Skills"
4. Validate YAML frontmatter, ensure the directory name matches the skill name, and check referenced resources. Exercise changed commands in an isolated workspace or with stubs as appropriate.
5. Run `git diff --check` before committing.

Release-oriented skills can compose with each other. For example, `changelog-bump-ver` prepares the latest versioned changelog entry, and `gh-release` publishes that entry as an annotated tag and GitHub prerelease.

## Adding a New Agent

1. Create a new `.md` file in `agents/` with the agent name (e.g., `my-agent.md`)
2. Add YAML frontmatter with `description`, `mode`, `model`, `tools`, etc.
3. Write the agent instructions in the markdown body
4. Update `README.md` to list the new agent under "Available Agents"
5. Validate YAML frontmatter and review the configured tools and workflow against the agent's intended task; use an isolated workspace for behavioral checks.
6. Run `git diff --check` before committing.

## CI Skip Rules

The `git-commit` skill checks for `AGENTS.md` files in target projects for CI skip rules. Changes limited to docs, config, or non-production scripts may get `[skip ci]` appended to commit messages.

## Keeping AGENTS.md Up-to-Date

When you make significant structural changes to this project (e.g., adding/removing skills or agents, changing conventions or installation workflows, or altering the repo layout), update this file to reflect those changes. Future agents rely on AGENTS.md for accurate project context.

## Documentation

- Skills: https://opencode.ai/docs/skills/
- Agents: https://opencode.ai/docs/agents/
- Agent Skills specification: https://agentskills.io/
