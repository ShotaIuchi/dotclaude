# Commit Message Schema

## Format

```
<type>(<scope>): <subject>

<body>
```

## Type (Required)

| type | Description |
|------|-------------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation only |
| style | Formatting (no code behavior change) |
| refactor | Refactoring |
| test | Add or modify tests |
| chore | Build or auxiliary tools |

## Scope (Optional)

Specify the main component of the change:
- Single file change: File name (without extension)
- Multiple file change: Common parent directory or feature name

## Subject (Required)

- 50 characters or less
- No period at the end
- Use imperative mood (Add, Fix, Update...)

## Body (Optional)

- Each line 72 characters or less
- Describe the reason or background of the change
