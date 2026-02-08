---
name: refactor-migration
description: >-
  Step-by-step migration planning for refactoring. Apply when creating
  incremental migration plans, defining rollback points, feature flags,
  and ensuring each step leaves code in a working state.
user-invocable: false
---

# Migration Planner Analysis

Create a step-by-step migration plan that ensures each step leaves the codebase in a working state.

## Analysis Checklist

### Step Decomposition
- Break the refactoring into the smallest independently deployable steps
- Verify each step produces a compilable and testable codebase
- Order steps to minimize risk and maximize early feedback
- Identify steps that can be parallelized across team members

### Rollback Points
- Define clear rollback criteria for each migration step
- Ensure rollback does not require forward-fixing other changes
- Verify data migrations are reversible or have backup strategies
- Plan rollback testing as part of the migration process

### Feature Flag Strategy
- Identify changes that benefit from feature flag protection
- Design flag granularity (per-feature, per-component, per-user)
- Plan flag cleanup timeline to avoid permanent toggles
- Ensure both old and new code paths remain tested

### Incremental Delivery
- Map migration steps to deployable milestones
- Define success criteria and verification for each milestone
- Plan communication points for dependent teams
- Identify minimum viable migration for early value delivery

### Risk Mitigation
- Identify steps with highest failure probability
- Plan fallback strategies for each high-risk step
- Define monitoring and alerting for migration progress
- Establish go/no-go criteria for proceeding to next step

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Breaking | Step that cannot be rolled back without data loss |
| High | Step requiring coordinated deployment across services |
| Medium | Step with moderate risk, rollback plan available |
| Low | Safe step with straightforward rollback |
