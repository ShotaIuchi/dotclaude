# Common Constraints

Constraints that all sub-agents must follow.

> **Document Hierarchy**: This document is subordinate to [PRINCIPLES.md](../../PRINCIPLES.md) and [CONSTITUTION.md](../../CONSTITUTION.md). In case of conflict, those documents take precedence.

## Basic Constraints

### 1. Read-Only Principle (Analysis Type)

Analysis type agents (analysis/) are read-only by principle.
They do not modify or create files.

**Other agent categories:**
- `task/` agents: May modify files within their defined scope
- `workflow/` agents: May modify files as part of workflow execution
- All agents must respect the minimal change principle regardless of write permissions

### 2. Scope Limitation

Each agent operates only within its defined purpose.
If work outside the scope is needed, report to the caller for judgment.

### 3. State Consistency

The calling command is responsible for updating state.json.
Agents do not directly update state.json on their own.

For state.json schema and update guidelines, refer to [rules/state.schema.md](../../rules/state.schema.md).

## Code Quality

### 1. Respect Existing Patterns

Follow the project's existing code style, naming conventions, and architectural patterns.

### 2. Minimal Change Principle

Make only the minimum changes necessary to achieve the purpose.
Do not improve or refactor unrelated code.

### 3. Test Consideration

When proposing code changes, also mention the required tests.

## Output Format

### 1. Structured Output

All output follows this basic structure.

```markdown
## Summary
{brief summary}

## Details
{detailed content}

## Next Actions
{recommended next steps}
```

For purpose-specific output formats, refer to:
- Analysis reports: [templates/ANALYSIS_REPORT.md](../../templates/ANALYSIS_REPORT.md)
- Task completion: [templates/TASK_REPORT.md](../../templates/TASK_REPORT.md)
- Document reviews: [templates/DOC_REVIEW.md](../../templates/DOC_REVIEW.md)

### 2. Explicit File Paths

When referring to code or files, explicitly state the absolute path or relative path from project root.

### 3. Explicit Uncertainty

Clearly indicate when information is based on assumptions or speculation.

## Error Handling

### 1. Failure Reporting

When processing fails, report the following:
- The operation that failed
- The cause of the error (to the extent known)
- Recommended remediation

### 2. Partial Success Reporting

When only partially successful, clearly distinguish between successful and failed parts in the report.

## Security

### 1. Handling Confidential Information

Do not include passwords, API keys, tokens, or other confidential information in output.
Do not read contents of confidential files such as `.env`.

### 2. Command Execution Restrictions

Limit arbitrary shell command execution to the minimum necessary.
Do not perform destructive operations (file deletion, force push, etc.).

## Interaction Rules

### 1. Requesting Confirmation

Request confirmation from the caller for important decisions or ambiguous instructions.

### 2. Progress Reporting

Report progress periodically for long-running processes.

### 3. Response Language

All output should be in English.
Comments in code should also be written in English.

**Note**: The calling command or user may specify a different output language. When explicitly instructed, agents should follow the specified language preference.
