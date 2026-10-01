---
name: make-changelog
description: Create initial CHANGELOG.md with unreleased features using Keep a Changelog format
license: MIT
metadata:
  audience: developers
  workflow: git
  category: release-workflow
---

## What I do

- Create initial CHANGELOG.md file using Keep a Changelog format
- Extract up to 10 major features from README.md, commit history, and codebase structure
- Place all extracted entries under [Unreleased] section (no version number yet)
- Classify entries into Added or Misc based on whether they describe new capabilities or notable catch-all code changes
- Include empty sections for Changed, Deprecated, Removed, Fixed, Security, and Misc at the end
- Note adherence to Semantic Versioning for future releases
- Notify if additional important features exist beyond the top 10
- Provide guidance on moving to versioned releases later

## When to use me

Use this skill when:
- Starting changelog documentation for an existing project
- Project has no CHANGELOG.md file yet
- You want to document current state before making first release
- You need a Keep a Changelog compliant starting point

## Prerequisites

**Required:**
- Must be a git repository
- Must have main or master branch

**Optional:**
- README.md file (used for feature extraction if present)

**Validation checks:**
```bash
# Check if git repo
git rev-parse --git-dir

# Check if CHANGELOG.md already exists
[ -f CHANGELOG.md ]
```

**Error messages:**
- Not a git repo → `"Error: This skill requires a git repository for context gathering."`
- CHANGELOG.md exists → `"Error: CHANGELOG.md already exists. This skill is for first-time changelog creation only."`
- No main/master branch → `"Error: No main or master branch found. Please create a default branch first."`

## References

This skill follows:
- **Keep a Changelog**: https://keepachangelog.com/en/1.1.0/
- **Semantic Versioning**: https://semver.org/spec/v2.0.0.html

If you need to fetch detailed information about changelog format or versioning rules during execution, use the WebFetch tool with these URLs.

## Workflow

### Step 1: Validate Prerequisites

```bash
# Check if git repository
git rev-parse --git-dir 2>/dev/null
```
If fails → error: "Error: This skill requires a git repository for context gathering."

```bash
# Check if CHANGELOG.md already exists
[ -f CHANGELOG.md ] && echo "exists" || echo "not found"
```
If exists → error: "Error: CHANGELOG.md already exists. This skill is for first-time changelog creation only."

### Step 2: Identify Default Branch

```bash
# Detect default branch name
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If that fails, try:
```bash
# Check which branch exists: main or master
git show-ref --verify refs/heads/main 2>/dev/null && echo "main" || \
git show-ref --verify refs/heads/master 2>/dev/null && echo "master"
```

If neither exists → error: "Error: No main or master branch found. Please create a default branch first."

### Step 3: Gather Context

**3a. Check for README.md:**
```bash
[ -f README.md ] && echo "found" || echo "not found"
```

If found, read README.md using Read tool and parse for:
- "Features" section
- "What it does" section
- "Capabilities" section
- Bullet lists describing functionality
- High-level feature descriptions

**3b. Analyze first-parent history on main/master:**
```bash
# Get first-parent commits from default branch
git log origin/main --first-parent --oneline
# or
git log origin/master --first-parent --oneline
```

Apply smart filtering to identify Added and Misc candidates:

**Include commits with:**
- `feat:`, `feature:`, `add:`, `added:`, `implement:`, `create:`
- Keywords: "api", "database", "auth", "cli", "ui", "backend", "frontend", "dashboard", "integration"
- `refactor:` only if mentions major component (e.g., "refactor: migrate to TypeScript")
- Descriptive squash-merge or PR titles that indicate code or logic changes not already covered by standard sections

**Exclude commits with:**
- `docs:`, `doc:`, `documentation:`
- `chore:`, `build:`, `ci:`, `style:`, `format:`
- `test:` (unless adding testing framework: "add jest", "add cypress", etc.)
- Version-related: "bump", "release", "version"
- Dependencies: "update deps", "upgrade", "npm update", "yarn upgrade"
- Trivial changes: "fix typo", "update readme", "add comment", "format code"
- Generic merge subjects with no useful description (e.g., "Merge pull request #123 ...")

**3c. Scan project structure:**
```bash
ls -la
```

Look for directories indicating major features:
- `src/` → Core application source code
- `api/`, `backend/` → REST API or backend service
- `cli/`, `cmd/` → CLI tool
- `web/`, `frontend/`, `ui/` → Web interface
- `docker/`, `k8s/` → Container deployment
- `db/`, `migrations/` → Database integration
- `auth/` → Authentication system
- `docs/` → Documentation (only mention if substantial)

### Step 4: Extract, Classify, and Rank Entries

**Priority ranking (highest to lowest):**
1. Explicit features from README.md sections
2. Commit messages with `feat:` prefix
3. Commit messages with feature-indicating keywords
4. Major directory structure inferences

**Deduplication logic:**
- Merge similar features from different sources
  - Example: "Add REST API" (commit) + "API endpoints" (README) → "RESTful API with endpoints"
- Group related commits
  - Example: "Add JWT auth", "Add login endpoint", "Add user sessions" → "Authentication system with JWT"

**Section classification rules:**
- `### Added` → new features, new subsystems, first-time integrations, or newly introduced user-facing capabilities
- `### Misc` → notable merged PRs or source-code / program-logic changes that affect behavior, architecture, or maintainability but do not cleanly fit `Added`, `Changed`, `Fixed`, `Removed`, `Deprecated`, or `Security`
- Do not place docs-only, formatting-only, CI-only, or dependency-only work into `Misc`
- When unsure between `Added` and `Misc`, prefer `Added` only for clearly new capabilities; otherwise use `Misc`

