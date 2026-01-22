# /doc-fix

Command to fix issues identified in `.review.md` files and apply changes to the original document.

## Usage

```
/doc-fix [file_path]
```

## Arguments

- `file_path`: Path to the review file or original file (optional)
  - `file.review.md` → Use directly as review file
  - `file.md` → Auto-search for `file.review.md`
  - Omitted → Search for `.review.md` files in current directory

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Identify Files

```bash
arg="$ARGUMENTS"

if [ -z "$arg" ]; then
  # Search for .review.md files in current directory
  review_files=$(find . -maxdepth 1 -name "*.review.md" -type f)
  if [ -z "$review_files" ]; then
    echo "❌ Error: No .review.md files found in current directory"
    exit 1
  fi
  # If multiple files found, use AskUserQuestion for selection
  # (see "Multiple Files Selection" section below)
elif [[ "$arg" == *.review.md ]]; then
  review_file="$arg"
else
  review_file="${arg%.*}.review.md"
fi

# Derive original file from review file
# Extract base name and find the actual original file
base_name="${review_file%.review.md}"
# Check for common extensions in order of preference
for ext in md yaml yml json txt; do
  if [ -f "${base_name}.${ext}" ]; then
    original_file="${base_name}.${ext}"
    break
  fi
done
# Fallback to .md if no file found (will error later if not exists)
original_file="${original_file:-${base_name}.md}"
```

Error if review file does not exist:
```
❌ Error: Review file not found: <review_file>
```

Error if original file does not exist:
```
❌ Error: Original file not found: <original_file>
```

#### Multiple Files Selection

When multiple `.review.md` files are found, use `AskUserQuestion`:

```json
{
  "questions": [{
    "question": "どのレビューファイルを処理しますか？",
    "header": "ファイル選択",
    "options": [
      {"label": "file1.review.md", "description": "Original: file1.md"},
      {"label": "file2.review.md", "description": "Original: file2.md"},
      {"label": "file3.review.md", "description": "Original: file3.md"}
    ],
    "multiSelect": false
  }]
}
```

If more than 4 files exist, display most recently modified files first. The "Other" option is automatically provided by AskUserQuestion, allowing users to input a custom file path.

### 2. Parse Review File

Parse the review file content to extract issues from the following sections:

**Template reference:** `../templates/DOC_REVIEW.md`

#### High Priority Issues (`### 優先度高 (High Priority)`)

Parse table format:
```markdown
| # | 箇所 | 問題 | 提案 |
|---|------|------|------|
| 1 | <location> | <issue> | <suggestion> |
```

#### Medium Priority Issues (`### 優先度中 (Medium Priority)`)

Same table format as High Priority.

#### Future Considerations (`### 将来の検討事項 (Future Considerations)`)

Parse list format:
```markdown
- <consideration>
```

### 3. Display Issues

```
📋 Review Issues: <review_file>
═══════════════════════════════════════════════════════════

🔴 High Priority (<count> items)
───────────────────────────────────────────────────────────
[H1] <location>
     問題: <issue>
     提案: <suggestion>

[H2] <location>
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

### 4. Select Issues to Fix

Use `AskUserQuestion` with `multiSelect: true` to allow users to select multiple issues:

```json
{
  "questions": [{
    "question": "修正する項目を選択してください",
    "header": "修正対象",
    "options": [
      {"label": "[H1] <location>", "description": "問題: <issue>"},
      {"label": "[H2] <location>", "description": "問題: <issue>"},
      {"label": "[M1] <location>", "description": "問題: <issue>"},
      {"label": "[F1] <description>", "description": "将来の検討事項"}
    ],
    "multiSelect": true
  }]
}
```

**Option rules:**
- Maximum 4 options per question (tool limitation)
- If more than 4 issues exist, use pagination (multiple rounds of questions)
- Include highest priority issues first (High > Medium > Future)
- Add "All remaining items" option when more than 4 issues remain

**Pagination example (5+ issues):**
```
Round 1: [H1], [H2], [M1], "All remaining (5 items)"
  ↓ (if "All remaining" not selected)
Round 2: [M2], [M3], [F1], "All remaining (2 items)"
  ↓ (if "All remaining" not selected)
Round 3: [F2], [F3]
```

**"All remaining" selection behavior:**
When "All remaining (N items)" is selected, all remaining issues not yet displayed are automatically marked as selected. No further pagination rounds are needed, and processing proceeds directly to the Apply Fixes step with all those items included.

### 5. Apply Fixes

For each selected issue:

1. **Load original file**
2. **Identify target section/location** based on `箇所` column
3. **Apply suggested changes** following these principles:
   - Apply the suggestion literally when it's specific and unambiguous
   - When the suggestion describes intent (e.g., "add pagination"), implement it using appropriate patterns from the codebase
   - Preserve existing formatting and style conventions
   - If the suggestion conflicts with existing content, prefer the suggestion but maintain consistency
4. **Verify changes are applied correctly**

```
修正中...
───────────────────────────────────────────────────────────
[H1] <location> ... ✓
[M2] <location> ... ✓
───────────────────────────────────────────────────────────
```

### 6. Update Review File

Add `Status` column to the improvement tables and mark fixed items.

**Table formatting rules:**
- Do not align pipe characters; use minimal spacing
- Keep existing column widths unchanged where possible
- Only add the Status column to the header separator with appropriate dashes

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

For Future Considerations, add ` ✓ Fixed (YYYY-MM-DD)` suffix:
```markdown
- <consideration> ✓ Fixed (YYYY-MM-DD)
```

### 7. Completion Message

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

If all issues are fixed:
```
✅ All issues have been fixed

Files modified:
- Original: <original_file>
- Review:   <review_file>

🎉 No remaining issues. Consider deleting the review file.
```

## Notes

- Issues are displayed in priority order: High → Medium → Future
- Only selected items are modified; unselected items remain unchanged
- Review file is updated with fix status for traceability
- Original file changes follow the suggestions in the review
- If a suggestion is ambiguous, use best judgment based on context
