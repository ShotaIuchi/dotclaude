# Commit Message Schema

## Format

```
<type>(<scope>): <subject>

<body>
```

## Type（必須）

| type | 説明 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| docs | ドキュメントのみ |
| style | フォーマット（コード動作に影響なし） |
| refactor | リファクタリング |
| test | テスト追加・修正 |
| chore | ビルド・補助ツール |

## Scope（任意）

変更の主要コンポーネントを指定：
- 単一ファイル変更: ファイル名（拡張子なし）
- 複数ファイル変更: 共通の親ディレクトリまたは機能名

## Subject（必須）

- 50文字以内
- 末尾にピリオドを付けない
- 命令形で書く（Add, Fix, Update...）

## Body（任意）

- 各行72文字以内
- 変更の理由や背景を記載
