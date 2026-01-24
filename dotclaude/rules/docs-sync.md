# Docs Sync Rule

ドキュメントの日本語訳を自動的に維持するためのルール。

## 概要

`dotclaude/`内のドキュメント（`.md`ファイル）を作成・更新した際は、対応する日本語訳ファイルを`docs/`ディレクトリに作成・更新する。

## 対象ファイル

| 元ファイル | 日本語訳ファイル |
|-----------|-----------------|
| `CLAUDE.md` | `docs/CLAUDE.md` |
| `PRINCIPLES.md` | `docs/PRINCIPLES.md` |
| `CONSTITUTION.md` | `docs/CONSTITUTION.md` |
| `commands/{name}.md` | `docs/commands.{name}.md` |
| `rules/{name}.md` | `docs/rules.{name}.md` |
| `agents/{category}/{name}.md` | `docs/agents.{category}.{name}.md` |
| `skills/{name}/SKILL.md` | `docs/skills.{name}.md` |

## 命名規則

- パスの`/`を`.`に置換
- 拡張子は`.md`を維持
- 例: `commands/wf1-workspace.md` → `docs/commands.wf1-workspace.md`

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
2. `docs/`に日本語訳ファイルを作成
3. 両方を同一コミットに含める

### 更新時

1. 元ドキュメントを更新
2. 日本語訳ファイルを同期更新
3. 両方を同一コミットに含める

## 検証

コミット前に以下を確認:

```bash
# 元ファイルと日本語訳の対応を確認
ls dotclaude/docs/
```

## 例外

以下のファイルは翻訳対象外:

- `reviews/` - 内部レビュー記録
- `templates/` - ユーザープロジェクト向けテンプレート
- `references/` - 技術リファレンス（必要に応じて個別対応）
- `examples/` - サンプルファイル
- `tests/` - テストファイル
