---
name: gh-release
description: Create an annotated git tag and GitHub prerelease from the latest versioned CHANGELOG entry
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: release
  category: release-workflow
---

## What I do

- Create an annotated git tag for the newest versioned release in `CHANGELOG.md`
- Create a GitHub prerelease with notes copied from that same changelog entry
- Treat the first versioned section below `## [Unreleased]` as the release to publish
- Preserve the release section subsections and bullets exactly as written in the changelog
- Preserve the repo's `### Misc` subsection at the end of release notes when present
- Append a `## Full Changelog` section that compares the previous release to the new tag
- Handle first-release repositories by comparing the default branch's first commit to the new release tag

## When to use me

Use this skill when:
- You already ran `changelog-bump-ver` and now want to publish that version as a git tag and GitHub prerelease
- The repository uses `CHANGELOG.md` with Keep a Changelog style version headings
- You want prerelease notes to come directly from the latest versioned changelog section

Do not use this skill when:
- `CHANGELOG.md` still only has unreleased notes and no new versioned section yet; run `changelog-bump-ver` first
- You want this workflow to rewrite `CHANGELOG.md`
- You want to publish a full GitHub release instead of a prerelease

## Prerequisites

**Required:**
- Must be a git repository
- `CHANGELOG.md` exists at the repository root
- `gh` is installed and authenticated
- `origin` remote exists
- The working tree is clean
- `HEAD` is on the default branch
- `CHANGELOG.md` contains exactly one `## [Unreleased]` section
- `CHANGELOG.md` contains at least one versioned release heading below `## [Unreleased]`

**Expected workflow:**
- Run `changelog-bump-ver` first so the newest release already exists as a versioned changelog section
- Then run `gh-release` to publish that version as a prerelease

**Validation checks:**
```bash
# Check git repository
git rev-parse --git-dir

# Check changelog exists
[ -f CHANGELOG.md ]

# Check GitHub CLI auth
gh auth status

# Check origin remote exists
git remote get-url origin

# Check working tree is clean
git status --short

# Detect default branch from GitHub metadata
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

**Error messages:**
- Missing changelog -> `Error: CHANGELOG.md not found. Run changelog-bump-ver first.`
- Missing versioned release -> `Error: No versioned release entry found below ## [Unreleased]. Run changelog-bump-ver first.`
- Dirty working tree -> `Error: Working tree is not clean. Commit or stash changes before creating a release.`
- Not on default branch -> `Error: Releases must be created from the default branch tip.`
- Tag already exists -> `Error: Tag vX.Y.Z already exists locally or on origin.`
- Missing previous tag for non-first release -> `Error: Previous changelog version exists but matching git tag was not found.`

## References

This skill follows:
- **Keep a Changelog**: https://keepachangelog.com/en/1.1.0/
- **Semantic Versioning**: https://semver.org/spec/v2.0.0.html
- **GitHub CLI release create**: https://cli.github.com/manual/gh_release_create

If you need to confirm compare-link or release-note behavior during execution, use the WebFetch tool for those URLs.

## Workflow

### Step 1: Validate Repository State

```bash
git rev-parse --git-dir 2>/dev/null
```
If this fails -> error: `Error: This skill requires a git repository.`

```bash
[ -f CHANGELOG.md ] && echo "found" || echo "missing"
```
If missing -> error: `Error: CHANGELOG.md not found. Run changelog-bump-ver first.`

```bash
gh auth status
```
If this fails -> error: `Error: GitHub CLI not authenticated. Run: gh auth login`

```bash
git remote get-url origin >/dev/null
```
If this fails -> error: `Error: Git remote 'origin' not found.`

```bash
default_branch="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null)"

if [ -z "$default_branch" ]; then
  default_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"

  if [ -z "$default_branch" ]; then
    if git show-ref --verify --quiet refs/heads/main; then
      default_branch="main"
    elif git show-ref --verify --quiet refs/heads/master; then
      default_branch="master"
    fi
  fi
fi

printf '%s\n' "$default_branch"
```

Rules:
- Prefer `gh repo view` so repositories with non-`main` default branches are handled correctly
- If GitHub metadata is unavailable, fall back to `origin/HEAD`
- If `origin/HEAD` is unavailable, fall back to local `main`, then local `master`

