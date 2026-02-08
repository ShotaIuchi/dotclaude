---
name: migration-breaking
description: >-
  Breaking change analysis for migrations. Apply when cataloging incompatible
  API changes, removed features, behavioral differences, deprecated usage,
  and version-specific breaking changes.
user-invocable: false
---

# Breaking Change Analysis

Analyze code for breaking changes during migration.

## Migration Checklist

### API Incompatibilities
- Identify changed method signatures and return types
- Catalog removed or renamed public APIs
- Check for changed default parameter values
- Verify event and callback contract changes

### Removed & Deprecated Features
- List all removed APIs with replacement alternatives
- Identify deprecated features scheduled for removal
- Check for removed configuration options
- Verify removed CLI flags or environment variables

### Behavioral Changes
- Detect changed error handling semantics
- Identify altered sorting, ordering, or iteration behavior
- Check for changed concurrency or async behavior
- Verify modified lifecycle hook timing or order

### Type & Signature Changes
- Identify changed generic type parameters
- Check for narrowed or widened type constraints
- Verify changed nullability annotations
- Detect incompatible interface or protocol changes

## Output Format

Report findings with risk ratings:

| Risk | Description |
|------|-------------|
| Critical | Binary or runtime incompatibility, blocks migration |
| High | Significant behavioral change, likely causes bugs |
| Medium | Subtle change, may cause issues in edge cases |
| Low | Minor change, unlikely to cause problems |
