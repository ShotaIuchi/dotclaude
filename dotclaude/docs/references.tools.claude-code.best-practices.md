# ベストプラクティス

## 概要

Claude Code のスキル・コマンド作成のベストプラクティス。

---

## 設計原則

### 1. 単一責任

1つのスキル/コマンドは1つの目的に集中：

```yaml
# BAD: 複数の責務
name: do-everything
description: Deploy, test, and document

# GOOD: 単一責務
name: deploy
description: Deploy application to production
```

### 2. 明確な説明

description は「いつ使うか」を明確に：

```yaml
# BAD
description: Code review

# GOOD
description: Expert code review for quality, security, and maintainability.
  Use after writing or modifying code.
```

### 3. 簡潔な本文

- SKILL.md / コマンド本文は **500行以下**
- 詳細は参照ファイルに分離
- Claude が必要な情報だけを読み込めるように

---

## description の書き方

### 英語で記述

Claude の理解精度が向上：

```yaml
# 推奨
description: This skill should be used when implementing Android features

# 日本語も可（精度がやや下がる可能性）
description: Androidの機能実装時に使用するスキル
```

### 「When to use」を明示

```yaml
description: |
  Use this skill when:
  - Creating new API endpoints
  - Modifying existing API behavior
  - Reviewing API design
```

---

## argument-hint の書き方

```yaml
# 必須引数
argument-hint: "<issue-number>"

# オプション引数
argument-hint: "[work-id]"

# 複数選択肢
argument-hint: "github=<n> | jira=<id> | local=<id>"

# 複合
argument-hint: "<agent_name> [param=value...]"
```

---

## エラーハンドリング

### 明確なエラーメッセージ

```markdown
## Error Handling

### File Not Found

Error: File '<path>' not found

Please check:
1. The file path is correct
2. The file exists in the repository
```

### 次のアクションを提示

```markdown
### No Active Work

Error: No active work found

To fix:
1. Run /wf1-kickoff to create a new workspace
   OR
2. Run /wf0-restore to restore an existing workspace
```

---

## 完了メッセージ

### 構造化された出力

```
Summary:
- Created: 3 files
- Modified: 2 files

Next step: Run /wf5-implement to implement the next step
```

---

## 呼び出し制御

### 自動起動を無効化

危険な操作は手動のみに：

```yaml
---
name: deploy-production
description: Deploy to production environment
disable-model-invocation: true
---
```

### ツール制限

読み取り専用：

```yaml
---
name: code-analyzer
allowed-tools:
  - Read
  - Grep
  - Glob
---
```

---

## アンチパターン

### 1. 巨大なスキル

```yaml
# BAD: 1000行のSKILL.md
---
name: everything-about-android
---

# GOOD: 分割
---
name: android-architecture
references:
  - path: ./viewmodel.md
  - path: ./repository.md
---
```

### 2. $ARGUMENTS の未使用

```markdown
# BAD: 引数を無視
Fix the issue.

# GOOD: 引数を活用
Fix GitHub issue $ARGUMENTS following our standards.
```

---

## 参考

- [command-frontmatter.md](command-frontmatter.md) - フロントマター詳細
- [skills-guide.md](skills-guide.md) - スキルの書き方
- [commands-guide.md](commands-guide.md) - コマンドの書き方
