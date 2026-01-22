# CONSTITUTION

This file defines **absolute rules**.
Always comply when adding new files or making changes. Violations must be corrected immediately.

> **Note**: This constitution is subordinate to `PRINCIPLES.md` (Principles).
> If there is a conflict with the principles, the principles take precedence.

---

## Article 1: Immediate Structure Finalization

When adding new files or directories, finalize the structure on the spot.

### Prohibited
- Placements that are "temporary" or "to be organized later"
- Adding new directories directly under root (ungrouped additions)
- Hierarchies that contradict existing structure

### Required
- Place in existing group directories
- If a new group is needed, update this constitution first

### Delegation of Structure Definition

If INDEX.md or README.md exists in each directory, follow its definitions.
If not present, follow the naming and placement patterns of existing files.
The constitution defines only principles; implementation details are delegated to each directory.

---

## Article 2: Simultaneous Documentation Creation

When adding files, create or update related documentation simultaneously.

- When adding new categories or modules, create explanatory documentation simultaneously
- If existing indexes or lists exist, update them simultaneously

---

## Article 3: Naming Convention Compliance

Follow existing naming patterns. Do not introduce new naming conventions.

- Follow the naming conventions of existing files in the same directory
- Follow standard conventions of the language/framework if applicable

---

## Article 4: Complete Dependency Resolution

When adding files, resolve all dependencies simultaneously.

### Prohibited
- References to non-existent files
- Additions with the assumption of "fixing paths later"
- Moves that break references in other files

---

## Article 5: Immediate Response to Violations

When an addition or change that violates this constitution is discovered:

1. **Correct immediately** - Fix before proceeding to the next task
2. **No rollback in violation state** - No commits in violation state
3. **Update constitution** - If the rule is inappropriate, update the constitution first

---

## Article 6: Pre-Execution Command Verification

Before executing a shell command, verify that the command exists.

### Prohibited
- Executing non-existent commands and generating errors
- The attitude of "just trying to execute"

### Required
- If the command does not exist, provide installation instructions
- Suggest installation or alternative means after obtaining user permission

---

## Addendum: Updating the Constitution

When updating this constitution itself:
1. Clearly state the reason for change
2. Confirm impact on existing files
3. If there is impact, correct simultaneously
