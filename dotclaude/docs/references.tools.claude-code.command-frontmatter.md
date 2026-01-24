# コマンド/スキル フロントマターリファレンス

## 概要

Claude Code のコマンド（`.claude/commands/*.md`）およびスキル（`.claude/skills/*/SKILL.md`）で使用できる YAML フロントマターのリファレンス。

---

## 基本構造

```markdown
---
field1: value1
field2: value2
---

# コマンド/スキル本文
```

フロントマターは `---` で囲まれた YAML 形式のメタデータ。ファイルの先頭に配置。

---

## フロントマターフィールド一覧

### 共通フィールド

| フィールド | 型 | 必須 | 説明 |
|------------|------|------|------|
| `description` | string | 推奨 | コマンド/スキルの説明。Claude が自動起動判断に使用 |
| `argument-hint` | string | 任意 | 入力時に表示される引数のヒント |

### スキル専用フィールド

| フィールド | 型 | 必須 | 説明 |
|------------|------|------|------|
| `name` | string | 必須 | スキル名（スラッシュコマンド名になる） |
| `references` | array | 任意 | 参照するリファレンスファイルのパス |
| `external` | array | 任意 | 外部ドキュメントへの参照 |

### 動作制御フィールド

| フィールド | 型 | デフォルト | 説明 |
|------------|------|----------|------|
| `disable-model-invocation` | boolean | false | `true` で手動起動のみ |
| `allowed-tools` | array | all | 許可するツールのリスト |
| `model` | string | inherit | 使用モデル（`haiku`, `sonnet`, `opus`） |
| `context` | string | - | `fork` でサブエージェント実行 |

---

## allowed-tools で使用可能なツール名

| ツール名 | 説明 |
|----------|------|
| `Read` | ファイル読み取り |
| `Write` | ファイル書き込み |
| `Edit` | ファイル編集（部分置換） |
| `Glob` | ファイルパターン検索 |
| `Grep` | ファイル内容検索 |
| `Bash` | シェルコマンド実行 |
| `WebFetch` | Web コンテンツ取得 |
| `WebSearch` | Web 検索 |
| `Task` | サブタスク実行 |
| `NotebookEdit` | Jupyter Notebook 編集 |

---

## argument-hint の書き方

```yaml
# 単一の引数
argument-hint: "<filename>"

# オプション引数（角括弧）
argument-hint: "[work-id]"

# 複数の選択肢（パイプ区切り）
argument-hint: "github=<n> | jira=<id> | local=<id>"

# フラグ付き
argument-hint: "[file_path...] [--all]"
```

---

## 使用例

### 読み取り専用の軽量サブエージェント

```yaml
---
description: Quick code analysis
model: haiku
context: fork
allowed-tools:
  - Read
  - Glob
  - Grep
---
```

### セキュリティ重視のレビュータスク

```yaml
---
description: Security-focused code review
model: opus
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---
```

---

## コマンドとスキルの違い

| 項目 | Commands | Skills |
|------|----------|--------|
| パス | `.claude/commands/*.md` | `.claude/skills/*/SKILL.md` |
| フォーマット | フラット | ディレクトリ構造 |
| `name` フィールド | 不要（ファイル名が名前） | 必須 |
| 用途 | ワークフローコマンド | ドメイン知識の提供 |

---

## トラブルシューティング

| 問題 | 原因 | 対処法 |
|------|------|--------|
| フロントマターが認識されない | `---` が正しく閉じられていない | 開始と終了の `---` を確認 |
| コマンドが自動起動しない | `disable-model-invocation: true` が設定 | 設定を削除 |
| ツールが使えない | `allowed-tools` でブロック | 必要なツールを追加 |
| YAML パースエラー | インデント不正、特殊文字 | 構文を確認、引用符で囲む |

---

## 参考リンク

- [Claude Code Skills Documentation](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Claude Code Sub-agents Documentation](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
