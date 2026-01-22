# /doc-review

Command to create a review of any document file and output as `<filename>.review.md`.
Supports parallel processing for multiple files using the doc-reviewer sub-agent.

## Usage

```
/doc-review <file_path>
```

## Arguments

- `<file_path>`: Path to the file(s) to review (required)
  - Single file: `docs/README.md`
  - Multiple files: `docs/README.md docs/INSTALL.md`
  - Glob pattern: `docs/*.md`, `dotclaude/commands/wf*.md`

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Arguments

> **Note**: The following is pseudocode illustrating the processing logic.
> Claude Code executes this logic internally, not as a shell script.

```
target_pattern = $ARGUMENTS

# Check if argument is empty
if target_pattern is empty:
  Display error:
    "❌ Error: Please specify a file path"
    ""
    "Usage: /doc-review <file_path>"
    "Example: /doc-review docs/README.md"
    "Example: /doc-review docs/*.md  (glob pattern)"
  Stop processing

# Expand glob pattern to get file list (using Glob tool)
files = Glob(target_pattern)
file_count = count(files)

if files is empty:
  Display error: "❌ Error: No files found matching: {target_pattern}"
  Stop processing

Display: "Found {file_count} file(s) to review"
```

### 2. Check File Existence

Error if target file does not exist:
```
❌ Error: File not found: <target_file>
```

### 3. Parallel Processing Decision

| File Count | Processing Mode |
|------------|-----------------|
| 1 | Sub-agent (single invocation) |
| 2-5 | Parallel (all at once) |
| 6+ | Batch parallel (5 files per batch) |

**Constant:**
- `MAX_PARALLEL`: 5 (maximum concurrent sub-agents)

### 4. Sub-agent Invocation

All files are processed via the `doc-reviewer` sub-agent for consistent behavior.

#### Template Placeholder Values

Each sub-agent invocation must include the following placeholder values in the prompt:

| Placeholder | Value | Example |
|-------------|-------|---------|
| `{{filename}}` | Target file basename | `README.md` |
| `{{date}}` | Review date (YYYY-MM-DD) | `2026-01-22` |
| `{{file_path}}` | Relative path from project root | `docs/README.md` |

#### Single File (file_count == 1)

```
Task tool:
  subagent_type: general-purpose
  prompt: |
    Execute the doc-reviewer agent defined in agents/task/doc-reviewer.md.
    Input: file=<file_path>

    Template placeholders:
    - {{filename}} = <basename of file_path>
    - {{date}} = <current date YYYY-MM-DD>
    - {{file_path}} = <relative file_path>

    Follow the agent instructions to:
    1. Load and analyze the document
    2. Generate review using template
    3. Write output to <filename>.review.md

    Return the result in JSON format:
    {"status": "success|failure", "file": "<path>", "output": "<path>", "error": "<msg if failed>"}
```

#### Multiple Files (file_count >= 2)

Launch sub-agents in parallel using the Task tool's `run_in_background` parameter:

```
for each file in files (up to MAX_PARALLEL):
  Task tool:
    subagent_type: general-purpose
    run_in_background: true
    prompt: |
      Execute the doc-reviewer agent defined in agents/task/doc-reviewer.md.
      Input: file=<file_path>

      Template placeholders:
      - {{filename}} = <basename>
      - {{date}} = <current date>
      - {{file_path}} = <relative path>

      [same instructions as single file...]
```

For file_count > MAX_PARALLEL, process in batches:
1. Launch first 5 files in parallel (each with `run_in_background: true`)
2. Wait for completion using TaskOutput tool
3. Launch next batch
4. Repeat until all files processed

### 5. Result Collection

Use TaskOutput to wait for all background tasks to complete.

Track results:
```
results = {
  succeeded: [],
  failed: []
}

for each task:
  result = TaskOutput(task_id)
  if result.status == "success":
    succeeded.push({file, output})
  else:
    failed.push({file, error})
```

### 6. Output Format

#### Progress Display (during processing)

```
📋 Reviewing 5 files (parallel)
───────────────────────────────────────────────────────────
[1/5] README.md .............. ✓
[2/5] INSTALL.md ............. ✓
[3/5] CONFIG.md .............. ✓
[4/5] API.md ................. ✗ (failed)
[5/5] GUIDE.md ............... ✓
───────────────────────────────────────────────────────────
```

#### Completion Message

```
✅ Review complete

Summary:
  Total:     5 files
  Succeeded: 4 files
  Failed:    1 file

Generated:
  - README.review.md
  - INSTALL.review.md
  - CONFIG.review.md
  - GUIDE.review.md

Failed:
  - API.md: <error_reason>
```

For single file (backwards compatible):
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

### 7. Error Handling

**Fail-soft policy**: Continue processing even if some files fail.

- Individual file failures do not stop other files
- Failed files are reported in the final summary
- Suggest retry command for failed files:

```
To retry failed files:
  /doc-review API.md
```

## Sub-agent Reference

- **Agent**: `agents/task/doc-reviewer.md`
- **Template**: `templates/DOC_REVIEW.md`

## Future Considerations

The following features are planned for future implementation:

- **Timeout setting**: Add configurable timeout for long-running review processes
- **Review quality metrics**: Define and document review quality indicators and criteria
- **Diff review**: Compare current review with previous review to show changes
- **Dry-run option**: Add `--dry-run` flag to list target files without generating reviews

## Notes

- Write review file (`.review.md`) in Japanese regardless of the document's language
- Provide specific and constructive feedback
- For improvements, clearly describe "location", "issue", and "suggestion"
- Check/uncheck evaluation checklist based on actual evaluation results
- Parallel processing significantly improves performance for multiple files
