# コマンドガイド

## 概要

Claude Code のコマンド（`.claude/commands/*.md`）の書き方ガイド。

コマンドは `/command-name` で手動実行するワークフロー定義。スキルと統合されており、同じフロントマターが使用可能。

---

## ファイル配置

```
.claude/commands/
├── my-command.md       # /my-command として呼び出し可能
├── wf1-kickoff.md    # /wf1-kickoff
└── subask.md           # /subask
```

**配置場所:**

| 場所 | スコープ |
|------|---------|
| `.claude/commands/` | プロジェクト固有 |
| `~/.claude/commands/` | 全プロジェクト共通 |

**命名規則:**
- ファイル名がコマンド名になる
- 小文字・ハイフン推奨
- `.md` 拡張子必須

---

## 基本構造

```markdown
---
description: コマンドの説明
argument-hint: "[arg1] [arg2]"
---

# /command-name

コマンドの概要説明。

## Usage

/command-name <required> [optional]

## Arguments

- `required`: 必須引数の説明
- `optional`: オプション引数の説明

## Processing

### 1. 入力検証
入力の検証処理

### 2. メイン処理
実際の処理内容

## Examples

/command-name value1
/command-name value1 value2
```

---

## $ARGUMENTS の使い方

`/command-name arg1 arg2` の `arg1 arg2` 部分が `$ARGUMENTS` に入る。

### 明示的に使用

```markdown
---
name: fix-issue
---

Fix GitHub issue $ARGUMENTS following our standards:

1. Read the issue
2. Implement the fix
```

呼び出し: `/fix-issue 123`
Claude が受け取る: 「Fix GitHub issue 123 following...」

### 暗黙的に追加

`$ARGUMENTS` を本文に含めない場合、末尾に自動追加。

---

## 動的コンテキスト注入

シェルコマンドの実行結果をコマンド本文に注入可能。

### 記法

バッククォート内に `!` プレフィックスを付けたコマンドを記述：

```
`!command`
```

### 使用例

```markdown
---
name: pr-summary
---

## Context

- PR diff: `!gh pr diff`
- Changed files: `!gh pr diff --name-only`

## Task

Summarize this PR...
```

**重要:** コマンドは Claude が受け取る**前**に実行される（プリプロセッシング）。

---

## コマンド vs スキル

| 項目 | Commands | Skills |
|------|----------|--------|
| パス | `.claude/commands/*.md` | `.claude/skills/*/SKILL.md` |
| 構造 | 単一ファイル | ディレクトリ |
| サポートファイル | 不可 | 可 |
| 主な用途 | ワークフロー実行 | 知識提供 |
| 自動起動 | 可（description必要） | 可 |

**選択基準:**
- 手順を実行する: **Commands**
- 知識を提供する: **Skills**
- 複数ファイルが必要: **Skills**

---

## エラーハンドリング

```markdown
## Error Handling

### When Agent Not Found

Error: Agent '<name>' not found

Available agents:
- workflow: research, spec-writer
- task: reviewer, test-writer

### Recovery Patterns

Operation failed: <reason>

Suggested actions:
1. Check prerequisites
2. Verify input
3. Retry with: /cmd --verbose
```

---

## 完了メッセージ

```markdown
### Completion Message

Workspace created

Work ID: FEAT-123-add-feature
Branch: feature/123-add-feature
Docs: docs/wf/FEAT-123-add-feature/

Next step: Run /wf1-kickoff
```

---

## 実装チェックリスト

- [ ] フロントマターに `description` を記載
- [ ] `argument-hint` で引数ヒントを提供
- [ ] Usage セクションで使用例を明示
- [ ] Arguments セクションで引数を説明
- [ ] Processing セクションで処理を明確に
- [ ] エラーケースを考慮
- [ ] `/command-name` で動作テスト済み

---

## 参考

- [command-frontmatter.md](command-frontmatter.md) - フロントマター詳細
- [skills-guide.md](skills-guide.md) - スキルの書き方
- [best-practices.md](best-practices.md) - ベストプラクティス
