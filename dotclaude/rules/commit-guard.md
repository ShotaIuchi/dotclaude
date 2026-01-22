---
priority: MUST
---

# Commit Guard Rule

## Prerequisites

Before committing, verify that a schema exists in one of the following locations:

**Project-specific (priority):**
- `docs/rules/git.md`
- `docs/rules/commit.schema.md`
- `docs/rules/commit.md`

**Global (fallback):**
- `.claude/rules/git.md`
- `.claude/rules/commit.schema.md`
- `.claude/rules/commit.md`

## Guard (MUST)

If the schema does not exist in either location, **do not execute `git commit` for any reason**.

In that case, do one of the following:

- Create the schema/rule document first (let the user choose the save location)
- Notify the user "Cannot commit because schema is missing" and terminate

## Save Location Options

When creating a new schema, present the following options to the user:

| Option | Path | Purpose |
|--------|------|---------|
| `docs/` | `docs/rules/commit.schema.md` | Project-specific, committed to repository |
| `.claude/` | `.claude/rules/commit.schema.md` | Project-specific, committed to repository |
| `~/.claude/` | `~/.claude/rules/commit.schema.md` | Global, shared across all projects |

**Default recommendation**: `docs/` (managed as project documentation)

## Post-Creation Behavior (MUST)

If a schema was newly created, **do not proceed to commit**.

After creation, do the following and terminate:

1. Notify the user of the created schema file path
2. Instruct "Schema has been created. Please review the content and request commit again"
3. Terminate without performing the commit