If empty -> error: `Error: Could not determine the default branch.`

```bash
current_branch="$(git branch --show-current)"
printf '%s\n' "$current_branch"
```

If `current_branch` is not equal to `default_branch` -> error: `Error: Releases must be created from the default branch tip.`

```bash
git status --short
```

If this prints any output -> error: `Error: Working tree is not clean. Commit or stash changes before creating a release.`

### Step 2: Validate Changelog Shape

Ensure `CHANGELOG.md` has exactly one unreleased section:

```bash
unreleased_count="$(grep -c '^## \[Unreleased\]$' CHANGELOG.md)"
printf '%s\n' "$unreleased_count"
```

Rules:
- `0` -> error: `Error: CHANGELOG.md does not contain a ## [Unreleased] section.`
- `1` -> continue
- `>1` -> error: `Error: Multiple ## [Unreleased] sections found. Normalize the changelog before releasing.`

Then identify the first versioned release heading after `## [Unreleased]`.

Accepted heading formats:
- `## [v1.2.3]`
- `## [v1.2.3] - 2026-03-20`
- `## [1.2.3]`
- `## [1.2.3] - 2026-03-20`

Normalization rules:
- Treat `v1.2.3` and `1.2.3` as the same version internally
- Always publish the git tag and GitHub release as `v1.2.3`
- Ignore comparison-link lines such as `[Unreleased]: ...`

Selection rule:
- Starting from `## [Unreleased]`, the first versioned `## [...]` heading encountered is the release to publish

If no such heading exists -> error: `Error: No versioned release entry found below ## [Unreleased]. Run changelog-bump-ver first.`

### Step 3: Extract Release Version and Notes

Read the selected release section from its heading line until the next `## ` heading or end of file.

Rules:
- Exclude the selected heading line from the notes body
- Preserve all subsection headings and bullets exactly as written
- Keep blank lines and subsection order intact
- Do not invent missing `Added`, `Changed`, `Fixed`, or other subsections
- Allow nonstandard subsections and keep them unchanged
- Preserve `### Misc` exactly as written as the final subsection when the changelog uses the repo's extended template

Example release body extracted from `CHANGELOG.md`:

```markdown
### Added
- Support release digests

### Fixed
- Correct changelog parsing for empty sections

### Misc
- Refactor changelog parsing for prerelease note generation
```

Normalize the release version to a tag value:
- `1.2.3` -> `v1.2.3`
- `v1.2.3` -> `v1.2.3`

### Step 4: Resolve Previous Release Context

Determine whether this is the first release.

Rules:
- If there is another versioned release heading after the selected one, that next heading is the previous release version
- If there is no older versioned heading, this is the first release

For non-first releases:
- Normalize the previous version to `vX.Y.Z`
- Verify that tag exists locally or on origin
- If the previous changelog version exists but the tag does not -> error: `Error: Previous changelog version exists but matching git tag was not found.`

For first releases:
- Use the first commit on the default branch as the start of the full changelog range

Commands:

```bash
git rev-list --max-parents=0 "$default_branch" | tail -n 1
```

Use that commit SHA as the start of the compare range.

### Step 5: Verify the New Tag Does Not Already Exist

```bash
tag="vX.Y.Z"

git rev-parse -q --verify "refs/tags/$tag" >/dev/null && echo "local-exists"
git ls-remote --tags origin "refs/tags/$tag" | grep -q . && echo "remote-exists"
```

If either check finds the tag -> error: `Error: Tag vX.Y.Z already exists locally or on origin.`

### Step 6: Build the GitHub Prerelease Notes

The prerelease title must be exactly the normalized tag:

```text
vX.Y.Z
```

The prerelease body must be:

1. The extracted changelog body for the selected release
2. A blank line
3. `## Full Changelog`
4. A compare line in one of these forms

Non-first release:

```markdown
## Full Changelog
https://github.com/OWNER/REPO/compare/v0.4.0...v0.5.0
```

First release:

```markdown
## Full Changelog
First release: https://github.com/OWNER/REPO/compare/<first-commit-sha>...v0.1.0
```

Repository URL guidance:
- Use `gh repo view --json url --jq '.url'` to get the canonical GitHub repository URL
- Build the compare link from that URL

