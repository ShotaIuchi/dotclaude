# Reference Decisions Rule

Rule for managing technology decision records in `references/`.

## Overview

Each category directory under `references/` must contain a `decisions.md` file that records technology adoption and rejection decisions. Do not use `index.md` as a collection of links to official documentation.

## File Naming

| Filename | Allowed | Reason |
|----------|---------|--------|
| `decisions.md` | ✅ Yes | Clearly indicates technology decision records |
| `index.md` | ❌ No | Implies an empty table of contents; duplicates official knowledge Claude already has |

## decisions.md Structure

### Required Sections

```markdown
# {Category} Technology Decisions

## Adopted Technologies

| Technology | Purpose | Adoption Reason | Alternatives |
|------------|---------|----------------|-------------|
| ... | ... | ... | ... |

## Rejected Options

| Technology | Rejection Reason |
|------------|-----------------|
| ... | ... |

## Related Documents

- [conventions.md](conventions.md) — ...
- [architecture-patterns.md](architecture-patterns.md) — ...
```

### Section Responsibilities

| Section | Include | Exclude |
|---------|---------|---------|
| Adopted Technologies | Technologies used, purpose, adoption reason, alternatives | Official documentation URLs |
| Rejected Options | Technologies not used, rejection reason | Future adoption plans |
| Related Documents | Links to files in the same directory | External URLs |

## Separation of Concerns

| File | Role | Example |
|------|------|---------|
| `decisions.md` | **What to use and what not to use** | Adopt Hilt, reject Koin |
| `conventions.md` | **How to write** | Naming rules, directory structure |
| `*-patterns.md` | **How to architect** | MVVM/UDF implementation patterns |

## Adding a New Category

When adding a new category under `references/`:

1. Create `decisions.md` following the template above
2. Update directory structure and category tables in `references/INDEX.md`
3. Do not create a collection of official documentation links

## Prohibitions

- Do not create `index.md` files under `references/`
- Do not include official documentation URL collections in `decisions.md` (Claude already knows official information)
- Do not list technology names without adoption/rejection reasons
