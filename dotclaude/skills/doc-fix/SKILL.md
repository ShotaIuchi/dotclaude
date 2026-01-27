---
name: doc-fix
description: Fix issues from document reviews
argument-hint: "[file_path...] [--all]"
---

**Always respond in Japanese.**

# /doc-fix

Command to fix issues identified in `docs/reviews/<path>.<filename>.md` files and apply changes to the original document.
Supports parallel processing for multiple review files using the doc-fixer sub-agent.

## Usage

```
/doc-fix [file_path...] [--all]
```

## Arguments

- `file_path`: Path to the review file(s) or original file(s) (optional)
  - `docs/reviews/commands.wf0-status.md` → Use directly as review file
  - `commands/wf0-status.md` → Auto-search for `docs/reviews/commands.wf0-status.md`
  - `docs/reviews/*.md` → Glob pattern for multiple files
  - Omitted → Search for `docs/reviews/*.md` files in reviews directory
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
  # Search for *.md files in reviews directory
  review_files = Glob("docs/reviews/*.md")
  if review_files is empty:
    Display error: "Error: No review files found in reviews directory"
    Stop processing
  # If multiple files found without --all, use AskUserQuestion for selection
  # (see "Multiple Files Selection" section below)
else:
  # Expand glob patterns and normalize to review files
  review_files = []
  for arg in file_args:
    if "docs/reviews/" in arg:
      review_files.append(arg)
    else:
      # commands/wf0-status.md → docs/reviews/commands.wf0-status.md
      dir = dirname(arg)
      base = basename(arg).removeSuffix(".md")
      if dir == ".":
        review_files.append("docs/reviews/" + base + ".md")
      else:
        path_part = dir.replace("/", ".")
        review_files.append("docs/reviews/" + path_part + "." + base + ".md")
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
  Display error: "Error: Review file not found: {review_file}"
  Stop processing (or skip in parallel mode)

# Derive original file
# docs/reviews/file.md → file (in original location)
base = basename(review_file).removeSuffix(".md")
base_name = join(dir, base)
# Priority order: common documentation formats first, then config files
# md: Most common for documentation
# yaml/yml: Configuration and spec files
# json: Data and config files
# txt: Plain text fallback
original_file = find file with extension [md, yaml, yml, json, txt]

if original_file does not exist:
  Display error: "Error: Original file not found: {original_file}"
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
Review Issues: <review_file>
═══════════════════════════════════════════════════════════

High Priority (<count> items)
───────────────────────────────────────────────────────────
[H1] <location>
     問題: <issue>
     提案: <suggestion>

Medium Priority (<count> items)
───────────────────────────────────────────────────────────
[M1] <location>
     問題: <issue>
     提案: <suggestion>

Future Considerations (<count> items)
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
| 1 | セクション4.1 | ... | ... | Fixed (YYYY-MM-DD) |
```

### 7. Output Format

#### Progress Display (Parallel Mode)

```
Fixing 5 review files (parallel)
───────────────────────────────────────────────────────────
[1/5] docs.README.md ....... OK (3/3 fixed)
[2/5] docs.INSTALL.md ...... OK (2/2 fixed)
[3/5] docs.CONFIG.md ....... PARTIAL (1/3 fixed)
[4/5] docs.API.md .......... FAIL (failed)
[5/5] docs.GUIDE.md ........ OK (5/5 fixed)
───────────────────────────────────────────────────────────
```

#### Completion Message (Single File)

```
Fix completed

Files modified:
- Original: <original_file>
- Review:   <review_file>

Fixed items:
───────────────────────────────────────────────────────────
High Priority:     <fixed>/<total>
Medium Priority:   <fixed>/<total>
Future:            <fixed>/<total>
───────────────────────────────────────────────────────────

Remaining issues: <remaining_count>
```

#### Completion Message (Parallel Mode)

```
Fix completed

Summary:
  Total:     5 files
  Succeeded: 3 files (all issues fixed)
  Partial:   1 file (some issues fixed)
  Failed:    1 file

Details:
───────────────────────────────────────────────────────────
OK README.md: 3/3 issues fixed
OK INSTALL.md: 2/2 issues fixed
PARTIAL CONFIG.md: 1/3 issues fixed
  - Failed: [M2] Section 3 - Could not locate target
FAIL API.md: Error reading review file
───────────────────────────────────────────────────────────

To retry failed files:
  /doc-fix docs/reviews/docs.CONFIG.md docs/reviews/docs.API.md --all
```

#### All Issues Fixed (Single File)

```
All issues have been fixed

Files modified:
- Original: <original_file>
- Review:   <review_file>

No remaining issues. Consider deleting the review file.
```

## Sub-agent Reference

- **Agent**: `agents/task/doc-fixer.md`
- **Template**: `~/.claude/templates/DOC_REVIEW.md` or `dotclaude/templates/DOC_REVIEW.md`

## Multiple Files Selection

When multiple `docs/reviews/*.md` files are found without `--all` flag:

```json
{
  "questions": [{
    "question": "どのレビューファイルを処理しますか？",
    "header": "ファイル選択",
    "options": [
      {"label": "commands.file1.md", "description": "Original: commands/file1.md"},
      {"label": "docs.file2.md", "description": "Original: docs/file2.md"},
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
