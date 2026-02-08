---
name: migration-test
description: >-
  Test migration and adaptation. Apply when updating test code, test utilities,
  mocks, assertions, test frameworks, and ensuring test coverage is maintained
  through migration.
user-invocable: false
---

# Test Migration

Update and adapt tests to work with the migrated codebase.

## Migration Checklist

### Test Framework Updates
- Update test runner configuration for new framework version
- Migrate deprecated test lifecycle hooks and annotations
- Replace removed assertion methods with new equivalents
- Verify test discovery and execution still works correctly

### Mock & Stub Adaptation
- Update mock library calls to match new API signatures
- Replace deprecated mocking patterns with current idioms
- Verify mock setup and teardown follows new conventions
- Check that spy and capture APIs are updated

### Assertion Updates
- Replace deprecated assertion syntax with modern equivalents
- Update custom matchers to comply with new interfaces
- Verify error message formatting in assertion failures
- Check for changed equality semantics in assertions

### Coverage Preservation
- Compare test coverage before and after migration
- Identify tests that were skipped or broken by migration
- Ensure critical paths retain full test coverage
- Add missing tests for newly introduced migration code

## Output Format

Report findings with risk ratings:

| Risk | Description |
|------|-------------|
| Critical | Tests silently pass but no longer verify behavior |
| High | Significant test coverage lost, gaps in verification |
| Medium | Some tests need updating but coverage is adequate |
| Low | Minor test syntax changes, coverage is maintained |
