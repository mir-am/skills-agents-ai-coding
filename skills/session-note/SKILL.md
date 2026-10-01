---
name: session-note
description: Capture current work session into a markdown note for continuity
license: MIT
metadata:
  audience: developers
  workflow: productivity
  category: session-management
---

## What I do

- Create `.opencode/notes/` directory if it doesn't exist
- Generate timestamped markdown file: `YYYY-MM-DD-HHmm-<description>.md`
- Document files changed with diffs (truncated with git reference for full diff)
- Capture incomplete todos from TodoWrite if present
- Provide 2-3 sentence summary of where the session left off
- Multiple notes per session create new files with incremented timestamps

## When to use me

Use this skill when:
- User explicitly requests a session note
- User wants to pause work and capture current state for later continuation
- User needs to document progress before switching tasks/projects

## Note Creation Workflow

1. **Create directory**: `mkdir -p .opencode/notes`
2. **Generate filename**:
   - Extract main task from conversation context
   - Format: `YYYY-MM-DD-HHmm-<brief-description>.md`
   - Example: `2026-02-14-1630-add-csv-export.md`
   - Description: kebab-case, max 4-5 words from main task
   - Fallback: `work-session` if task unclear
3. **Gather context**:
   - Scan conversation for accomplished work
   - Identify main goals and outcomes
4. **Detect file changes**:
   - If git repo: `git status --short`
   - Parse: `M` = modified, `A`/`??` = created, `D` = deleted
   - If not git: extract from conversation (files agent wrote/edited)
5. **Get diffs**:
   - For modified files: `git diff <file>` (if git available)
   - For new files: read first 20-30 lines or key sections
   - Truncate large diffs (see diff handling below)
6. **Extract todos**:
   - Check if TodoWrite was used in session
   - Filter for `status: pending` or `status: in_progress`
   - Format as markdown checklist
7. **Write note** with structure below
8. **Confirm**: Tell user the note location

## Filename Generation

- **Pattern**: `YYYY-MM-DD-HHmm-<description>.md`
- **Timestamp**: `date +%Y-%m-%d-%H%M`
- **Description extraction**:
  - Scan conversation for primary task/goal
  - Extract key verbs + objects: "add CSV export" → `add-csv-export`
  - Sanitize: lowercase, spaces→hyphens, remove special chars
  - Max 4-5 words, keep concise
- **Examples**:
  - `2026-02-14-1630-add-csv-export.md`
  - `2026-02-14-1845-fix-memory-leak.md`
  - `2026-02-14-2015-refactor-auth-module.md`

## Note Structure

```markdown
# Session Note: <Descriptive Title>

**Date:** YYYY-MM-DD HH:mm
**Branch:** <current-branch> (only if git repo)

## Summary
<2-3 sentence overview of what was accomplished in this session>

## Files Changed

### Created
- `path/to/new-file1.ext`
- `path/to/new-file2.ext`

### Modified
- `path/to/modified-file1.ext`
- `path/to/modified-file2.ext`

### Deleted
- `path/to/deleted-file.ext`

(Only include sections that apply - skip empty categories)

## Changes Detail

### path/to/file1.ext
```diff
<diff output - first 50 lines>
... (diff truncated, run `git diff path/to/file1.ext` for full changes)
```

### path/to/file2.ext
```diff
<diff output - first 50 lines>
... (diff truncated, run `git diff path/to/file2.ext` for full changes)
```

(Repeat for each modified file)

## Tests/Validations
- `npm test` - All 47 tests passed
- `npm run build` - Build successful
- Manual testing: CSV export works with 1000+ rows

(Only include if tests/validations were run - omit section otherwise)

## Incomplete Tasks
- [ ] Add error handling for edge cases
- [ ] Update documentation
- [ ] Review performance with larger datasets

(Only include if TodoWrite has incomplete items - omit section otherwise)

## Where We Left Off
<2-3 sentences max describing current state, what was being worked on, and immediate context for continuation>

## Next Steps
1. <actionable next step 1>
2. <actionable next step 2>
3. <actionable next step 3>
```

