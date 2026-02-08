---
name: feature-test
description: >-
  Test creation for new features. Apply when creating unit tests,
  integration tests, edge case coverage, and test fixtures for
  newly implemented functionality.
user-invocable: false
---

# Test Writer Implementation

Create tests for newly implemented feature functionality.

## Implementation Checklist

### Unit Test Coverage
- Write tests for all public methods and functions
- Verify happy path scenarios produce expected results
- Check that each test validates a single behavior
- Ensure proper use of mocks and stubs for dependencies
- Validate test naming follows project conventions

### Integration Tests
- Write tests for component interaction boundaries
- Verify API endpoint request/response contracts
- Check database operations with real or in-memory stores
- Ensure external service integrations use test doubles
- Validate end-to-end workflows across layers

### Edge Case Coverage
- Test boundary values (zero, empty, max, min)
- Verify null and undefined input handling
- Check concurrent access and race condition scenarios
- Ensure error paths return appropriate failures
- Validate timeout and retry behavior

### Test Data & Fixtures
- Create reusable test fixtures and factories
- Verify test data represents realistic scenarios
- Check for proper test isolation (no shared mutable state)
- Ensure setup and teardown clean up resources
- Validate test determinism (no flaky dependencies)

## Output Format

Report implementation status:

| Status | Description |
|--------|-------------|
| Complete | Fully implemented and verified |
| Partial | Implementation started, needs remaining work |
| Blocked | Cannot proceed due to dependency or decision needed |
| Skipped | Not applicable to this feature |
