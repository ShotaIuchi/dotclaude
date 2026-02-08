---
name: debug-dependency
description: >-
  Dependency and version investigation. Apply when debugging version conflicts,
  breaking changes in libraries, transitive dependency issues, and
  incompatibility errors.
user-invocable: false
---

# Dependency Auditor Investigation

Investigate dependency and version issues that cause build failures or runtime errors.

## Investigation Checklist

### Version Compatibility
- Check declared version constraints against installed versions
- Identify version range specifications that resolve to incompatible releases
- Verify peer dependency requirements are satisfied
- Look for version pinning that prevents necessary updates
- Check for diamond dependency conflicts with incompatible versions

### Breaking Changes
- Review changelogs for breaking changes between current and expected versions
- Identify removed or renamed APIs causing compile or runtime errors
- Check for behavior changes in existing APIs that alter semantics
- Verify default value changes that affect implicit configurations
- Look for deprecation warnings that preceded the breaking change

### Transitive Dependencies
- Map the full dependency tree to find conflict sources
- Identify duplicate packages at different versions in the tree
- Check for transitive dependencies that override direct declarations
- Verify resolution strategies do not silently pick wrong versions
- Look for phantom dependencies used but not declared explicitly

### Runtime vs Build Dependencies
- Verify build-time dependencies are not leaking into runtime
- Check for missing runtime dependencies excluded during packaging
- Identify development dependencies incorrectly marked as production
- Verify native binary dependencies match the target platform
- Look for optional dependencies that fail silently at runtime

## Output Format

Report findings with confidence ratings:

| Confidence | Description |
|------------|-------------|
| High | Root cause clearly identified with supporting evidence |
| Medium | Probable cause identified but needs verification |
| Low | Hypothesis formed but insufficient evidence |
| Inconclusive | Unable to determine from available information |
