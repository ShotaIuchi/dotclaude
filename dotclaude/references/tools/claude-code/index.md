# Claude Code Reference

Claude Code のスキル・コマンド作成に関するリファレンス。

---

## ガイド一覧

| File | Description |
|------|-------------|
| [skills-guide.md](skills-guide.md) | スキルの書き方ガイド |
| [commands-guide.md](commands-guide.md) | コマンドの書き方ガイド |
| [command-frontmatter.md](command-frontmatter.md) | フロントマター仕様リファレンス |
| [best-practices.md](best-practices.md) | ベストプラクティス |

---

## クイックリファレンス

### スキル vs コマンド

| 項目 | Skills | Commands |
|------|--------|----------|
| パス | `.claude/skills/*/SKILL.md` | `.claude/commands/*.md` |
| 構造 | ディレクトリ | 単一ファイル |
| サポートファイル | 可 | 不可 |
| 主な用途 | 知識提供 | ワークフロー実行 |

### フロントマター早見表

```yaml
---
# 共通
description: いつ使うかの説明
argument-hint: "[arg1] [arg2]"

# スキル専用
name: skill-name
references:
  - path: ../../references/file.md
external:
  - id: external-doc-id

# 動作制御
disable-model-invocation: true  # 手動起動のみ
user-invocable: false           # Claudeのみ使用
allowed-tools: [Read, Grep]     # ツール制限
model: haiku                    # モデル指定
context: fork                   # サブエージェント実行
---
```

### $ARGUMENTS の使い方

```markdown
# 明示的に使用
Fix issue $ARGUMENTS

# オプション処理
if --dry-run in $ARGUMENTS:
  Show preview only
```

---

## External Links

| Resource | Description |
|----------|-------------|
| [Claude Code Skills](https://docs.anthropic.com/en/docs/claude-code/skills) | 公式: Skills |
| [Claude Code Sub-agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents) | 公式: Sub-agents |
| [Claude Code Memory](https://docs.anthropic.com/en/docs/claude-code/memory) | 公式: Memory & CLAUDE.md |
| [Agent Skills Standard](https://agentskills.io) | Agent Skills 標準仕様 |
