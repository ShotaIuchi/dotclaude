# /doc-review

Command to create a review of any document file and output as `<filename>.review.md`.

## Usage

```
/doc-review <file_path>
```

## Arguments

- `<file_path>`: Path to the file(s) to review (required)
  - Single file: `docs/README.md`
  - Glob pattern: `docs/*.md`, `dotclaude/commands/wf*.md`

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Arguments

```bash
target_pattern="$ARGUMENTS"

# Check if argument is empty
if [ -z "$target_pattern" ]; then
  echo "❌ Error: Please specify a file path"
  echo ""
  echo "Usage: /doc-review <file_path>"
  echo "Example: /doc-review docs/README.md"
  echo "Example: /doc-review docs/*.md  (glob pattern)"
  exit 1
fi

# Expand glob pattern to get file list
files=$(ls -1 $target_pattern 2>/dev/null)
file_count=$(echo "$files" | wc -l | tr -d ' ')

if [ -z "$files" ]; then
  echo "❌ Error: No files found matching: $target_pattern"
  exit 1
fi

echo "Found $file_count file(s) to review"
```

**For multiple files:**
- Process each file sequentially
- Generate individual `.review.md` for each file
- Display summary at the end

### 2. Check File Existence

Error if target file does not exist:
```
❌ Error: File not found: <target_file>
```

### 3. Determine Output File Path

```
# Base name without extension + .review.md
# Example: docs/guide.md → docs/guide.review.md
# Example: src/config.yaml → src/config.review.md
output_file="${target_file%.*}.review.md"
```

### 4. Load and Analyze Target File

Load file content and analyze from the following perspectives:

- **Purpose and Role**: What is this document for
- **Completeness**: Is necessary information covered
- **Clarity**: Is it understandable for readers
- **Consistency**: Are terms and style unified
- **Technical Accuracy**: Is information accurate and current
- **Improvements**: What specifically should be improved and how

### 5. Generate Review File

**Template reference:** `~/.claude/templates/DOC_REVIEW.md` (or `dotclaude/templates/DOC_REVIEW.md`)

Load template and replace the following placeholders to create review:

| Placeholder | Value |
|-------------|-------|
| `{{filename}}` | Target file name |
| `{{date}}` | Review date (YYYY-MM-DD format) |
| `{{file_path}}` | Target file path |

### 6. Output Review File

Write generated review to `output_file`.

### 7. Completion Message

```
✅ Review complete

Target file: <target_file>
Review file: <output_file>

Review content:
- Summary: Document purpose and role
- Evaluation: Quality and technical accuracy check
- Improvements: Specific suggestions by priority
- Overall Assessment: Comprehensive evaluation

Please review the review file and implement improvements as needed.
```

## Notes

- Write review file (`.review.md`) in Japanese regardless of the document's language
- Provide specific and constructive feedback
- For improvements, clearly describe "location", "issue", and "suggestion"
- Check/uncheck evaluation checklist based on actual evaluation results
