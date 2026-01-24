# 日本語ドキュメント

dotclaudeプロジェクトの日本語訳ドキュメント。

## 概要

このディレクトリには、dotclaudeの各ドキュメントの日本語訳が含まれています。
元ドキュメントが作成・更新された際は、対応する日本語訳も同期的に更新されます。

## ファイル一覧

### コア文書

| ファイル | 元ファイル | 説明 |
|----------|-----------|------|
| `CLAUDE.md` | `CLAUDE.md` | プロジェクト概要 |
| `PRINCIPLES.md` | `PRINCIPLES.md` | 根本原則 |
| `CONSTITUTION.md` | `CONSTITUTION.md` | 憲法（絶対ルール） |

### コマンド

| ファイル | 元ファイル | 説明 |
|----------|-----------|------|
| `commands.wf0-status.md` | `commands/wf0-status.md` | ステータス表示 |
| `commands.wf0-restore.md` | `commands/wf0-restore.md` | ワークスペース復元 |
| `commands.wf0-nextstep.md` | `commands/wf0-nextstep.md` | 次ステップ実行 |
| `commands.wf1-workspace.md` | `commands/wf1-workspace.md` | ワークスペース作成 |
| `commands.wf2-kickoff.md` | `commands/wf2-kickoff.md` | Kickoff作成 |
| `commands.wf3-spec.md` | `commands/wf3-spec.md` | 仕様書作成 |
| `commands.wf4-plan.md` | `commands/wf4-plan.md` | 実装計画作成 |
| `commands.wf5-review.md` | `commands/wf5-review.md` | レビュー作成 |
| `commands.wf6-implement.md` | `commands/wf6-implement.md` | 実装 |
| `commands.wf7-verify.md` | `commands/wf7-verify.md` | 検証・PR作成 |
| `commands.agent.md` | `commands/agent.md` | エージェント呼び出し |
| `commands.doc-review.md` | `commands/doc-review.md` | ドキュメントレビュー |
| `commands.doc-fix.md` | `commands/doc-fix.md` | レビュー修正適用 |
| `commands.subask.md` | `commands/subask.md` | サブエージェントへ質問 |
| `commands.subcommit.md` | `commands/subcommit.md` | 非同期コミット |

### ルール

| ファイル | 元ファイル | 説明 |
|----------|-----------|------|
| `rules.commit-guard.md` | `rules/commit-guard.md` | コミットガード |
| `rules.hooks.md` | `rules/hooks.md` | フックシステム |
| `rules.parallel-execution.md` | `rules/parallel-execution.md` | 並列実行 |
| `rules.docs-sync.md` | `rules/docs-sync.md` | ドキュメント同期 |

## 命名規則

- 元ファイルパスの`/`を`.`に置換
- 例: `commands/wf1-workspace.md` → `commands.wf1-workspace.md`

## メンテナンス

ドキュメントの作成・更新時は`rules/docs-sync.md`に従い、
対応する日本語訳も同時に更新すること。
