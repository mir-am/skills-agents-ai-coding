---
name: changelog-bump-ver
description: Promote CHANGELOG.md unreleased entries into the next release version and update Maven POMs to the next snapshot version
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: release
  category: release-workflow
---

## What I do

- Promote `## [Unreleased]` entries in `CHANGELOG.md` into a new versioned release section
- Create a fresh empty `## [Unreleased]` section above the new release
- Preserve Keep a Changelog structure with empty `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` subsections, and include `Misc` at the end for this repo's extended template
- Determine the next version using the user's requested bump method when provided
- Otherwise infer the current bump method from existing changelog history and fall back to `minor` when history is insufficient or unclear
- Use the current system date from `date +%F` in the new release heading
- Update Java Maven `pom.xml` files by changing only the direct `<project><version>` value to the next development snapshot version after the release

## When to use me

Use this skill when:
- A project already has a `CHANGELOG.md` with an `## [Unreleased]` section
- You are cutting a new release and want to move unreleased notes into a versioned entry
- You want the skill to keep a fresh empty unreleased template ready for future work
- You want Maven project versions in `pom.xml` files updated to the next development snapshot after the release

Do not use this skill when:
- The repository does not have a `CHANGELOG.md` yet; use `make-changelog` first
- You want to generate release notes from commits automatically
- You want to create git tags, commits, or GitHub releases as part of the same workflow

## Prerequisites

**Required:**
- `CHANGELOG.md` exists at the repository root
- `CHANGELOG.md` contains exactly one `## [Unreleased]` section

**Optional:**
- One or more `pom.xml` files if the project uses Maven

**Validation checks:**
```bash
# Check changelog exists
[ -f CHANGELOG.md ]

# Check unreleased section exists exactly once
[ "$(grep -c '^## \[Unreleased\]$' CHANGELOG.md)" -eq 1 ]

# Get current release date
date +%F
```

**Error messages:**
- Missing changelog -> `"Error: CHANGELOG.md not found. Create it first before bumping a release."`
- Missing unreleased section -> `"Error: CHANGELOG.md does not contain a ## [Unreleased] section."`
- Multiple unreleased sections -> `"Error: Multiple ## [Unreleased] sections found. Normalize the changelog before running this skill."`
- No version can be derived -> `"Error: Could not determine the next release version from CHANGELOG.md."`

## References

This skill follows:
- **Keep a Changelog**: https://keepachangelog.com/en/1.1.0/
- **Semantic Versioning**: https://semver.org/spec/v2.0.0.html
- **Maven POM Reference**: https://maven.apache.org/pom.html

If you need to verify detailed release-format rules during execution, use the WebFetch tool for those URLs.

## Workflow

### Step 1: Validate Inputs

```bash
[ -f CHANGELOG.md ] && echo "found" || echo "missing"
```
If missing -> error: `Error: CHANGELOG.md not found. Create it first before bumping a release.`

```bash
unreleased_count="$(grep -c '^## \[Unreleased\]$' CHANGELOG.md)"

if [ "$unreleased_count" -eq 0 ]; then
  echo "Error: CHANGELOG.md does not contain a ## [Unreleased] section."
elif [ "$unreleased_count" -gt 1 ]; then
  echo "Error: Multiple ## [Unreleased] sections found. Normalize the changelog before running this skill."
else
  echo "found exactly one"
fi
```

Rules:
- Exactly one match is required
- Zero matches -> error: `Error: CHANGELOG.md does not contain a ## [Unreleased] section.`
- One match -> continue
- More than one match -> error: `Error: Multiple ## [Unreleased] sections found. Normalize the changelog before running this skill.`

### Step 2: Collect Release Date

Use the system date command:

```bash
date +%F
```

Use the resulting value in the new release heading.

Example:
- `2026-03-19`

### Step 3: Parse Existing Versions

Read `CHANGELOG.md` and identify versioned headings matching either of these forms:
- `## [v0.2.0]`
- `## [v0.2.0] - 2026-03-19`
- `## [0.2.0]`
- `## [0.2.0] - 2026-03-19`

Normalization rules:
- Treat `v0.2.0` and `0.2.0` as the same semantic version internally
- Ignore headings that are not valid SemVer release headings
- Preserve all older release sections exactly as written
- Write newly created release headings using a `v` prefix

### Step 4: Determine the Bump Method

Choose the bump method in this order:

1. **Explicit user request wins**
   - If the user explicitly asks for `major`, `minor`, or `patch`, use that method
2. **Infer the current project bump method**
   - If at least two existing versioned releases are present, compare the two most recent versions
   - Infer the bump type from the latest observed transition:
     - `0.2.0 -> 0.3.0` -> `minor`
     - `1.4.2 -> 1.4.3` -> `patch`
     - `1.9.0 -> 2.0.0` -> `major`
3. **Fallback default**
   - If there are fewer than two versioned releases, or the latest transition does not match a clean SemVer step, default to `minor`

