---
name: test-unit
description: >-
  Unit test creation. Apply when writing isolated tests for individual
  functions, methods, and classes with proper mocking, assertions, and
  coverage of happy paths and error conditions.
user-invocable: false
---

# Unit Tests

Write unit tests for individual functions, methods, and classes in isolation.

## Test Creation Checklist

### Function/Method Isolation
- Identify all external dependencies to mock or stub
- Ensure each test exercises exactly one unit of behavior
- Verify test independence (no shared mutable state between tests)
- Check that setup/teardown properly resets test context
- Confirm no reliance on execution order

### Assertion Completeness
- Assert return values for all meaningful inputs
- Verify state changes on mutable objects after method calls
- Check that expected exceptions are thrown with correct types and messages
- Assert side effects (method calls on collaborators, events emitted)
- Validate output structure, not just existence

### Happy Path Coverage
- Cover the primary success scenario end-to-end
- Test with typical/representative input values
- Verify correct behavior with valid boundary inputs
- Check default parameter behavior
- Test idempotent operations for consistent results

### Error Condition Coverage
- Test with invalid, null, and out-of-range inputs
- Verify graceful handling of dependency failures
- Check timeout and cancellation behavior
- Test concurrent access if applicable
- Validate error messages and error codes returned

## Output Format

Report test plan with priority ratings:

| Priority | Description |
|----------|-------------|
| Must | Core functionality tests that prevent regressions |
| Should | Important paths that cover common usage patterns |
| Could | Additional coverage for less common scenarios |
| Won't | Out of scope or covered by other test types |