**Entry formatting:**
- Convert to past tense if needed
- Start with capital letter
- Concise: 50-80 characters max
- Focus on user-facing or architectural significance
- Examples:
  - `Initial project scaffolding and CLI interface`
  - `RESTful API with JWT authentication`
  - `PostgreSQL database integration with migrations`
  - `Docker deployment configuration`
  - `Web-based admin dashboard`
  - `Real-time WebSocket notifications`
  - `Comprehensive test suite with 80% coverage`
  - `CI/CD pipeline with GitHub Actions`
  - `API documentation with OpenAPI/Swagger`
  - `Role-based access control (RBAC)`

**Feature selection:**
- Select top 10 most significant features based on ranking
- If fewer than 10 candidates found, include all
- If more than 10 candidates found:
  - Keep top 10 in CHANGELOG
  - Note 2-3 examples of additional features for user review

Balance the selected entries across `### Added` and `### Misc` based on classification. `### Misc` may remain empty if no suitable catch-all code changes are found.

### Step 5: Generate CHANGELOG.md

**Template structure:**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- [Feature 1]
- [Feature 2]
- [Feature 3]
- [Feature 4]
- [Feature 5]
- [Feature 6]
- [Feature 7]
- [Feature 8]
- [Feature 9]
- [Feature 10]

### Changed

### Deprecated

### Removed

### Fixed

### Security

### Misc
```

**Rules:**
- All features go under `## [Unreleased]` section
- No version number or date yet
- Keep empty sections (Changed, Deprecated, Removed, Fixed, Security, Misc) present
- Place each extracted entry in either `### Added` or `### Misc` with `- ` bullet format
- Use `### Misc` only for notable code or logic changes and merged PRs that do not fit the standard Keep a Changelog sections

### Step 6: Write CHANGELOG.md

Use the Write tool to create the file at project root:
```bash
# File path: ./CHANGELOG.md
```

### Step 7: User Confirmation

**Standard success message:**
```
✓ Created CHANGELOG.md with [N] entries under [Unreleased]
  - File location: CHANGELOG.md
  - Included `### Misc` for notable code changes that do not fit standard Keep a Changelog sections
  - Future versions will follow Semantic Versioning

Next steps:
  - Review and edit CHANGELOG.md if needed
  - Commit: git add CHANGELOG.md && git commit -m "docs: add initial changelog"
  - When ready to release, move [Unreleased] items to a versioned section (e.g., [0.1.0])
```

**With overflow notification (>10 features found):**
```
✓ Created CHANGELOG.md with 10 entries under [Unreleased]
  - Note: Found [X] additional potential entries. Consider reviewing commits for:
    • [Feature example 1]
    • [Feature example 2]
    • [Feature example 3]

Next steps:
  - Review CHANGELOG.md and add any missing important features
  - Commit: git add CHANGELOG.md && git commit -m "docs: add initial changelog"
  - When ready to release, move [Unreleased] items to a versioned section (e.g., [0.1.0])
```

**Low feature count (0-2 features):**
```
✓ Created CHANGELOG.md with [N] entr(y/ies) under [Unreleased]
  - Note: Limited entries detected from project analysis. You may want to manually edit CHANGELOG.md to add more details.

Next steps:
  - Review CHANGELOG.md and add missing features
  - Commit: git add CHANGELOG.md && git commit -m "docs: add initial changelog"
  - When ready to release, move [Unreleased] items to a versioned section (e.g., [0.1.0])
```

## Feature Extraction Strategy

### README.md Parsing

Look for these section headers (case-insensitive):
- `## Features`
- `## What it does`
- `## Capabilities`
- `## About`
- `## Overview`

Extract bullet points or numbered lists from these sections. Each item becomes a feature candidate.

### Commit Message Patterns

**High-priority patterns (strong feature indicators):**
- `feat: ` or `feature: ` prefix
- `add: ` or `added: ` prefix
- `implement: ` or `create: ` prefix
- Contains: "initial", "scaffold", "setup", "introduce"

**Medium-priority patterns (contextual features):**
- Contains architectural keywords: "api", "database", "auth", "authentication", "authorization"
- Contains component keywords: "cli", "ui", "dashboard", "admin", "backend", "frontend"
- Contains integration keywords: "docker", "kubernetes", "postgres", "redis", "websocket"
- Contains workflow keywords: "ci/cd", "pipeline", "deployment", "migration"