## Diff Handling

- **Size threshold**: If diff exceeds 50 lines:
  - Include first 50 lines only
  - Add note: `... (diff truncated, run \`git diff <file>\` for full changes)`
- **New files**: Include first 20-30 lines or key sections
- **Large new files** (>100 lines): Show structure/imports + key functions only
- **No git**: For files without git, describe changes textually:
  ```
  ### path/to/file.ext
  - Added new function `processData()`
  - Updated error handling in `validateInput()`
  - Refactored class structure
  ```

## File Change Detection

**With git:**
```bash
git status --short
```
Parse output:
- `M  file.ext` → Modified
- `A  file.ext` → Created (staged)
- `?? file.ext` → Created (untracked)
- `D  file.ext` → Deleted

**Without git:**
- Extract from conversation context
- Track files agent used Write/Edit tools on
- Note: "Files listed based on session activity (not a git repository)"

## Todo Extraction

**Process:**
1. Check if TodoWrite tool was used in current session
2. Filter for incomplete items: `status: "pending"` or `status: "in_progress"`
3. Format as markdown checklist with `- [ ]` prefix
4. If no incomplete todos or TodoWrite not used → omit section

**Example:**
```markdown
## Incomplete Tasks
- [ ] Add unit tests for CSV exporter
- [ ] Handle empty dataset edge case
- [ ] Update API documentation
```

## Edge Cases

- **No files changed**: Note this in Summary, focus on planning/discussion done
- **No git repo**: Skip branch info, use conversation context for file tracking
- **No todos**: Omit "Incomplete Tasks" section entirely
- **No tests run**: Omit "Tests/Validations" section entirely
- **Multiple calls in session**: Create new note with current timestamp (naturally incremented)
- **Very short session**: Still create note, may have minimal content in some sections

## Example Complete Note

```markdown
# Session Note: Add CSV Export Functionality

**Date:** 2026-02-14 16:30
**Branch:** feat/csv-export

## Summary
Implemented CSV export functionality for user data with configurable column selection. Added validation for large datasets and basic error handling. Tests passing but documentation still needed.

## Files Changed

### Created
- `src/exporters/csv-exporter.ts`
- `tests/csv-exporter.test.ts`

### Modified
- `src/components/ExportButton.tsx`
- `src/types/export.types.ts`

## Changes Detail

### src/exporters/csv-exporter.ts
```diff
+export class CSVExporter {
+  constructor(private options: ExportOptions) {}
+
+  export(data: UserData[]): string {
+    const headers = this.getHeaders();
+    const rows = data.map(item => this.formatRow(item));
+    return [headers, ...rows].join('\n');
+  }
+
+  private getHeaders(): string {
+    return this.options.columns.join(',');
+  }
+
+  private formatRow(item: UserData): string {
+    return this.options.columns
+      .map(col => this.escapeValue(item[col]))
+      .join(',');
+  }
+}
... (diff truncated, run `git diff src/exporters/csv-exporter.ts` for full changes)
```

### src/components/ExportButton.tsx
```diff
 export function ExportButton({ data }: Props) {
+  const handleExport = () => {
+    const exporter = new CSVExporter({ columns: ['name', 'email', 'role'] });
+    const csv = exporter.export(data);
+    downloadFile(csv, 'users.csv');
+  };
+
   return (
-    <button>Export</button>
+    <button onClick={handleExport}>Export as CSV</button>
   );
 }
```

## Tests/Validations
- `npm test` - All 12 tests passed
- Manual testing: Exported 500 user records successfully

## Incomplete Tasks
- [ ] Add error handling for invalid column names
- [ ] Update user documentation with export feature
- [ ] Add support for Excel format

## Where We Left Off
CSV export is functional and tested. Error handling for edge cases (empty datasets, invalid columns) still needs implementation. Documentation update is next priority.

## Next Steps
1. Implement error handling for edge cases
2. Add user documentation for export feature
3. Consider adding Excel export format support
```
