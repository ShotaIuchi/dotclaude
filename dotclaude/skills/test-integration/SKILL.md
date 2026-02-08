---
name: test-integration
description: >-
  Integration test creation. Apply when writing tests that verify component
  interactions, API contract compliance, database transactions, and
  end-to-end data flow across boundaries.
user-invocable: false
---

# Integration Tests

Write integration tests that verify interactions across component boundaries.

## Test Creation Checklist

### Component Interaction
- Test communication between modules through real interfaces
- Verify dependency injection wiring produces correct collaborators
- Check event propagation across component boundaries
- Validate callback and listener invocation order
- Confirm proper lifecycle management between components

### API Contract Verification
- Test request/response format compliance with specifications
- Verify HTTP status codes for success, error, and edge cases
- Check header handling (authentication, content-type, caching)
- Validate pagination, filtering, and sorting parameters
- Test versioning and backward compatibility of endpoints

### Database Transaction Testing
- Verify CRUD operations produce correct persistent state
- Test transaction rollback on failure conditions
- Check concurrent access and locking behavior
- Validate migration scripts apply cleanly on test data
- Confirm cascade operations (delete, update) work correctly

### End-to-End Flow
- Trace data from input through all processing layers to output
- Verify data transformation accuracy at each boundary
- Test complete user workflows spanning multiple services
- Check that error states propagate correctly across layers
- Validate cleanup and resource release after flow completion

## Output Format

Report test plan with priority ratings:

| Priority | Description |
|----------|-------------|
| Must | Critical integration paths that verify system correctness |
| Should | Important cross-boundary flows for common scenarios |
| Could | Additional integration scenarios for edge conditions |
| Won't | Out of scope or better covered by unit/e2e tests |
