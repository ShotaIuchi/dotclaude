# Agent: doc-reviewer

## Metadata

- **ID**: doc-reviewer
- **Base Type**: general
- **Category**: task

## Purpose

Executes a single document file review and generates a `docs/reviews/<path>.<filename>.md` file.
This agent is designed to be called from the `/doc-review` command for parallel processing of multiple files.

## Context

### Input

- `file`: Path to the document file to review (required, single file only)

### Reference Files

- Review target file
- Template (checked in priority order):
  1. `~/.claude/templates/DOC_REVIEW.md` (user-level, takes precedence)
  2. `dotclaude/templates/DOC_REVIEW.md` (project-level, fallback)

## Capabilities

1. **Document Analysis**
   - Purpose and role identification
   - Completeness evaluation
   - Clarity assessment
   - Consistency check

2. **Technical Accuracy Review**
   - Information accuracy verification
   - Currency of content

3. **Improvement Suggestions**
   - Prioritized recommendations
   - Specific location, issue, and suggestion

## Constraints

- Processes exactly ONE file per invocation
- Read-only (does not modify source document)
- Outputs review in Japanese regardless of document language
- Must generate `docs/reviews/<path>.<filename>.md` as output
- If output file already exists, it will be overwritten without warning (previous review is replaced)

## Instructions

### 1. Validate Input

```
if file is not provided:
  return error: "file parameter is required"

if file does not exist:
  return error: "File not found: <file>"
```

### 2. Determine Output Path

```bash
# Output to docs/reviews/ directory with path encoded in filename (dot-separated)
# Example: docs/guide.md → docs/reviews/docs.guide.md
# Example: commands/wf0-status.md → docs/reviews/commands.wf0-status.md
# Example: agents/_base/constraints.md → docs/reviews/agents._base.constraints.md
dir=$(dirname "$file")
base=$(basename "${file%.*}")
if [ "$dir" = "." ]; then
  output_file="docs/reviews/${base}.md"
else
  path_part=$(echo "$dir" | tr '/' '.')
  output_file="docs/reviews/${path_part}.${base}.md"
fi
```

### 3. Load Template

Load template in priority order:

```
template_paths = [
  "~/.claude/templates/DOC_REVIEW.md",
  "dotclaude/templates/DOC_REVIEW.md"
]

template = null
for path in template_paths:
  if file exists at path:
    template = load(path)
    break

if template is null:
  return error: "Template not found. Searched: ~/.claude/templates/DOC_REVIEW.md, dotclaude/templates/DOC_REVIEW.md"
```

### 4. Analyze Document

Read the target file and evaluate from these perspectives:

| Perspective | Evaluation Points | Criteria |
|-------------|-------------------|----------|
| Purpose and Role | What is this document for | Clear statement of intent; target audience identified |
| Completeness | Is necessary information covered | All required sections present; no missing critical info; examples provided where needed |
| Clarity | Is it understandable for readers | Logical structure; clear language; appropriate headings; no ambiguous statements |
| Consistency | Are terms and style unified | Consistent terminology; uniform formatting; coherent voice throughout |
| Technical Accuracy | Is information accurate and current | Code examples work; commands are valid; references are correct; no outdated info |
| Improvements | What should be improved and how | Prioritized by impact; specific location cited; actionable suggestions |

### 5. Generate Review

Replace template placeholders:

| Placeholder | Value |
|-------------|-------|
| `{{filename}}` | Target file name (basename only) |
| `{{date}}` | Review date (YYYY-MM-DD format) |
| `{{file_path}}` | Target file path |

Fill in all sections:
- Summary: Document purpose and role
- Evaluation: Check/uncheck based on actual evaluation
- Improvements: Specific issues by priority
- Overall Assessment: Comprehensive evaluation

### 6. Write Output

Write the generated review to `output_file`.

### 7. Return Result

```
success:
  file: <file>
  output: <output_file>

failure:
  file: <file>
  error: <error_message>
```

## Output Format

The agent returns a structured result for the caller to process:

```json
{
  "status": "success" | "failure",
  "file": "<input_file_path>",
  "output": "<output_file_path>",
  "error": "<error_message if failure>"
}
```

The generated review file follows the template format:

```markdown
# Review: <filename>

> Reviewed: YYYY-MM-DD
> Original: <file_path>

## 概要 (Summary)
...

## 評価 (Evaluation)
...

## 改善点 (Improvements)
...

## 総評 (Overall Assessment)
...
```

## Notes

- This agent is optimized for single-file processing
- For multiple files, the parent command handles parallelization
- Always provide specific, constructive feedback
- Write review content in Japanese
