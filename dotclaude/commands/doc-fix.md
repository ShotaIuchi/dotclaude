# /doc-fix

Command to fix issues identified in `.review.md` files and apply changes to the original document.
Supports parallel processing for multiple review files using the doc-fixer sub-agent.

## Usage

```
/doc-fix [file_path...] [--all]
```

## Arguments

- `file_path`: Path to the review file(s) or original file(s) (optional)
  - `file.review.md` → Use directly as review file
  - `file.md` → Auto-search for `file.review.md`
  - `*.review.md` → Glob pattern for multiple files (non-recursive, current directory only)
  - `**/*.review.md` → Recursive glob pattern (all subdirectories)
  - Omitted → Search for `.review.md` files in current directory (non-recursive)
- `--all`: Apply all fixes without interactive selection (required for parallel mode)

## Processing

Parse $ARGUMENTS and execute the following processing.

> **Note**: The following is pseudocode illustrating the processing logic.
> Claude Code executes this logic internally, not as a shell script.

### 1. Parse Arguments

```
args = $ARGUMENTS
all_mode = "--all" in args
file_args = args without "--all"

if file_args is empty:
  # Search for .review.md files in current directory
  review_files = Glob("*.review.md")
  if review_files is empty:
    Display error: "❌ Error: No .review.md files found in current directory"
    Stop processing
  # If multiple files found without --all, use AskUserQuestion for selection
  # (see "Multiple Files Selection" section below)
else:
  # Expand glob patterns and normalize to review files
  review_files = []
  for arg in file_args:
    if arg ends with ".review.md":
      review_files.append(arg)
    else:
      review_files.append(arg.replace(extension, ".review.md"))
```

### 2. Processing Mode Decision

| File Count | --all Flag | Processing Mode |
|------------|------------|-----------------|
| 1 | No | Interactive (user selects issues) |
| 1 | Yes | Batch via sub-agent (all fixes) |
| 2+ | No | Error: "--all required for multiple files" |
| 2+ | Yes | Parallel via sub-agents |

**Constant:**
- `MAX_PARALLEL`: 5 (maximum concurrent sub-agents)

### 3. File Validation

For each review file:

```
if review_file does not exist:
  Display error: "❌ Error: Review file not found: {review_file}"
  Stop processing (or skip in parallel mode)

# Derive original file
base_name = review_file without ".review.md"
# Priority order: common documentation formats first, then config files
# md: Most common for documentation
# yaml/yml: Configuration and spec files
# json: Data and config files
# txt: Plain text fallback
original_file = find file with extension [md, yaml, yml, json, txt]

if original_file does not exist:
  Display error: "❌ Error: Original file not found: {original_file}"
  Stop processing (or skip in parallel mode)
```

### 4. Interactive Mode (Single File, No --all)

#### 4.1. Parse Review File

Parse the review file content to extract issues from the following sections:

**Template reference:** `../templates/DOC_REVIEW.md`

##### High Priority Issues (`### 優先度高 (High Priority)`)

Parse table format:
```markdown
| # | 箇所 | 問題 | 提案 |
|---|------|------|------|
| 1 | <location> | <issue> | <suggestion> |
```

##### Medium Priority Issues (`### 優先度中 (Medium Priority)`)

Same table format as High Priority.

##### Future Considerations (`### 将来の検討事項 (Future Considerations)`)

Parse list format:
```markdown
- <consideration>
```

#### 4.2. Display Issues

```
📋 Review Issues: <review_file>
═══════════════════════════════════════════════════════════

🔴 High Priority (<count> items)
───────────────────────────────────────────────────────────
[H1] <location>
     問題: <issue>
     提案: <suggestion>

🟡 Medium Priority (<count> items)
───────────────────────────────────────────────────────────
[M1] <location>
     問題: <issue>
     提案: <suggestion>

🟢 Future Considerations (<count> items)
───────────────────────────────────────────────────────────
[F1] <description>

═══════════════════════════════════════════════════════════
```

#### 4.3. Select Issues to Fix

Use `AskUserQuestion` with `multiSelect: true`:

```json
{
  "questions": [{
    "question": "修正する項目を選択してください",
    "header": "修正対象",
    "options": [
      {"label": "[H1] <location>", "description": "問題: <issue>"},
      {"label": "[H2] <location>", "description": "問題: <issue>"},
      {"label": "[M1] <location>", "description": "問題: <issue>"},
      {"label": "All remaining (N items)", "description": "残りすべての項目"}
    ],
    "multiSelect": true
  }]
}
```

**Option rules:**
- Maximum 4 options per question (tool limitation)
- If more than 4 issues exist, use pagination
- Include highest priority issues first (High > Medium > Future)

#### 4.4. Apply Fixes (Interactive)

For each selected issue, apply the fix directly without sub-agent.

### 5. Parallel Mode (Multiple Files or --all)

#### 5.1. Sub-agent Invocation

