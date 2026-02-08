---
name: refactor-impact
description: >-
  Blast radius and risk assessment for refactoring. Apply when analyzing
  affected consumers, change propagation, risk levels, and areas requiring
  extra caution during refactoring.
user-invocable: false
---

# Impact Assessor Analysis

Analyze the blast radius of changes, identify affected consumers, and assess risk levels.

## Analysis Checklist

### Blast Radius Analysis
- Map all modules directly affected by the refactoring
- Trace transitive impact through dependency chains
- Identify cross-service or cross-repository effects
- Estimate the number of files, functions, and tests impacted

### Consumer Impact
- List all internal consumers of the code being changed
- Identify external consumers (APIs, SDKs, plugins)
- Check for downstream services that depend on behavior
- Assess impact on build pipelines and deployment processes

### Risk Categorization
- Classify changes by likelihood of causing regression
- Assess severity of potential failures for each change
- Identify single points of failure in the refactoring plan
- Rate overall risk considering both likelihood and severity

### Caution Areas
- Flag code with high business criticality (payments, auth, data)
- Identify areas with poor test coverage in the blast radius
- Mark recently modified code that may have unstable behavior
- Highlight shared utilities used by many unrelated features

### Rollback Impact
- Assess difficulty of reverting each change independently
- Identify data migrations that complicate rollback
- Check for state changes that cannot be undone automatically
- Plan communication strategy if rollback is needed

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Breaking | Change will cause failures in production if not coordinated |
| High | Significant risk to critical functionality or many consumers |
| Medium | Moderate risk with known mitigation strategies |
| Low | Minimal risk, isolated change with limited blast radius |