Body construction rules:
- Do not repeat the release heading line from `CHANGELOG.md`
- Do not add extra summary prose above the changelog notes
- Keep the exact subsection content from the changelog
- Always include the `## Full Changelog` section at the end

### Step 7: Write the Prerelease Notes File

Write the assembled prerelease body from Step 6 into a temporary file before creating the release:

```bash
notes_file="$(mktemp)"

cat > "$notes_file" <<'EOF'
### Added
- Example release note

### Misc
- Example internal refactor note

## Full Changelog
https://github.com/OWNER/REPO/compare/v0.4.0...v0.5.0
EOF
```

Rules:
- The file content must be the exact assembled release body from Step 6
- Do not pass an empty temp file to `gh release create --notes-file`
- Remove the temp file after the release command succeeds or fails

### Step 8: Create the Annotated Tag

Create the release tag at the current `HEAD` commit:

```bash
git tag -a "vX.Y.Z" -m "Release vX.Y.Z"
```

Rules:
- Use an annotated tag, not a lightweight tag
- Tag the current `HEAD` only after all validation passes
- Do not retag an existing version

### Step 9: Push and Verify the Annotated Tag

Push the annotated tag to `origin` before creating the GitHub prerelease:

```bash
git push origin "vX.Y.Z"
git ls-remote --tags origin "refs/tags/vX.Y.Z"
```

Rules:
- Push the tag before running `gh release create`
- Ensure the prerelease is published from the annotated tag you created in Step 8
- If the tag push fails, stop and report the error instead of creating the release

### Step 10: Create the GitHub Prerelease

Create a temporary notes file, then publish the prerelease:

```bash
gh release create "vX.Y.Z" \
  --prerelease \
  --title "vX.Y.Z" \
  --notes-file "$notes_file"
```

Behavior rules:
- The release must be marked with `--prerelease`
- The release title must match the tag exactly
- The release notes must come from the generated body written in Step 7
- Use the already-pushed annotated tag from Step 9 rather than relying on GitHub to create a new ref

If `gh release create` fails after the local tag was created:
- Report the failure clearly
- Tell the user the local and remote tag now exist and may need cleanup or retry
- Remove the temp notes file before exiting
- Do not claim release success

After the release command finishes, clean up the temp file:

```bash
rm -f "$notes_file"
```

### Step 11: Report the Result

Report:
- Published tag
- Whether the release was first release or had a previous release
- Compare range used in `Full Changelog`
- GitHub prerelease URL

**Standard success message:**
```text
✓ Created prerelease v0.5.0
  - Tag: v0.5.0
  - Previous release: v0.4.0
  - Full Changelog: https://github.com/OWNER/REPO/compare/v0.4.0...v0.5.0
  - GitHub prerelease: https://github.com/OWNER/REPO/releases/tag/v0.5.0
```

**First release success message:**
```text
✓ Created prerelease v0.1.0
  - Tag: v0.1.0
  - Previous release: none (first release)
  - Full Changelog: https://github.com/OWNER/REPO/compare/<first-commit-sha>...v0.1.0
  - GitHub prerelease: https://github.com/OWNER/REPO/releases/tag/v0.1.0
```

## Version Parsing Rules

Accept these heading patterns when scanning `CHANGELOG.md`:
- `^## \[(v)?([0-9]+\.[0-9]+\.[0-9]+)\]$`
- `^## \[(v)?([0-9]+\.[0-9]+\.[0-9]+)\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$`

Ignore:
- Comparison links such as `[Unreleased]: ...`
- Headings with non-SemVer values like `vNext`, `1.0`, or `release-1`
- Inline code or prose mentions of versions

When scanning for the release to publish:
- Start at the `## [Unreleased]` heading
- Select the first later heading that matches the accepted version formats
- Use document order, not highest-version sorting, because `changelog-bump-ver` writes the newest release directly below `Unreleased`

## Release Body Example

Given this changelog excerpt:

```markdown
## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

### Misc

## [v0.5.0] - 2026-03-20

### Added
- Add `gh-release` skill for annotated tags and GitHub prereleases

### Fixed
- Preserve changelog subsection order in generated release notes

### Misc
- Refactor release note assembly for changelog subsection passthrough

## [v0.4.0] - 2026-03-10

### Added
- Add changelog version bump workflow
```

