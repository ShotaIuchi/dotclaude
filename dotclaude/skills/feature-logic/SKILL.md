---
name: feature-logic
description: >-
  Business logic implementation. Apply when implementing core business
  rules, validation logic, workflows, state machines, and domain-specific
  algorithms for new features.
user-invocable: false
---

# Business Logic Implementer Implementation

Implement core business logic for new features.

## Implementation Checklist

### Business Rules
- Implement domain rules matching specification requirements
- Verify boundary conditions and edge case handling
- Check for proper separation of business logic from infrastructure
- Ensure business rules are unit testable in isolation
- Validate rule consistency across related operations

### Validation Logic
- Implement input validation at domain boundary
- Verify validation error messages are descriptive and actionable
- Check for proper validation ordering (cheap checks first)
- Ensure cross-field and cross-entity validation rules
- Validate sanitization of user-provided data

### Workflow & State Management
- Implement state transitions with proper guard conditions
- Verify invalid state transition prevention
- Check for proper event emission on state changes
- Ensure workflow steps are idempotent where required
- Validate concurrent state modification handling

### Algorithm Correctness
- Verify algorithm produces correct output for all input ranges
- Check for proper handling of empty, null, and boundary inputs
- Ensure deterministic behavior for same inputs
- Validate computational complexity meets performance requirements
- Check for proper error propagation through computation chains

## Output Format

Report implementation status:

| Status | Description |
|--------|-------------|
| Complete | Fully implemented and verified |
| Partial | Implementation started, needs remaining work |
| Blocked | Cannot proceed due to dependency or decision needed |
| Skipped | Not applicable to this feature |