Inference rules:
- Prefer the most recent version transition over older history
- A clean `minor` bump increments minor and resets patch to zero
- A clean `major` bump increments major and resets minor and patch to zero
- A clean `patch` bump increments patch only
- If the latest transition skips values or mixes multiple components unexpectedly, treat it as unclear and default to `minor`

### Step 5: Determine the Release Version

Use the highest existing versioned release in `CHANGELOG.md`.

Rules:
- If no versioned release exists yet, release as `v0.1.0`
- If versions exist, bump the highest version using the method chosen in Step 4

Examples:
- No prior versions -> `v0.1.0`
- Highest `v0.2.0`, method `minor` -> `v0.3.0`
- Highest `v1.4.2`, method `minor` -> `v1.5.0`
- Highest `v1.4.2`, method `patch` -> `v1.4.3`
- Highest `v1.4.2`, method `major` -> `v2.0.0`

### Step 6: Determine the Next Maven Snapshot Version

After computing the release version, compute the next Maven development version using the same bump method again and append `-SNAPSHOT`.

Rules:
- If releasing `v0.1.0` as the first release, update Maven POMs to `0.2.0-SNAPSHOT`
- Use the same bump method chosen in Step 4 to advance from the release version to the next development version
- Remove the leading `v` before writing the Maven version value

Examples:
- Release `v0.3.0`, method `minor` -> Maven `0.4.0-SNAPSHOT`
- Release `v1.4.3`, method `patch` -> Maven `1.4.4-SNAPSHOT`
- Release `v2.0.0`, method `major` -> Maven `3.0.0-SNAPSHOT`

### Step 7: Capture the Current Unreleased Content

Read the entire `## [Unreleased]` section, including all subsections and bullets, until the next `## ` heading or end of file.

Rules:
- Preserve all existing unreleased notes exactly
- Keep subsection order as found within the promoted release content
- Do not silently discard unknown subsections
- Preserve `### Misc` exactly like the standard subsections when present
- If the unreleased section is empty, allow the release but warn the user

### Step 8: Rewrite CHANGELOG.md

Rewrite `CHANGELOG.md` so the file contains, in order:

1. Existing changelog title and intro text unchanged
2. A fresh empty `## [Unreleased]` section
3. A new release heading in this exact format:
   - `## [vX.Y.Z] - YYYY-MM-DD`
4. The prior unreleased content moved under the new release heading
5. All older release sections unchanged below

Fresh unreleased template:

```markdown
## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

### Misc
```

Rules:
- The new empty unreleased section must appear directly above the new release
- The new release heading must always include the date from `date +%F`
- If the promoted unreleased content did not contain one of the standard subsections, do not invent release notes; just move what existed
- For this repo's extended template, keep `### Misc` as the last subsection in both the promoted release content and the refreshed empty unreleased template
- Keep surrounding whitespace tidy and consistent

### Step 9: Update Maven `pom.xml` Files

Search for Maven POM files:

```bash
find . -name 'pom.xml' -type f
```

For each `pom.xml` found:
- Update only the direct `<project><version>` element
- Set it to the next development snapshot version without brackets, for example `0.4.0-SNAPSHOT` after releasing `v0.3.0`
- Do not modify:
  - `<parent><version>`
  - dependency versions
  - plugin versions
  - property values like `<revision>` unless the direct project version is actually defined that way and the user explicitly asked for that behavior

Behavior rules:
- If a POM inherits its version from a parent and has no direct project `<version>`, leave it unchanged and report that it was skipped
- Handle XML namespaces correctly
- Preserve the rest of the file formatting as much as practical

Recommended safe approach:
- Read each `pom.xml`
- Locate the direct child `<version>` of the root `<project>` element
- Update only that node
- Verify after editing that the file still contains a root `<project>` element and the expected version value

### Step 10: Report the Result

Report:
- New release version
- New Maven snapshot version
- Release date
- Bump method used
- Whether the bump method was explicit, inferred, or a fallback default
- Whether the unreleased section had content or was empty
- Which `pom.xml` files were updated or skipped

**Standard success message:**
```
✓ Released CHANGELOG.md as [v0.3.0] - 2026-03-19
  - Bump method: minor (inferred from existing history)
  - Added fresh empty [Unreleased] section including `### Misc`
  - Updated Maven project version to `0.4.0-SNAPSHOT` in:
    - pom.xml
    - modules/api/pom.xml
  - Skipped inherited-version POMs:
    - modules/shared/pom.xml
```

**First release success message:**
```
✓ Released CHANGELOG.md as [v0.1.0] - 2026-03-19
  - Bump method: minor (fallback default; no prior version history)
  - Added fresh empty [Unreleased] section including `### Misc`
  - Updated Maven project version to `0.2.0-SNAPSHOT` in:
    - pom.xml
```

**Empty unreleased success message:**
```
✓ Released CHANGELOG.md as [v0.3.0] - 2026-03-19
  - Bump method: minor (explicit user request)
  - Next Maven snapshot version: `0.4.0-SNAPSHOT`
  - Note: [Unreleased] was empty
  - Added fresh empty [Unreleased] section including `### Misc`
  - No pom.xml files required updates
