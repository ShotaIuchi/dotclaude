---
name: doc-review
description: ドキュメントファイルをレビュー
argument-hint: "<file_path>"
---

**Always respond in Japanese.**

# /doc-review

Command to create a review of any document file and output as `docs/reviews/<path>.<filename>.md`.
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
    "Error: Please specify a file path"
    ""
    "Usage: /doc-review <file_path>"
    "Example: /doc-review docs/README.md"
    "Example: /doc-review docs/*.md  (glob pattern)"
  Stop processing

# Expand glob pattern to get file list (using Glob tool)
files = Glob(target_pattern)
file_count = count(files)

if files is empty:
  Display error: "Error: No files found matching: {target_pattern}"
  Stop processing

Display: "Found {file_count} file(s) to review"
```

### 2. Check File Existence

Error if target file does not exist:
```
Error: File not found: <target_file>
```

### 3. Parallel Processing Decision

| File Count | Processing Mode |
|------------|-----------------|
| 1 | Sub-agent (single invocation) |
| 2-5 | **Async parallel** (all at once) |
| 6+ | **Async batch parallel** (5 files per batch) |

**Constant:**
- `MAX_PARALLEL`: 5 (maximum concurrent sub-agents)

> **CRITICAL: Async Parallel Execution**
>
> When processing multiple files, you MUST:
> 1. Call **all Task tools in a single message** (do not split across multiple messages)
> 2. Set **`run_in_background: true`** for each Task
> 3. Continue without waiting for completion notifications
>
> Failure to follow these rules results in sequential execution, negating parallelism benefits.

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
    3. Write output to docs/reviews/<path>.<filename>.md

    Return the result in JSON format:
    {"status": "success|failure", "file": "<path>", "output": "<path>", "error": "<msg if failed>"}
```

#### Multiple Files (file_count >= 2) - Async Parallel

**IMPORTANT**: Call **all Task tools in a single assistant message**.

```
# CORRECT: Multiple Tasks in single message (true parallel)
<function_calls>
<invoke name="Task">  # File 1 - run_in_background: true
<invoke name="Task">  # File 2 - run_in_background: true
<invoke name="Task">  # File 3 - run_in_background: true
</function_calls>
→ All 3 launch simultaneously, completion notifications arrive as each finishes

# WRONG: Split across multiple messages (becomes sequential)
Message 1: Task tool (File 1) → wait for completion
Message 2: Task tool (File 2) → wait for completion
Message 3: Task tool (File 3) → wait for completion
→ Processed one by one, takes longer
```

**Task tool parameters (per file):**

```yaml
Task tool:
  subagent_type: general-purpose
  run_in_background: true  # ← REQUIRED
  prompt: |
    Execute the doc-reviewer agent defined in agents/task/doc-reviewer.md.
    Input: file=<file_path>

    Template placeholders:
    - {{filename}} = <basename>
    - {{date}} = <current date>
    - {{file_path}} = <relative path>

    Follow the agent instructions to:
    1. Load and analyze the document
    2. Generate review using template
    3. Write output to docs/reviews/<path>.<filename>.md

    Return the result in JSON format:
    {"status": "success|failure", "file": "<path>", "output": "<path>"}
```

**Batch processing (file_count > MAX_PARALLEL):**

1. Launch first 5 files with `run_in_background: true`
2. Wait for completion using TaskOutput
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
Reviewing 5 files (parallel)
───────────────────────────────────────────────────────────
[1/5] README.md .............. OK
[2/5] INSTALL.md ............. OK
[3/5] CONFIG.md .............. OK
[4/5] API.md ................. FAIL (failed)
[5/5] GUIDE.md ............... OK
───────────────────────────────────────────────────────────
```

#### Completion Message

```
Review complete

Summary:
  Total:     5 files
  Succeeded: 4 files
  Failed:    1 file

Generated:
  - docs/reviews/docs.README.md
  - docs/reviews/docs.INSTALL.md
  - docs/reviews/docs.CONFIG.md
  - docs/reviews/docs.GUIDE.md

Failed:
  - API.md: <error_reason>
```

For single file (backwards compatible):
```
Review complete

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

## Notes

- Write review file (`docs/reviews/<path>.<filename>.md`) in Japanese regardless of the document's language
- Provide specific and constructive feedback
- For improvements, clearly describe "location", "issue", and "suggestion"
- Check/uncheck evaluation checklist based on actual evaluation results
- **For multiple files: MUST use `run_in_background: true` and call all Tasks in a single message**
- Parallel processing significantly improves performance for multiple files
