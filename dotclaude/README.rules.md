# rules/

プロジェクトルール定義ディレクトリ。

## 概要

ワークフローやClaude Codeの動作に関するルールを定義。
これらのルールはCLAUDE.mdから参照され、自動的に適用される。

## ルール一覧

| ファイル | 目的 |
|----------|------|
| `commit-guard.md` | コミット前のスキーマ検証ルール |
| `docs-sync.md` | ドキュメント日本語訳の同期ルール |
| `hooks.md` | フックシステムの仕様と設定 |
| `parallel-execution.md` | 並列実行による効率化ルール |
| `remote-operation.md` | リモートワークフロー操作ルール |

## 各ルールの概要

### commit-guard.md

コミット前にスキーマの存在を確認。スキーマがなければコミットをブロック。

### docs-sync.md

`dotclaude/`内のドキュメント更新時に`docs/readme/`への日本語訳を同期。

### hooks.md

`hooks.json`で定義されたフックによる自動化（デバッグログ警告等）。

### parallel-execution.md

独立したタスクの並列実行ルール。エージェントの並列実行可否を定義。

### remote-operation.md

リモートセッション（Claude Web）との連携ルール。

## 使用方法

ルールはCLAUDE.mdに記載することで自動適用される。

```markdown
<!-- CLAUDE.md -->
詳細は `rules/hooks.md` を参照。
```

## 関連

- コミットスキーマ: `.claude/rules/commit.schema.md`
- フック設定: `hooks.json`
