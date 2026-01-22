# Agent: research

## Metadata

- **ID**: research
- **Base Type**: explore
- **Category**: workflow

## Purpose

Conducts background research on GitHub Issues and identifies related code.
As a preliminary step for wf1-kickoff, it is responsible for gathering information to deepen understanding of Issues.

## Context

### Input

- `issue`: Issue number (required)
- If there is active work, automatically get Issue number from work-id
  - `work-id` format: `{issue_number}-{short_description}` (e.g., `123-add-login-feature`)
  - Retrieved from `.wf/state.json` under `work.id` field

### Reference Files

- `.wf/state.json` - Current work state
- `.wf/config.json` - Project configuration

## Capabilities

1. **Issue Analysis**
   - Parse Issue title, body, labels, milestones
   - Extract related Issues and links

2. **Codebase Investigation**
   - Identify files and modules mentioned in Issue
   - Search for related code patterns
   - Discover existing similar implementations

3. **Understanding Dependencies**
   - Identify affected modules
   - Identify related test files
   - Investigation methods:
     - Parse `package.json` / `requirements.txt` for external dependencies
     - Analyze import/require statements to trace internal dependencies
     - Check configuration files (tsconfig.json, webpack.config.js, etc.)

4. **Organizing Technical Background**
   - Confirm technology stack in use
   - Collect related documentation and comments

## Constraints

- Read-only (do not modify code)
- Do not read confidential information (.env, credentials, etc.)
- Report investigation results in structured format (see [Output Format](#output-format) section)
- **Investigation Limits** (for large codebases):
  - Maximum investigation time: 10 minutes
  - Maximum files to analyze in detail: 50 files
  - If limits are reached, document findings so far and note remaining areas for investigation

## Instructions

### 0. Prerequisites Check

Before starting investigation, verify:

1. **GitHub CLI Authentication**: Ensure `gh` command is authenticated
   ```bash
   gh auth status
   ```
   If not authenticated, prompt user to run `gh auth login`

2. **Issue Existence**: Verify the Issue exists
   ```bash
   gh issue view <issue_number> --json number 2>/dev/null || echo "Issue not found"
   ```
   If Issue does not exist, report error and terminate

### 1. Get Issue Information

```bash
gh issue view <issue_number> --json number,title,body,labels,assignees,milestone,comments
```

### 2. Analyze Issue Content

Analyze Issue from the following perspectives:

- **Purpose**: What is to be achieved
- **Background**: Why this Issue was created
- **Technical Elements**: Mentioned components, APIs, data structures
- **Constraints**: Explicit or implicit constraints

### 3. Investigate Codebase

Based on Issue content, investigate the following:

**Note**: In Claude Code environment, use dedicated tools instead of shell commands:
- Use `Grep` tool for content search (instead of `grep -r`)
- Use `Glob` tool for file pattern matching (instead of `find`)

```
# Code search by keyword (using Grep tool)
Grep: pattern="<keyword>", glob="*.{ts,tsx}"

# Search by file name pattern (using Glob tool)
Glob: pattern="**/*<pattern>*"

# Check specific directory structure
ls -la src/
```

### 4. Identify Related Files

Classify related files into the following categories:

- **Directly Related**: Files explicitly mentioned in Issue
- **Indirectly Related**: Files inferred from dependencies
- **Tests**: Related test files
- **Documentation**: Related documentation

### 5. Organize Results

Report investigation results in structured format

## Output

### Output File

Investigation results are saved to:

```
.wf/research/<issue_number>.md
```

Example: `.wf/research/123.md` for Issue #123

### Caching

- Previous investigation results are preserved in `.wf/research/`
- When re-investigating the same Issue, check for existing results first
- If existing results found, compare timestamps and update incrementally if needed
- Cache invalidation: Results older than 7 days should be refreshed

### Handoff to wf1-kickoff

After completing investigation, the results are used by `wf1-kickoff`:

1. Research output file (`.wf/research/<issue>.md`) serves as input for kickoff
2. `wf1-kickoff` reads the "Related Files" and "Technical Elements" sections
3. Investigation findings inform the scope and approach of the work plan

### Output Format

```markdown
## Issue Investigation Results

### Issue Summary

- **Number**: #<number>
- **Title**: <title>
- **Labels**: <labels>

### Purpose and Background

<Explanation of Issue purpose and background>

### Technical Elements

| Element | Description |
|---------|-------------|
| <component> | <description> |

### Related Files

#### Directly Related

| File | Role |
|------|------|
| <path> | <role> |

#### Indirectly Related

| File | Relation Reason |
|------|-----------------|
| <path> | <reason> |

#### Tests

| File | Coverage |
|------|----------|
| <path> | <coverage> |

### Existing Similar Implementations

<Document here if similar implementations exist>

### Points to Consider

- <point1>
- <point2>

### Items Requiring Additional Investigation

- <item1>
- <item2>
```
