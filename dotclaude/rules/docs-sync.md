# Docs Sync Rule

Rule for automatically maintaining Japanese translations of documents.

## Source Language Requirement (CONSTITUTION Article 7)

**All source documents must be written in English.** This includes all `.md` files under `skills/`, `agents/`, `rules/`, `references/`, and `templates/`, as well as root-level documents (`CLAUDE.md`, `PRINCIPLES.md`, `CONSTITUTION.md`). Japanese text must never appear in source documents.

## Overview

When creating or updating documents (`.md` files) under `dotclaude/`, create or update the corresponding Japanese translation file in the `docs/readme/` directory.

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

## 検証

コミット前に以下を確認:

```bash
# 元ファイルと日本語訳の対応を確認
ls dotclaude/docs/readme/
```

## 例外

以下のファイルは翻訳対象外:

- `docs/reviews/` - 内部レビュー記録
- `templates/` - ユーザープロジェクト向けテンプレート
- `references/` - 技術リファレンス（必要に応じて個別対応）
- `examples/` - サンプルファイル
- `tests/` - テストファイル
