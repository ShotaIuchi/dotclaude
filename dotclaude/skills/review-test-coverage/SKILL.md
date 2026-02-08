---
name: review-test-coverage
description: >-
  Test coverage-focused code review. Apply when reviewing code for
  missing unit tests, integration tests, edge cases, error handling paths,
  test quality, and test maintainability.
user-invocable: false
---

# Test Coverage Review

Review code from a testing perspective.

## Review Checklist

### Unit Test Coverage
- Verify all public functions have unit tests
- Check boundary conditions and edge cases are tested
- Look for missing null/empty/error path tests
- Verify assertions are meaningful (not just "no exception thrown")

### Integration Test Coverage
- Check critical user flows have integration tests
- Verify API endpoints are tested end-to-end
- Look for missing database interaction tests
- Check external service integration points

### Test Quality
- Verify tests are independent (no shared mutable state)
- Check test naming clearly describes the scenario
- Look for flaky tests (timing, ordering, external dependencies)
- Verify proper use of mocks/stubs (not over-mocking)

### Edge Cases & Error Handling
- Check error paths are tested (exceptions, failures)
- Verify timeout and retry behavior is tested
- Look for race condition tests in concurrent code
- Check boundary values (0, -1, MAX, empty, null)

### Test Maintainability
- Verify test helpers/fixtures reduce duplication
- Check tests don't depend on implementation details
- Look for proper setup/teardown handling
- Verify test data is clear and self-documenting

## Output Format

Report findings with priority:

| Priority | Description |
|----------|-------------|
| Missing | Critical path without any test coverage |
| Incomplete | Test exists but misses important cases |
| Quality | Test exists but has quality issues |
| Enhancement | Additional test would improve confidence |
