---
name: migration-resolver
description: >-
  Dependency resolution for migrations. Apply when resolving version conflicts,
  transitive dependency issues, peer dependency requirements, and incompatible
  dependency trees.
user-invocable: false
---

# Dependency Resolution

Resolve dependency conflicts during migration.

## Migration Checklist

### Version Conflict Resolution
- Identify direct dependency version incompatibilities
- Resolve conflicting version ranges across packages
- Verify pinned versions are compatible with target migration
- Check for version constraints that block upgrading

### Transitive Dependencies
- Map the full transitive dependency tree for changes
- Identify indirect dependencies pulled in by upgrades
- Check for diamond dependency conflicts
- Verify transitive dependency licenses remain compliant

### Peer Requirements
- Validate peer dependency ranges after version bumps
- Identify unmet peer dependency warnings
- Check for plugins or extensions requiring specific peer versions
- Ensure peer dependency declarations are updated in package metadata

### Dependency Tree Health
- Audit for known vulnerabilities in updated dependencies
- Check for abandoned or unmaintained dependencies
- Verify no duplicate packages exist at incompatible versions
- Validate the lock file is consistent and reproducible

## Output Format

Report findings with risk ratings:

| Risk | Description |
|------|-------------|
| Critical | Unresolvable conflict, blocks migration entirely |
| High | Conflict requires major refactoring or replacement |
| Medium | Conflict resolvable with version pinning or overrides |
| Low | Minor version bump, no conflicts expected |
