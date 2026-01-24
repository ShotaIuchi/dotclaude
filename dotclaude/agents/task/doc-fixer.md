# Agent: doc-fixer

## Metadata

- **ID**: doc-fixer
- **Base Type**: general
- **Category**: task

## Purpose

Applies fixes from a `reviews/README.<path>.<filename>.md` file to its corresponding original document.
This agent is designed to be called from the `/doc-fix` command for parallel processing of multiple review files.

## Context

### Input

- `review_file`: Path to the review file (required, single file only)
- `issues`: List of issue IDs to fix (optional, defaults to "all")
  - Format: `["H1", "H2", "M1", "F1"]` or `"all"`

### Reference Files

- Review file (`reviews/README.<path>.<filename>.md`)
- Original document (derived from review file name)
- Template reference (priority order):
  1. `dotclaude/templates/DOC_REVIEW.md` (project-specific)
  2. `~/.claude/templates/DOC_REVIEW.md` (global fallback)

## Capabilities

1. **Review File Parsing**
   - Extract issues from High Priority table
   - Extract issues from Medium Priority table
   - Extract items from Future Considerations list

2. **Fix Application**
   - Identify target location in original file
   - Apply suggested changes
   - Preserve formatting and style

3. **Status Tracking**
   - Add Status column to improvement tables
   - Mark fixed items with timestamp

## Constraints

- Processes exactly ONE review file per invocation
- Modifies both original file and review file
- Applies fixes in priority order (High → Medium → Future)
- Must preserve file integrity on partial failures
- Backup strategy:
  1. Primary: Relies on git for versioning (if available)
  2. Fallback: If git is unavailable, creates `.bak` file before modification
  3. Warning: Outputs warning message when operating without git version control

## Instructions

### 1. Validate Input

```
if review_file is not provided:
  return error: "review_file parameter is required"

if review_file does not exist:
  return error: "Review file not found: <review_file>"
```

### 2. Derive Original File

```
# reviews/README.commands.wf0-status.md → commands/wf0-status
# reviews/README.agents._base.constraints.md → agents/_base/constraints
# reviews/README.CLAUDE.md → CLAUDE
# Extract filename, remove "README." prefix, replace "." with "/" for path
base = basename(review_file)  # README.commands.wf0-status.md
base = base.removePrefix("README.")  # commands.wf0-status.md
base = base.removeSuffix(".md")  # commands.wf0-status

# Replace dots with "/" to restore path structure
# commands.wf0-status → commands/wf0-status
# agents._base.constraints → agents/_base/constraints
# CLAUDE → CLAUDE (no dots = root level file)
if "." in base:
  # Replace dots with "/" to restore path
  base_name = base.replace(".", "/")
else:
  base_name = base

# Check for common extensions in order
# Extension selection criteria:
# - Documentation formats (md, txt): Primary use case for doc-fixer
# - Configuration formats (yaml, yml, json): Commonly reviewed configuration files
# - Code files (.sh, .py, .ts, etc.): Not included by default
#   - Reason: Code files require specialized linting/formatting tools
#   - To support: Use explicit naming (e.g., README.script.sh.md) or extend config
for ext in [md, yaml, yml, json, txt]:
  if file exists at "{base_name}.{ext}":
    original_file = "{base_name}.{ext}"
    break

if original_file not found:
  return error: "Original file not found for: <review_file>"
```

### 3. Parse Review File

Extract issues from the review file:

```
issues = {
  high: [],      # From "### 優先度高 (High Priority)" table
  medium: [],    # From "### 優先度中 (Medium Priority)" table
  future: []     # From "### 将来の検討事項 (Future Considerations)" list
}

# Parse table format for high/medium:
# | # | 箇所 | 問題 | 提案 |
# Extract: id, location, issue, suggestion

# Parse list format for future:
# - <description>
# Extract: description
```

### 4. Filter Issues

```
if issues parameter == "all":
  target_issues = all parsed issues
else:
  target_issues = filter by issue IDs in parameter
```

### 5. Apply Fixes

For each target issue in priority order:

1. Read original file
2. Identify target section based on `箇所` (location)
3. Apply suggested changes:
   - **Literal application**: When the suggestion provides exact text to add/replace
     - Example: "Add `--verbose` flag description" → Add the exact text as specified
     - Detection criteria: Suggestion contains code blocks, quoted text, or specific syntax
   - **Contextual implementation**: When the suggestion describes intent or improvement
     - Example: "Clarify the error handling" → Understand context and write appropriate content
     - Detection criteria: Suggestion uses descriptive language without specific text to insert
   - **Selection rule**: If suggestion contains backticks, quotes, or code fences → Literal; otherwise → Contextual
   - Preserve existing style and formatting
4. Track success/failure for each fix

```
results = {
  fixed: [],
  failed: []
}

for issue in target_issues:
  try:
    apply_fix(original_file, issue)
    results.fixed.append(issue.id)
  catch error:
    results.failed.append({id: issue.id, error: error.message})
```

### 6. Update Review File

Add Status column and mark fixed items:

**For tables (High/Medium Priority):**
```markdown
| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | ... | ... | ... | ✓ Fixed (YYYY-MM-DD) |
```

**For list items (Future Considerations):**
```markdown
- <description> ✓ Fixed (YYYY-MM-DD)
```

### 7. Return Result

```json
{
  "status": "success" | "partial" | "failure",
  "review_file": "<review_file_path>",
  "original_file": "<original_file_path>",
  "fixed": ["H1", "H2", "M1"],
  "failed": [{"id": "F1", "error": "..."}],
  "summary": {
    "high": {"fixed": 2, "total": 2},
    "medium": {"fixed": 1, "total": 3},
    "future": {"fixed": 0, "total": 2}
  }
}
```

## Output Format

The agent returns a structured result for the caller to process:

```json
{
  "status": "success" | "partial" | "failure",
  "review_file": "<path>",
  "original_file": "<path>",
  "fixed": ["<issue_ids>"],
  "failed": [{"id": "<id>", "error": "<message>"}],
  "summary": {
    "high": {"fixed": <n>, "total": <n>},
    "medium": {"fixed": <n>, "total": <n>},
    "future": {"fixed": <n>, "total": <n>}
  }
}
```

Status values:
- `success`: All requested fixes applied successfully (N/N succeeded)
- `partial`: At least one fix applied AND at least one fix failed (e.g., 2/5 fixes succeeded, where 1 <= succeeded < total)
- `failure`: No fixes applied (0 succeeded) or critical error (e.g., file not found, parse error)
  - Note: 0 success + 1 or more failures = `failure`, not `partial`

## Future Considerations

The following enhancements are planned for future versions:

- **Dry-run mode**: Preview changes without applying them (`--dry-run` flag)
- **Rollback capability**: Undo applied fixes without relying on git (maintain `.bak` chain or undo log)
- **Granular fix application**: Allow partial fixes within a single issue (configurable via `--allow-partial`)
- **Enhanced error handling**: Categorize errors (parse error, file permission, invalid location) with specific recovery actions

## Notes

- This agent is optimized for single-file processing
- For multiple files, the parent command handles parallelization
- Fixes are applied atomically per-issue (all or nothing for each)
- Original file is backed up via git (primary) or `.bak` file (fallback)
- Always update review file status even on partial failures