```

## Version Parsing Rules

Accept these heading patterns when scanning the changelog:
- `^## \[(v)?([0-9]+\.[0-9]+\.[0-9]+)\]$`
- `^## \[(v)?([0-9]+\.[0-9]+\.[0-9]+)\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$`

Ignore:
- Comparison-link references such as `[Unreleased]: ...`
- Inline examples in prose
- Headings with non-SemVer values like `vNext`, `1.0`, or `release-1`

When multiple valid version headings exist:
- Use semantic version ordering, not text ordering, to determine the highest version
- Use document order only when inspecting the most recent transition for bump-method inference

## Changelog Rewrite Example

**Before:**

```markdown
## [Unreleased]

### Added
- Support SSO login

### Fixed
- Resolve session timeout bug

## [v0.2.0] - 2026-02-10

### Added
- Add audit export
```

**After:**

```markdown
## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

### Misc

## [v0.3.0] - 2026-03-19

### Added
- Support SSO login

### Fixed
- Resolve session timeout bug

### Security

### Misc
- Refactor access-control evaluation flow

## [v0.2.0] - 2026-02-10

### Added
- Add audit export
```

## Maven POM Update Guidance

For Maven projects, update only the project artifact version, and set it to the next development snapshot after the release.

Safe target:

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>demo</artifactId>
  <version>0.3.0-SNAPSHOT</version>
</project>
```

Change only:
- If releasing `v0.2.0`: `<version>0.2.0-SNAPSHOT</version>` -> `<version>0.3.0-SNAPSHOT</version>`
- If releasing `v0.3.0`: `<version>0.3.0-SNAPSHOT</version>` -> `<version>0.4.0-SNAPSHOT</version>`

Do not change these automatically:

```xml
<parent>
  <version>1.0.0</version>
</parent>

<dependency>
  <version>5.3.1</version>
</dependency>

<properties>
  <revision>0.2.0</revision>
</properties>
```

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| `CHANGELOG.md` missing | Error: `CHANGELOG.md not found. Create it first before bumping a release.` |
| No `## [Unreleased]` section | Error: `CHANGELOG.md does not contain a ## [Unreleased] section.` |
| Multiple `## [Unreleased]` sections | Error: `Multiple ## [Unreleased] sections found. Normalize the changelog before running this skill.` |
| No prior version headings | Release as `v0.1.0` |
| Only one prior version heading | Use that version as the base; fallback bump method is `minor` unless the user specifies another |
| Latest version transition is unclear | Fallback bump method is `minor` |
| User explicitly requests `major`, `minor`, or `patch` | Use the explicit request even if it differs from history |
| Unreleased section is empty | Create release anyway, but notify the user |
| Unreleased section contains `### Misc` | Preserve it under the new release and recreate it in the fresh empty `[Unreleased]` template |
| Unreleased section contains nonstandard subsections | Preserve them under the new release |
| Mixed `v` and non-`v` release headings | Normalize only the new release heading to `vX.Y.Z` |
| `pom.xml` has direct project version | Update it to the next snapshot version |
| `pom.xml` inherits version from parent | Skip it and report the skip |
| `pom.xml` only uses properties like `<revision>` | Skip by default unless the user explicitly asks for property-based version updates |

## Complete Workflow Example

**Scenario:** Existing changelog with releases `v0.1.0`, `v0.2.0`, current unreleased notes, and two Maven POM files

1. **Validate files:**
   ```bash
   [ -f CHANGELOG.md ] && echo "found"
   grep -n '^## \[Unreleased\]$' CHANGELOG.md
   ```

2. **Get current date:**
   ```bash
   date +%F
   # 2026-03-19
   ```

3. **Read release history:**
   - Existing headings found:
     - `## [v0.2.0] - 2026-02-10`
     - `## [v0.1.0] - 2026-01-15`

4. **Infer bump method:**
   - Latest transition is `0.1.0 -> 0.2.0`
   - Inferred method: `minor`

5. **Compute release version:**
    - Highest existing version: `0.2.0`
    - Next version: `0.3.0`

6. **Compute next Maven snapshot version:**
   - From release `0.3.0` with `minor` bump -> `0.4.0-SNAPSHOT`

7. **Rewrite changelog:**
    - Create fresh empty `## [Unreleased]` including `### Misc`
    - Promote current unreleased notes into `## [v0.3.0] - 2026-03-19`
    - Preserve prior entries below

8. **Update Maven versions:**
   - `pom.xml` direct project version `0.2.0-SNAPSHOT` -> `0.4.0-SNAPSHOT`
    - `modules/core/pom.xml` has no direct project version -> skipped

9. **Notify the user:**
   ```
    ✓ Released CHANGELOG.md as [v0.3.0] - 2026-03-19
      - Bump method: minor (inferred from existing history)
      - Added fresh empty [Unreleased] section including `### Misc`
      - Updated Maven project version to `0.4.0-SNAPSHOT` in:
        - pom.xml
      - Skipped inherited-version POMs:
        - modules/core/pom.xml
   ```
