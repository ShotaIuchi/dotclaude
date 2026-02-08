---
name: refactor-archeology
description: >-
  Code history and rationale investigation for refactoring. Apply when
  researching git blame, commit history, code comments, hidden constraints,
  and historical design decisions.
user-invocable: false
---

# Code Archeologist Analysis

Research the history of the code to understand why decisions were made and identify hidden constraints.

## Analysis Checklist

### Git History Analysis
- Run git blame on target files to identify authors and change dates
- Review commit messages for rationale behind key decisions
- Trace the evolution of critical functions through git log
- Identify code that has been frequently modified (churn analysis)

### Decision Rationale
- Extract reasoning from commit messages and PR descriptions
- Check for linked issues or tickets explaining requirements
- Identify comments that document "why" rather than "what"
- Look for TODO/FIXME/HACK comments with historical context

### Hidden Constraints
- Detect workarounds for external system limitations
- Identify timing-sensitive code or ordering dependencies
- Find platform-specific behavior that constrains refactoring
- Check for undocumented business rules embedded in logic

### Legacy Pattern Identification
- Identify deprecated patterns still in use
- Find abandoned migration attempts (partial rewrites)
- Detect compatibility shims that may no longer be needed
- Map code that predates current architecture conventions

### Knowledge Preservation
- Document tribal knowledge found in comments and commit messages
- Record undocumented invariants that tests rely upon
- Capture performance constraints discovered through history
- List external system dependencies revealed by past incidents

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Breaking | Hidden constraint that will cause failures if not preserved |
| High | Historical decision with active dependencies on its behavior |
| Medium | Legacy pattern that should be updated but carries risk |
| Low | Historical artifact safe to remove or modernize |
