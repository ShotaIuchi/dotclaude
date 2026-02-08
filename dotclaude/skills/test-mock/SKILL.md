---
name: test-mock
description: >-
  Test double and fixture design. Apply when creating mock objects, stub
  responses, fake implementations, test factories, seed data, and reusable
  test fixtures.
user-invocable: false
---

# Mock/Fixture Design

Design test doubles, factories, and fixtures for reliable test infrastructure.

## Test Creation Checklist

### Mock Object Design
- Define clear interfaces for all mockable dependencies
- Configure mock return values matching realistic production data
- Set up verification for expected interaction counts and order
- Avoid over-mocking by using real implementations where practical
- Ensure mocks fail fast with descriptive error messages

### Stub & Fake Implementation
- Create lightweight fake implementations for complex dependencies
- Implement configurable stubs that support multiple test scenarios
- Verify fakes maintain behavioral parity with real implementations
- Provide error simulation modes (network failure, timeout, corruption)
- Keep fake implementations simple and avoid duplicating production logic

### Test Data Factories
- Build factories that produce valid default objects with minimal setup
- Support trait-based customization for specific test scenarios
- Ensure generated data satisfies all validation constraints
- Provide sequence generators for unique identifiers and timestamps
- Create related object graphs with proper foreign key relationships

### Fixture Management
- Organize shared fixtures by domain context, not by test file
- Implement setup/teardown that guarantees clean state between tests
- Use fixture scoping (test, class, module) appropriate to cost
- Version control seed data alongside schema migrations
- Document fixture dependencies and loading order requirements

## Output Format

Report test plan with priority ratings:

| Priority | Description |
|----------|-------------|
| Must | Core test doubles required for unit test isolation |
| Should | Factories and fixtures that reduce test boilerplate |
| Could | Convenience helpers for less common test scenarios |
| Won't | Over-engineered abstractions with limited reuse value |
