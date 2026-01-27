# Docs Sync ルール

ドキュメントの日本語訳を自動的に維持するためのルール。

## ソース言語の要件（CONSTITUTION 第7条）

**すべてのソースドキュメントは英語で記述しなければならない。** `skills/`, `agents/`, `rules/`, `references/`, `templates/` 配下のすべての `.md` ファイル、およびルートレベルのドキュメント（`CLAUDE.md`, `PRINCIPLES.md`, `CONSTITUTION.md`）が対象。ソースドキュメントに日本語を含めてはならない。

## 概要

`dotclaude/`内のドキュメント（`.md`ファイル）を作成・更新した際は、対応する日本語訳ファイルを`docs/readme/`ディレクトリに作成・更新する。

## 対象ファイル

| 元ファイル | 日本語訳ファイル |
|-----------|-----------------|
| `CLAUDE.md` | `docs/readme/CLAUDE.md` |
| `PRINCIPLES.md` | `docs/readme/PRINCIPLES.md` |
| `CONSTITUTION.md` | `docs/readme/CONSTITUTION.md` |
| `commands/{name}.md` | `docs/readme/commands.{name}.md` |
| `rules/{name}.md` | `docs/readme/rules.{name}.md` |
| `agents/{category}/{name}.md` | `docs/readme/agents.{category}.{name}.md` |
| `skills/{name}/SKILL.md` | `docs/readme/skills.{name}.md` |

## 命名規則

- パスの`/`を`.`に置換
- 拡張子は`.md`を維持
- 例: `commands/wf1-kickoff.md` → `docs/readme/commands.wf1-kickoff.md`

## 翻訳内容

### 含めるもの

- 目的・概要の説明
- 使用方法（コマンド構文、引数）
- 実行例
- 注意事項・制約

### 含めないもの

- サンプルコード全体（コードブロックは最小限に）
- 実装の詳細
- 内部的なメタデータ

## ワークフロー

### 新規作成時

1. 元ドキュメントを作成
2. `docs/readme/`に日本語訳ファイルを作成
3. 両方を同一コミットに含める

### 更新時

1. 元ドキュメントを更新
2. 日本語訳ファイルを同期更新
3. 両方を同一コミットに含める

## 例外

以下のファイルは翻訳対象外:

- `docs/reviews/` - 内部レビュー記録
- `templates/` - ユーザープロジェクト向けテンプレート
- `references/` - 技術リファレンス（必要に応じて個別対応）
- `examples/` - サンプルファイル
- `tests/` - テストファイル
