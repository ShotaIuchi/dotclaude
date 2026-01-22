# Commit Message Schema

## Format

```
<type>: <subject>

[body]

[footer]
```

## Type (Required)

| Type | Purpose |
|------|---------|
| `feat` | New feature addition |
| `fix` | Bug fix |
| `docs` | Documentation only changes |
| `style` | Changes that don't affect code meaning (whitespace, formatting, etc.) |
| `refactor` | Code changes that are neither bug fixes nor feature additions |
| `test` | Adding or modifying tests |
| `chore` | Build process or tool changes |

## Subject (Required)

- 50 characters or less
- No period at the end
- Use imperative mood (Add, Fix, Update...)

## Body (Optional)

- Describe the reason or background of the change
- Wrap at 72 characters

## Footer (Optional)

- Breaking Change description
- Issue reference (e.g., `Closes #123`)

## Example

```
feat: Add wf0-nextstep command

Implement feature to suggest next workflow step.
Reads state.json status and displays appropriate next action.

Closes #42
```
