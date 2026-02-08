---
name: migration-transform
description: >-
  Automated code transformation for migrations. Apply when performing codemods,
  syntax updates, API renames, import path changes, and pattern replacements
  across the codebase.
user-invocable: false
---

# Code Transformation

Perform automated code transformations for migration.

## Migration Checklist

### Syntax Transformations
- Identify deprecated syntax patterns requiring updates
- Apply language version syntax migrations consistently
- Verify transformed code preserves original semantics
- Check for edge cases missed by automated transforms

### API & Import Updates
- Rename changed API calls across the codebase
- Update import paths to reflect new module structure
- Replace removed APIs with recommended alternatives
- Verify no stale imports remain after transformation

### Pattern Replacements
- Convert deprecated patterns to idiomatic new patterns
- Replace obsolete utility usage with modern equivalents
- Update error handling to match new conventions
- Transform configuration formats to new schema

### Automated Verification
- Run transformed code through type checker and linter
- Verify all codemods are idempotent and safe to re-run
- Check that no unintended changes were introduced
- Validate transformation coverage with before/after diffs

## Output Format

Report findings with risk ratings:

| Risk | Description |
|------|-------------|
| Critical | Transformation alters program behavior, manual fix needed |
| High | Ambiguous transformation, requires human review |
| Medium | Transformation is safe but needs verification |
| Low | Straightforward rename or import update |