All files are processed via the `doc-fixer` sub-agent for consistent behavior.

##### Single File with --all

```
Task tool:
  subagent_type: general-purpose
  prompt: |
    Execute the doc-fixer agent defined in agents/task/doc-fixer.md.
    Input: review_file=<review_file_path>, issues="all"

    Follow the agent instructions to:
    1. Parse review file and extract all issues
    2. Apply all fixes to the original document
    3. Update review file with fix status

    Return the result in JSON format:
    {"status": "success|partial|failure", "review_file": "<path>", ...}
```

##### Multiple Files (Parallel)

Launch sub-agents in parallel using `run_in_background: true`:

```
for each review_file in review_files (up to MAX_PARALLEL):
  Task tool:
    subagent_type: general-purpose
    run_in_background: true
    prompt: |
      Execute the doc-fixer agent defined in agents/task/doc-fixer.md.
      Input: review_file=<review_file_path>, issues="all"
      ...
```

For file_count > MAX_PARALLEL, process in batches:
1. Launch first 5 files in parallel
2. Wait for completion using TaskOutput
3. Launch next batch
4. Repeat until all files processed

#### 5.2. Result Collection

Use TaskOutput to wait for all background tasks to complete.

```
results = {
  succeeded: [],
  partial: [],
  failed: []
}

for each task:
  result = TaskOutput(task_id)
  if result.status == "success":
    succeeded.append(result)
  elif result.status == "partial":
    partial.append(result)
  else:
    failed.append(result)
```

### 6. Update Review File

Add `Status` column to the improvement tables and mark fixed items.

**Table formatting rules:**
- Do not align pipe characters; use minimal spacing
- Keep existing column widths unchanged where possible

**Before:**
```markdown
| # | 箇所 | 問題 | 提案 |
|---|------|------|------|
| 1 | セクション4.1 | ... | ... |
```

**After:**
```markdown
| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | セクション4.1 | ... | ... | ✓ Fixed (YYYY-MM-DD) |
```

### 7. Output Format

#### Progress Display (Parallel Mode)

```
📋 Fixing 5 review files (parallel)
───────────────────────────────────────────────────────────
[1/5] README.review.md ....... ✓ (3/3 fixed)
[2/5] INSTALL.review.md ...... ✓ (2/2 fixed)
[3/5] CONFIG.review.md ....... △ (1/3 fixed)
[4/5] API.review.md .......... ✗ (failed)
[5/5] GUIDE.review.md ........ ✓ (5/5 fixed)
───────────────────────────────────────────────────────────
```

#### Completion Message (Single File)

```
✅ Fix completed

Files modified:
- Original: <original_file>
- Review:   <review_file>

Fixed items:
───────────────────────────────────────────────────────────
🔴 High Priority:     <fixed>/<total>
🟡 Medium Priority:   <fixed>/<total>
🟢 Future:            <fixed>/<total>
───────────────────────────────────────────────────────────

Remaining issues: <remaining_count>
```

#### Completion Message (Parallel Mode)

```
✅ Fix completed

Summary:
  Total:     5 files
  Succeeded: 3 files (all issues fixed)
  Partial:   1 file (some issues fixed)
  Failed:    1 file

Details:
───────────────────────────────────────────────────────────
✓ README.md: 3/3 issues fixed
✓ INSTALL.md: 2/2 issues fixed
△ CONFIG.md: 1/3 issues fixed
  - Failed: [M2] Section 3 - Could not locate target
✗ API.md: Error reading review file
───────────────────────────────────────────────────────────

To retry failed files:
  /doc-fix CONFIG.review.md API.review.md --all
```

#### All Issues Fixed (Single File)

```
✅ All issues have been fixed

Files modified:
- Original: <original_file>
- Review:   <review_file>

🎉 No remaining issues. Consider deleting the review file.
```

## Sub-agent Reference

- **Agent**: `agents/task/doc-fixer.md`
- **Template**: `~/.claude/templates/DOC_REVIEW.md` or `dotclaude/templates/DOC_REVIEW.md`

## Multiple Files Selection

When multiple `.review.md` files are found without `--all` flag:

```json
{
  "questions": [{
    "question": "どのレビューファイルを処理しますか？",
    "header": "ファイル選択",
    "options": [
      {"label": "file1.review.md", "description": "Original: file1.md"},
      {"label": "file2.review.md", "description": "Original: file2.md"},
      {"label": "すべて処理 (--all)", "description": "全ファイルの全修正を適用"}
    ],
    "multiSelect": false
  }]
}
```

## Notes

- Issues are displayed in priority order: High → Medium → Future
- Interactive mode: Only selected items are modified
- Parallel mode (--all): All issues in each file are fixed
- Review file is updated with fix status for traceability
- Original file changes follow the suggestions in the review
- If a suggestion is ambiguous, use best judgment based on context
- Parallel processing significantly improves performance for multiple files
