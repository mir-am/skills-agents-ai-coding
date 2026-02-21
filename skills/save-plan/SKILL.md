---
name: save-plan
description: Save or update the agent's current plan to .opencode/plans/ in the working project
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: productivity
  category: planning
---

## What I do

- Create `.opencode/plans/` directory in the project if it doesn't exist
- Derive a topic-based filename in kebab-case from the plan subject (e.g. `add-csv-export.md`)
- Write the final plan the agent has devised as freeform markdown — agent decides structure and content
- If a plan file for the same topic already exists, overwrite it with the latest version
- Confirm the saved file path to the user

## When to use me

Use this skill when:
- User asks to save, record, or write down the current plan
- User asks to update an existing plan with latest changes
- Agent has finished devising a plan and the user wants it persisted

## Workflow

1. **Create directory**:
   ```bash
   mkdir -p .opencode/plans
   ```

2. **Derive filename**:
   - Extract the main topic or subject of the plan from conversation context
   - Format as kebab-case: `<topic>.md`
   - Examples: `add-csv-export.md`, `refactor-auth-module.md`, `migrate-to-postgres.md`
   - Keep it concise (3-5 words max)
   - Fallback: `plan.md` if topic is unclear

3. **Check for existing file**:
   - If `.opencode/plans/<filename>.md` already exists → overwrite with the latest plan
   - No need to prompt the user; silent overwrite is the expected behavior

4. **Write plan**:
   - Content is freeform markdown — the agent decides the structure based on the plan it devised
   - Write exactly the plan that was discussed/devised in the conversation
   - Do not add boilerplate or enforce a fixed template; let the plan speak for itself

5. **Confirm to user**:
   - Report the file path: `.opencode/plans/<filename>.md`
   - State whether it was created or updated

## Edge Cases

- **No plan devised yet**: Do not save. Tell the user there is no plan to save yet and offer to devise one first.
- **Unclear topic**: Use `plan.md` as the filename, or ask the user for a one-word topic if context is truly ambiguous.
- **Not a git repo / no project root**: Save relative to the current working directory; `.opencode/plans/` still works.
- **Multiple unrelated plans in one session**: Each gets its own topic-based filename and can coexist in `.opencode/plans/`.
