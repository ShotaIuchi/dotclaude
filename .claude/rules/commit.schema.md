# Commit Message Schema

## Format

```
<type>: <ticket> <subject>

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

## Ticket (Required when applicable)

- Placed at the beginning of the subject, before the description
- Accepts `#123` (GitHub Issue) or `PROJ-123` (Jira style) format
- Omit when no ticket is associated

## Subject (Required)

- 50 characters or less (including ticket)
- No period at the end
- Use imperative mood (Add, Fix, Update...)

## Body (Optional)

- Describe the reason or background of the change
- Wrap at 72 characters

## Footer (Optional)

- Breaking Change description
- Issue reference (e.g., `Closes #123`)

## Examples

```
feat: #40 Add wf0-nextstep command

Implement feature to suggest next workflow step.
Reads state.json status and displays appropriate next action.
```

```
fix: Closes-87 Correct token refresh timing
```

```
refactor: Renumber workflow templates from 0-based to 1-based
```
