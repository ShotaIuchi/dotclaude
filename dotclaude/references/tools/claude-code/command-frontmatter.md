# Command/Skill Frontmatter Reference

Claude Code のコマンド（`.claude/commands/*.md`）およびスキル（`.claude/skills/*/SKILL.md`）で使用できるYAMLフロントマターのリファレンス。

## 基本構造

```markdown
---
field1: value1
field2: value2
---

# コマンド/スキル本文
```

フロントマターは `---` で囲まれたYAML形式のメタデータ。ファイルの先頭に配置する。

---

## フロントマターフィールド一覧

### 共通フィールド

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | string | 推奨 | コマンド/スキルの説明。Claude が自動起動判断に使用 |
| `argument-hint` | string | 任意 | 入力時に表示される引数のヒント |

### スキル専用フィールド

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | 必須 | スキル名（スラッシュコマンド名になる） |
| `references` | array | 任意 | 参照するリファレンスファイルのパス |
| `external` | array | 任意 | 外部ドキュメントへの参照 |

### 動作制御フィールド

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `disable-model-invocation` | boolean | false | `true` で手動起動のみ（自動起動を無効化） |
| `allowed-tools` | array | all | 許可するツールのリスト |
| `model` | string | inherit | 使用するモデル（`haiku`, `sonnet`, `opus`） |
| `context` | string | - | `fork` でサブエージェントとして実行 |

---

## argument-hint の書き方

### 基本パターン

```yaml
# 単一の引数
argument-hint: "<filename>"

# オプション引数（角括弧）
argument-hint: "[work-id]"

# 複数の選択肢（パイプ区切り）
argument-hint: "github=<n> | jira=<id> | local=<id>"

# 複数の引数
argument-hint: "<agent_name> [param=value...]"

# フラグ付き
argument-hint: "[file_path...] [--all]"
```

### 実例

```yaml
---
description: Create a new workspace
argument-hint: "github=<n> | jira=<id> | local=<id>"
---
```

入力時の表示:
```
/wf0-workspace github=<n> | jira=<id> | local=<id>
```

---

## description の活用

`description` は Claude がコマンドを自動起動するかどうかの判断に使用される。

```yaml
---
description: Review document files and output issues
---
```

ユーザーが「ドキュメントをレビューして」と言った場合、この description を見て `/doc-review` が適切かを判断する。

**ベストプラクティス:**
- 英語で記述（Claudeの理解精度向上）
- 動詞から始める（"Create...", "Review...", "Execute..."）
- 簡潔に（1文で完結）

---

## 高度な設定

### 手動起動のみに制限

```yaml
---
description: Dangerous operation - manual only
disable-model-invocation: true
---
```

### 使用ツールの制限

```yaml
---
description: Read-only analysis
allowed-tools:
  - Read
  - Glob
  - Grep
---
```

### 軽量モデルで実行

```yaml
---
description: Quick question answering
model: haiku
---
```

### サブエージェントとして実行

```yaml
---
description: Background analysis task
context: fork
---
```

---

## コマンドとスキルの違い

| 項目 | Commands | Skills |
|------|----------|--------|
| パス | `.claude/commands/*.md` | `.claude/skills/*/SKILL.md` |
| フォーマット | フラット | ディレクトリ構造 |
| `name` フィールド | 不要（ファイル名が名前） | 必須 |
| `references` | 使用可能 | 使用可能 |
| 用途 | ワークフローコマンド | ドメイン知識の提供 |

両者は統合されており、同じフロントマターフィールドが使用可能。

---

## 参考リンク

- [Claude Code Skills Documentation](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Claude Code Sub-agents Documentation](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
