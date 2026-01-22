# /doc-review

Command to create a review of any document file and output as `<filename>.review.md`.

## Usage

```
/doc-review <file_path>
```

## Arguments

- `<file_path>`: Path to the file to review (required)

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Arguments

```
target_file=$ARGUMENTS
```

If argument is empty, display error message and exit:
```
❌ Error: Please specify a file path

Usage: /doc-review <file_path>
Example: /doc-review docs/README.md
```

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

**Template reference:** `../templates/DOC_REVIEW.md`

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

- Write review in the same language as the document
- Provide specific and constructive feedback
- For improvements, clearly describe "location", "issue", and "suggestion"
- Check/uncheck evaluation checklist based on actual evaluation results
