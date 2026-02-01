# Commit Message Schema

## Format

```
<type>: <ticket> <subject>

[body]

[footer]
```

## Language (Required)

- Subject and body must be written in **Japanese**
- Type prefix remains in English (`feat`, `fix`, etc.)
- Ticket references remain in original format (`#123`, `PROJ-123`)

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
- Write in Japanese (e.g., 「〜を追加」「〜を修正」)

## Body (Optional)

- Describe the reason or background of the change in Japanese
- Wrap at 72 characters

## Footer (Optional)

- Breaking Change description
- Issue reference (e.g., `Closes #123`)

## Examples

```
feat: #40 wf0-nextstepコマンドを追加

次のワークフローステップを提案する機能を実装。
state.jsonのステータスを読み取り、適切な次のアクションを表示する。
```

```
fix: #87 トークンリフレッシュのタイミングを修正
```

```
refactor: ワークフローテンプレートの番号を0始まりから1始まりに変更
```
