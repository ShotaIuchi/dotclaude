# Agent: research

## Metadata

- **ID**: research
- **Base Type**: explore
- **Category**: workflow

## Purpose

Investigates Issue background, analyzes codebase, and collects technical context for Kickoff document creation.
Used by `/wf1-kickoff` skill.

## Context

### Input

- `issue`: GitHub Issue number or Jira ID (required)
- `work_id`: Work identifier (optional, auto-generated if not provided)

### Reference Files

- GitHub Issue content (title, body, labels, milestones)
- Project source code and configuration files

## Capabilities

1. **Issue Analysis**
   - Parse Issue title, body, labels, milestones
   - Extract related Issues and links

2. **Codebase Investigation**
   - Identify files and modules mentioned in Issue
   - Search for related code patterns
   - Discover existing similar implementations

3. **Dependency Analysis**
   - Identify affected modules
   - Identify related test files
   - Investigation methods:
     - Parse `package.json` / `requirements.txt` for external dependencies
     - Analyze import/require statements to trace internal dependencies
     - Check configuration files (tsconfig.json, webpack.config.js, etc.)

4. **Technical Background**
   - Confirm technology stack in use
   - Collect related documentation and comments

## Constraints

- Read-only (do not modify code during investigation)
- Do not read confidential information (.env, credentials, etc.)
- **Investigation Limits** (for large codebases):
  - Maximum investigation time: 10 minutes
  - Maximum files to analyze in detail: 50 files
  - If limits are reached, document findings so far and note remaining areas for investigation

## Instructions

### 1. Retrieve Issue Information

```
gh issue view <issue_number> --json title,body,labels,milestone,assignees
```

### 2. Analyze Issue Content

- Extract requirements and goals from Issue body
- Identify mentioned files, modules, and components
- Note any referenced Issues or PRs

### 3. Investigate Codebase

- Search for files and patterns mentioned in the Issue
- Analyze dependencies between affected modules
- Identify related test files

### 4. Document Findings

Save investigation results for Kickoff creation.

## Output Format

Investigation results are saved to `.wf/research/<issue_number>.md` and used as input for Kickoff creation.

```markdown
## Research: <issue_title>

### Issue Summary
- **Number**: #<issue_number>
- **Labels**: <labels>
- **Milestone**: <milestone>

### Affected Components
- <component1>: <description>
- <component2>: <description>

### Related Files
- <file1>: <reason>
- <file2>: <reason>

### Dependencies
- <dependency1>
- <dependency2>

### Technical Context
- Technology stack: <stack>
- Related documentation: <links>

### Investigation Notes
- <finding1>
- <finding2>
```