**Refinement rules:**
- Group commits by topic (e.g., all auth-related commits → single "Authentication system" feature)
- Ignore micro-commits (e.g., "fix lint error", "remove console.log")
- Prioritize commits near repository start (foundational features)
- Treat descriptive squash-merge titles as valid candidates for `### Misc` when they represent notable source changes without a cleaner standard section

### Directory Structure Inference

Map directories to feature descriptions:
- `src/` → "Core application source code"
- `api/`, `backend/`, `server/` → "Backend API server"
- `cli/`, `cmd/` → "Command-line interface"
- `web/`, `frontend/`, `client/`, `ui/` → "Web user interface"
- `docker/`, `Dockerfile` → "Docker containerization"
- `k8s/`, `kubernetes/` → "Kubernetes deployment"
- `db/`, `database/`, `migrations/` → "Database layer with migrations"
- `auth/`, `authentication/` → "Authentication system"
- `docs/`, `documentation/` → "Project documentation" (only if substantial)
- `tests/`, `__tests__/` → "Test suite" (only if comprehensive)

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| CHANGELOG.md exists | Error: "CHANGELOG.md already exists. This skill is for first-time changelog creation only." |
| Not a git repository | Error: "This skill requires a git repository for context gathering." |
| No main or master branch | Error: "No main or master branch found. Please create a default branch first." |
| README.md not found | Proceed with commits + directory structure analysis only |
| No commits on main/master | Use directory structure + notify: "No commit history found. Created minimal CHANGELOG.md based on project structure. Please edit manually to add entries." |
| Empty repository (no files) | Notify: "Empty repository detected. Created template CHANGELOG.md with no features. Please edit manually." |
| 0 entries extracted | Create CHANGELOG with empty Added and Misc sections + notify: "No notable code changes detected. Please manually edit CHANGELOG.md to add your project's entries." |
| 1-2 entries extracted | Include all + notify: "Limited entries detected. You may want to manually edit CHANGELOG.md to add more details." |
| Exactly 10 entries | Include all, no overflow notification |
| More than 10 entries | Include top 10 + notify with 2-3 examples of additional entries |

## Complete Workflow Example

**Scenario:** Project with README, 150 commits, and typical web app structure

1. **Validation:**
   ```bash
   git rev-parse --git-dir
   # ✓ Valid git repo

   [ -f CHANGELOG.md ]
   # ✓ Does not exist, can proceed
   ```

2. **Branch detection:**
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD
   # refs/remotes/origin/main
   # ✓ Using 'main' branch
   ```

3. **README analysis:**
   - Found `## Features` section with 6 items:
     - User authentication and authorization
     - RESTful API with OpenAPI docs
     - PostgreSQL database
     - React frontend
     - Docker deployment
     - CI/CD with GitHub Actions

4. **Commit analysis (150 first-parent commits):**
    - Filter to 42 feature-related commits
    - Grouped into topics:
      - Authentication (8 commits) → "Authentication system with JWT and OAuth"
     - API (15 commits) → "RESTful API with OpenAPI documentation"
     - Database (6 commits) → "PostgreSQL database with Prisma ORM"
     - Frontend (10 commits) → "React-based web interface with Material-UI"
     - Testing (3 commits) → "Comprehensive test suite with Jest and Cypress"
     - Deployment (5 commits) → "Docker containerization and Kubernetes deployment"
     - CI/CD (4 commits) → "CI/CD pipeline with GitHub Actions"
     - WebSocket (3 commits) → "Real-time notifications via WebSocket"
     - Monitoring (2 commits) → "Application monitoring with Prometheus"

5. **Directory structure:**
   ```
   api/      → Backend API
   web/      → Frontend
   docker/   → Container support
   k8s/      → Kubernetes configs
   db/       → Database migrations
   ```

6. **Entry ranking and selection:**
    - Deduplicated and merged sources
    - Top 10 selected:
      1. Authentication system with JWT and OAuth
      2. RESTful API with OpenAPI documentation
      3. PostgreSQL database with Prisma ORM
      4. React-based web interface with Material-UI
      5. Real-time notifications via WebSocket
      6. Docker containerization and Kubernetes deployment
      7. CI/CD pipeline with GitHub Actions
      8. Comprehensive test suite with Jest and Cypress
      9. Application monitoring with Prometheus
      10. Major internal permissions refactor (Misc)

7. **Overflow detection:**
   - Found 2 additional features:
     - Email notification system
     - API rate limiting

8. **Write CHANGELOG.md** with selected entries split between `### Added` and `### Misc`

9. **User notification:**
   ```
   ✓ Created CHANGELOG.md with 10 features under [Unreleased]
     - Note: Found 2 additional potential features. Consider reviewing commits for:
       • Email notification system
       • API rate limiting

   Next steps:
     - Review CHANGELOG.md and add any missing important features
     - Commit: git add CHANGELOG.md && git commit -m "docs: add initial changelog"
     - When ready to release, move [Unreleased] items to a versioned section (e.g., [0.1.0])
   ```
