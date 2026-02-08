---
name: migration-compatibility
description: >-
  Compatibility layer design for migrations. Apply when creating adapters,
  shims, polyfills, abstraction layers, and incremental migration bridges
  between old and new systems.
user-invocable: false
---

# Compatibility Bridge Design

Design compatibility layers to bridge old and new systems during migration.

## Migration Checklist

### Adapter Design
- Define adapter interfaces for changed APIs
- Implement wrappers that translate old calls to new APIs
- Ensure adapters handle edge cases from both versions
- Verify adapter performance overhead is acceptable

### Abstraction Layers
- Create version-agnostic abstractions over divergent APIs
- Isolate version-specific code behind clean interfaces
- Ensure abstractions do not leak implementation details
- Validate abstraction coverage for all affected call sites

### Incremental Migration Path
- Define phase-by-phase migration milestones
- Ensure each phase produces a working system
- Identify safe stopping points for partial migration
- Provide rollback capability at each migration phase

### Coexistence Strategy
- Verify old and new code can run side by side
- Check for shared state conflicts between versions
- Ensure dependency versions do not clash at runtime
- Validate integration tests cover coexistence scenarios

## Output Format

Report findings with risk ratings:

| Risk | Description |
|------|-------------|
| Critical | No viable compatibility path, redesign required |
| High | Complex bridging needed, significant effort required |
| Medium | Standard adapter pattern sufficient, moderate effort |
| Low | Minor shim needed, straightforward implementation |