Publish `v0.5.0` with notes body:

```markdown
### Added
- Add `gh-release` skill for annotated tags and GitHub prereleases

### Fixed
- Preserve changelog subsection order in generated release notes

### Misc
- Refactor release note assembly for changelog subsection passthrough

## Full Changelog
https://github.com/OWNER/REPO/compare/v0.4.0...v0.5.0
```

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| `CHANGELOG.md` missing | Error: `CHANGELOG.md not found. Run changelog-bump-ver first.` |
| No `## [Unreleased]` section | Error: `CHANGELOG.md does not contain a ## [Unreleased] section.` |
| Multiple `## [Unreleased]` sections | Error: `Multiple ## [Unreleased] sections found. Normalize the changelog before releasing.` |
| No versioned release below `Unreleased` | Error: `No versioned release entry found below ## [Unreleased]. Run changelog-bump-ver first.` |
| Release version heading is malformed | Ignore it unless it matches the accepted SemVer patterns |
| Current branch is not the default branch | Error: `Releases must be created from the default branch tip.` |
| Working tree is dirty | Error: `Working tree is not clean. Commit or stash changes before creating a release.` |
| Tag already exists locally or remotely | Error: `Tag vX.Y.Z already exists locally or on origin.` |
| Could not determine default branch from GitHub metadata | Fall back to `origin/HEAD`, then local `main`, then local `master` |
| Previous changelog version exists but tag is missing | Error: `Previous changelog version exists but matching git tag was not found.` |
| Temp notes file was created but not populated | Error: stop before `gh release create`; do not publish empty notes |
| Annotated tag was created locally but not pushed | Push and verify the tag on `origin` before creating the release |
| First release with no older version heading | Compare first commit on default branch to new tag |
| First release with a single commit | Compare that same first commit to the new tag |
| Release section contains `### Misc` | Preserve it unchanged in the generated notes body |
| `gh release create` fails after tag creation | Report partial failure and note that the local tag now exists |

## Complete Workflow Example

**Scenario:** `changelog-bump-ver` already created `## [v0.5.0] - 2026-03-20` above `v0.4.0`

1. **Validate repository state:**
   ```bash
   git rev-parse --git-dir
   gh auth status
   git remote get-url origin
   git status --short
   git branch --show-current
   ```

2. **Detect default branch:**
   ```bash
   gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
   # main
   ```

3. **Identify the release heading below `Unreleased`:**
   - Selected heading: `## [v0.5.0] - 2026-03-20`
   - Previous heading: `## [v0.4.0] - 2026-03-10`

4. **Verify tags:**
   ```bash
   git rev-parse -q --verify refs/tags/v0.5.0
   git rev-parse -q --verify refs/tags/v0.4.0
   ```

5. **Build notes body:**
   ```markdown
    ### Added
    - Add `gh-release` skill for annotated tags and GitHub prereleases

    ### Fixed
    - Preserve changelog subsection order in generated release notes

    ### Misc
    - Refactor release note assembly for changelog subsection passthrough

   ## Full Changelog
   https://github.com/OWNER/REPO/compare/v0.4.0...v0.5.0
   ```

6. **Write notes, push tag, and create prerelease:**
   ```bash
    notes_file="$(mktemp)"

    cat > "$notes_file" <<'EOF'
    ### Added
    - Add `gh-release` skill for annotated tags and GitHub prereleases

    ### Fixed
    - Preserve changelog subsection order in generated release notes

    ### Misc
    - Refactor release note assembly for changelog subsection passthrough

    ## Full Changelog
    https://github.com/OWNER/REPO/compare/v0.4.0...v0.5.0
    EOF

   git tag -a "v0.5.0" -m "Release v0.5.0"
   git push origin "v0.5.0"

   gh release create "v0.5.0" \
     --prerelease \
     --title "v0.5.0" \
     --notes-file "$notes_file"

   rm -f "$notes_file"
   ```

7. **Notify the user:**
   ```text
   ✓ Created prerelease v0.5.0
     - Tag: v0.5.0
     - Previous release: v0.4.0
     - Full Changelog: https://github.com/OWNER/REPO/compare/v0.4.0...v0.5.0
     - GitHub prerelease: https://github.com/OWNER/REPO/releases/tag/v0.5.0
   ```
