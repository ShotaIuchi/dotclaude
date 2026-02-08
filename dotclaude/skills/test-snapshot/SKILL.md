---
name: test-snapshot
description: >-
  Snapshot and golden test creation. Apply when creating baseline capture
  tests for UI components, API response formats, serialization contracts,
  and detecting unintended output changes.
user-invocable: false
---

# Snapshot/Golden Tests

Create snapshot and golden tests that detect unintended output changes.

## Test Creation Checklist

### UI Snapshot Capture
- Capture visual snapshots for all component states (default, loading, error)
- Test across relevant viewport sizes and screen densities
- Include snapshots for light/dark themes and accessibility modes
- Verify interactive states (hover, focus, disabled, selected)
- Establish pixel tolerance thresholds for acceptable rendering variance

### API Response Baselines
- Capture baseline responses for all endpoint success cases
- Record error response structures for each error category
- Snapshot pagination metadata and envelope format
- Verify header values and content-type consistency
- Test response format stability across API versions

### Serialization Contract Tests
- Snapshot JSON/XML/Protobuf serialization output for domain models
- Verify backward compatibility when fields are added or deprecated
- Test deserialization of historical format versions
- Check that optional fields serialize/deserialize correctly
- Validate enum and union type serialization stability

### Change Detection Strategy
- Configure meaningful diff output for failed snapshot comparisons
- Exclude volatile fields (timestamps, random IDs) from comparisons
- Implement review workflow for intentional snapshot updates
- Group related snapshots for batch approval when schemas change
- Set up CI integration to block merges on unexpected snapshot diffs

## Output Format

Report test plan with priority ratings:

| Priority | Description |
|----------|-------------|
| Must | Contract snapshots preventing breaking serialization changes |
| Should | UI snapshots for primary components and key states |
| Could | Response baselines for secondary endpoints and formats |
| Won't | Snapshots for internal representations with no external contract |
