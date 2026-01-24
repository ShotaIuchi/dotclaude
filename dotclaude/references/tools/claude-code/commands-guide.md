# Commands Guide

Claude Code のコマンド（`.claude/commands/*.md`）の書き方ガイド。

## コマンドとは

コマンドは `/command-name` で手動実行するワークフロー定義。
スキルと統合されており、同じフロントマターが使用可能。

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

> **参照:** フロントマターの全フィールドについては [command-frontmatter.md](command-frontmatter.md) を参照。

```markdown
---
description: コマンドの説明
argument-hint: "[arg1] [arg2]"
---

# /command-name

コマンドの概要説明。

## Usage

```
/command-name <required> [optional]
```

## Arguments

- `required`: 必須引数の説明
- `optional`: オプション引数の説明（省略時のデフォルト）

## Processing

### 1. 入力検証
入力の検証処理

### 2. メイン処理
実際の処理内容

### 3. 出力
結果の出力形式

## Examples

```
/command-name value1
/command-name value1 value2
```

## Notes

- 注意事項
- エラーケース
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
→ Claude が受け取る: 「Fix GitHub issue 123 following...」

### 暗黙的に追加

`$ARGUMENTS` を本文に含めない場合、末尾に自動追加：

```markdown
---
name: analyze
---

Analyze the provided code for issues.
```

呼び出し: `/analyze src/main.ts`
→ Claude が受け取る: 「Analyze the provided code for issues. ARGUMENTS: src/main.ts」

### 引数のパース

複雑な引数は Processing セクションで説明：

```markdown
## Processing

Parse $ARGUMENTS to extract:
- First word: action (create|update|delete)
- Remaining: target path

Example: `/cmd create src/file.ts`
→ action = "create", target = "src/file.ts"
```

---

## オプションの処理

```markdown
## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dry-run` | 実行せずに確認のみ | off |
| `--force` | 確認なしで実行 | off |

## Processing

### Option Handling

```
if --dry-run in $ARGUMENTS:
  Show what would be done without executing

if --force in $ARGUMENTS:
  Skip confirmation prompts
```
```

---

## サブコマンド

```markdown
## Usage

```
/wf1-kickoff [subcommand] [options]
```

## Subcommands

- `(none)`: 新規作成（インタラクティブ）
- `update`: 既存を更新
- `revise "<instruction>"`: 指示に基づいて修正
- `chat`: ブレインストーミングモード

## Processing

### Subcommand Routing

```
if subcommand == "update":
  → Update existing document
elif subcommand starts with "revise":
  → Parse instruction and apply revision
elif subcommand == "chat":
  → Enter dialogue mode
else:
  → Create new document
```
```

---

## Processing セクションの書き方

Claude が実行する処理を明確に記述：

### 疑似コードスタイル

```markdown
### 1. 入力検証

```
if $ARGUMENTS is empty:
  Display: "Usage: /cmd <arg>"
  Exit
```

### 2. 処理実行

```
work_id = read from .wf/state.json
if work_id is empty:
  Error: "No active work"
```
```

### Bash コマンド例示

```markdown
### 1. 前提条件の確認

```bash
command -v jq >/dev/null || echo "ERROR: jq is required"
```

### 2. 情報取得

```bash
gh issue view $issue_number --json number,title,body
```
```

### 説明文スタイル

```markdown
### 1. 入力検証

$ARGUMENTS が空の場合、使用方法を表示して終了。

### 2. 状態確認

`.wf/state.json` から `active_work` を読み取る。
設定されていない場合はエラー。
```

---

## 動的コンテキスト注入

シェルコマンドの実行結果をコマンド本文に注入できる。

### 記法

バッククォート内に `!` プレフィックスを付けたコマンドを記述する：

```
`!command`
```

構造の分解：
- `` ` `` - 開始バッククォート
- `!` - 動的実行を示すプレフィックス
- `command` - 実行されるシェルコマンド
- `` ` `` - 終了バッククォート

### 例

**ファイルの内容（commands/pr-summary.md）:**

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

**Claude が受け取る内容（実行後）:**

```markdown
## Context

- PR diff:
  diff --git a/src/main.ts b/src/main.ts
  + added line
  - removed line

- Changed files:
  src/main.ts
  src/utils.ts

## Task

Summarize this PR...
```

### 動作タイミング

**重要:** コマンドは Claude が受け取る**前**に実行される（プリプロセッシング）。
つまり、`/pr-summary` を実行した時点でシェルコマンドが実行され、その結果が埋め込まれた状態で Claude に渡される。

---

## コマンド vs スキル

| 項目 | Commands | Skills |
|------|----------|--------|
| パス | `.claude/commands/*.md` | `.claude/skills/*/SKILL.md` |
| 構造 | 単一ファイル | ディレクトリ |
| `name` フィールド | 省略可（指定しても無視される。ファイル名が常にコマンド名として使用される） | 必須 |
| サポートファイル | 不可 | 可（同ディレクトリ内に補助的なMarkdownファイルや設定ファイルを配置可能） |
| 主な用途 | ワークフロー実行 | 知識提供 |
| 自動起動 | 可（description必要） | 可 |

**選択基準:**
- 手順を実行する → **Commands**
- 知識を提供する → **Skills**
- 複数ファイルが必要 → **Skills**

---

## エラーハンドリング

```markdown
## Error Handling

### When Agent Not Found

```
Error: Agent '<name>' not found

Available agents:
- workflow: research, spec-writer
- task: reviewer, test-writer
```

### When Required Parameters Missing

```
Error: Required parameters missing

Usage: /cmd <param>=<value>

Example: /cmd issue=123
```

### Recovery Patterns

エラー発生時は、ユーザーに次のアクションを提示する：

```markdown
### On Failure

```
❌ Operation failed: <reason>

Suggested actions:
1. Check prerequisites: <specific check>
2. Verify input: <expected format>
3. Retry with: /cmd --verbose

For help: /cmd --help
```
```
```

---

## 完了メッセージ

```markdown
### Completion Message

```
✅ Workspace created

Work ID: FEAT-123-add-feature
Branch: feature/123-add-feature
Docs: docs/wf/FEAT-123-add-feature/

Next step: Run /wf1-kickoff
```
```

---

## 実装チェックリスト

- [ ] フロントマターに `description` を記載
- [ ] `argument-hint` で引数ヒントを提供
- [ ] Usage セクションで使用例を明示
- [ ] Arguments セクションで引数を説明
- [ ] Processing セクションで処理を明確に
- [ ] Examples セクションで具体例を提示
- [ ] エラーケースを考慮
- [ ] `/command-name` で動作テスト済み

---

## 参考

- [command-frontmatter.md](command-frontmatter.md) - フロントマター詳細
- [skills-guide.md](skills-guide.md) - スキルの書き方
- [best-practices.md](best-practices.md) - ベストプラクティス
