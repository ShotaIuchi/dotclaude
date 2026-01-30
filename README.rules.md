# rules/

プロジェクトルール定義ディレクトリ。

## 概要

ワークフローやClaude Codeの動作に関するルールを定義。
これらのルールはCLAUDE.mdから参照され、自動的に適用される。

## ルール一覧

### 基本ルール

| ファイル | 目的 |
|----------|------|
| `commit-guard.md` | コミット前のスキーマ検証ルール |
| `docs-sync.md` | ドキュメント日本語訳の同期ルール |
| `hooks.md` | フックシステムの仕様と設定 |
| `parallel-execution.md` | 並列実行による効率化ルール |
| `remote-operation.md` | リモートワークフロー操作ルール |
| `reference-decisions.md` | リファレンス内決定記録ルール |

### コンテキストルール

開発タスク時に自動適用されるコンテキスト:

| ファイル | 対象 |
|----------|------|
| `context-android.md` | Android開発タスク |
| `context-ios.md` | iOS開発タスク |
| `context-kmp.md` | Kotlin Multiplatform開発タスク |
| `context-aws-sam.md` | AWS SAMサーバーレス開発 |

## 使用方法

ルールはCLAUDE.mdに記載することで自動適用される。

```markdown
<!-- CLAUDE.md -->
詳細は `rules/hooks.md` を参照。
```

## 関連

- コミットスキーマ: `.claude/rules/commit.schema.md`
- フック設定: `hooks.json`
