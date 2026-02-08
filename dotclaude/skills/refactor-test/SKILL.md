---
name: refactor-test
description: >-
  Test coverage verification for refactoring. Apply when verifying existing
  test coverage, identifying gaps, recommending pre-refactoring tests,
  and defining verification checkpoints.
user-invocable: false
---

# Test Guardian Analysis

Verify existing test coverage and ensure tests will catch regressions during refactoring.

## Analysis Checklist

### Existing Coverage Analysis
- Map test coverage for all files in the refactoring scope
- Identify which behaviors are covered by unit vs integration tests
- Check for tests that depend on implementation details (brittle tests)
- Verify edge cases and error paths are covered

### Gap Identification
- Find critical code paths with no test coverage
- Identify untested boundary conditions and error handling
- Detect missing integration tests between affected modules
- Check for untested concurrent or async behavior

### Pre-Refactoring Tests
- Recommend characterization tests to capture current behavior
- Define golden master tests for complex output verification
- Suggest contract tests for public API boundaries
- Plan snapshot tests for UI components affected by changes

### Verification Checkpoints
- Define test gates between each migration step
- Specify performance benchmarks to verify no regression
- Plan smoke tests for critical user journeys
- Establish monitoring checks for post-deployment verification

### Test Refactoring Readiness
- Identify brittle tests that will break from structural changes
- Recommend test rewrites to depend on behavior not implementation
- Check test isolation to prevent cascade failures
- Verify test data setup is independent of internal structure

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Breaking | Missing tests for critical path, refactoring unsafe to start |
| High | Significant coverage gap that must be filled before proceeding |
| Medium | Coverage gap that should be addressed during refactoring |
| Low | Minor gap, acceptable risk with manual verification |
