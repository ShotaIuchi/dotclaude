---
name: refactor-compat
description: >-
  Backward compatibility verification for refactoring. Apply when checking
  public API compatibility, exported interfaces, external contracts, and
  identifying breaking changes requiring migration guides.
user-invocable: false
---

# Compatibility Checker Analysis

Verify backward compatibility for public APIs, exported interfaces, and external contracts.

## Analysis Checklist

### Public API Compatibility
- Check function signatures for parameter changes (order, type, count)
- Verify return type consistency across versions
- Detect removed or renamed public methods and properties
- Validate default value changes that alter existing behavior

### Interface Contracts
- Verify exported types and interfaces remain compatible
- Check protocol/trait implementations for missing methods
- Validate serialization format compatibility (JSON, protobuf, etc.)
- Ensure event schemas and message formats are backward compatible

### Breaking Change Detection
- Identify semantic changes that alter behavior without API changes
- Detect configuration format changes requiring user updates
- Find removed feature flags or environment variables
- Check database schema changes affecting existing data

### Migration Guide Requirements
- Define upgrade steps for each breaking change identified
- Provide deprecation warnings with recommended alternatives
- Plan compatibility shims for gradual consumer migration
- Document timeline for removing backward compatibility support

### Version Strategy
- Recommend semantic versioning impact (major, minor, patch)
- Plan deprecation period length based on consumer count
- Define compatibility testing matrix across supported versions
- Identify opportunities to batch breaking changes together

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Breaking | Incompatible change requiring all consumers to update |
| High | Behavioral change that may break consumers silently |
| Medium | Deprecation requiring consumer action within a timeline |
| Low | Compatible change with optional migration for improvement |
