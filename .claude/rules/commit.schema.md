# Commit Message Schema

## フォーマット

```
<type>: <subject>

[body]

[footer]
```

## Type（必須）

| Type | 用途 |
|------|------|
| `feat` | 新機能追加 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | コードの意味に影響しない変更（空白、フォーマット等） |
| `refactor` | バグ修正でも機能追加でもないコード変更 |
| `test` | テストの追加・修正 |
| `chore` | ビルドプロセスやツールの変更 |

## Subject（必須）

- 50文字以内
- 末尾にピリオドを付けない
- 命令形で記述（日本語の場合は体言止め）

## Body（任意）

- 変更の理由や背景を記述
- 72文字で折り返し

## Footer（任意）

- Breaking Changeの記述
- Issue参照（例: `Closes #123`）

## 例

```
feat: wf0-nextstep コマンドを追加

ワークフローの次ステップを提案する機能を実装。
state.jsonの状態を読み取り、適切な次アクションを表示する。

Closes #42
```
