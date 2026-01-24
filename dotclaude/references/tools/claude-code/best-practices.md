# Best Practices

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

### 具体的なキーワード

```yaml
# BAD: 曖昧
description: Help with Android

# GOOD: 具体的
description: Use when implementing ViewModels, Repositories, Hilt DI,
  Jetpack Compose, or MVVM/UDF patterns on Android
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

### 基本パターン

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

### 分かりやすさ優先

```yaml
# BAD: 省略しすぎ
argument-hint: "<n>"

# GOOD: 意味が分かる
argument-hint: "<issue-number>"
```

---

## Processing の書き方

### 段階的に記述

```markdown
## Processing

### 1. 前提条件の確認
必要なツールの確認

### 2. 入力の解析
引数のパース

### 3. メイン処理
実際の処理

### 4. 結果の出力
完了メッセージ
```

### 疑似コードは明確に

コードブロック内で疑似コードを記述する場合、言語指定なしのコードブロックを使用：

```markdown
### 1. 入力検証

    if $ARGUMENTS is empty:
      Display: "Usage: /cmd <arg>"
      Exit

    if file does not exist:
      Error: "File not found"
```

> **Note:** インデント（4スペース）を使用することで、ネストされたコードブロックの問題を回避できる。

### Bash 例示は実行可能に

```markdown
### 2. 情報取得

```bash
# Issue 情報を取得
gh issue view "$issue_number" --json number,title,body,labels
```
```

---

## エラーハンドリング

### 明確なエラーメッセージ

```markdown
## Error Handling

### File Not Found

```
Error: File '<path>' not found

Please check:
1. The file path is correct
2. The file exists in the repository
```

### Invalid Arguments

```
Error: Invalid argument format

Expected: /cmd key=value
Got: /cmd invalid

Example: /cmd issue=123
```
```

### 次のアクションを提示

```markdown
### No Active Work

```
Error: No active work found

To fix:
1. Run /wf0-workspace to create a new workspace
   OR
2. Run /wf0-restore to restore an existing workspace
```
```

---

## 完了メッセージ

### 構造化された出力

```markdown
```
✅ Task completed

Summary:
- Created: 3 files
- Modified: 2 files
- Deleted: 0 files

Details:
- src/feature/ViewModel.kt (new)
- src/feature/Repository.kt (new)
- src/feature/UseCase.kt (new)
- build.gradle.kts (modified)
- settings.gradle.kts (modified)

Next step: Run /wf5-implement to implement the next step
```
```

### 次のステップを提示

```markdown
```
✅ Workspace created

Work ID: FEAT-123-add-feature
Branch: feature/123-add-feature

Next steps:
1. Run /wf1-kickoff to create the Kickoff document
2. Review the created workspace structure
```
```

---

## ファイル構成

### スキル: 複数ファイル活用

```
skills/android-architecture/
├── SKILL.md              # メイン（500行以下）
├── viewmodel-patterns.md # ViewModel パターン詳細
├── di-patterns.md        # DI パターン詳細
└── examples/
    ├── simple-feature.md
    └── complex-feature.md
```

### コマンド: シンプルに保つ

```
commands/
├── wf0-workspace.md      # ワークスペース作成
├── wf1-kickoff.md        # キックオフ
└── subask.md             # サブ質問
```

---

## 参照ファイルの活用

### references フィールド

```yaml
references:
  - path: ../../references/common/clean-architecture.md
  - path: ../../references/platforms/android/architecture.md
```

### 本文内リンク

```markdown
## Detailed References

- [Clean Architecture](../../references/common/clean-architecture.md)
- [Android Architecture](../../references/platforms/android/architecture.md)
```

### メリット

1. **本文を簡潔に保てる**
2. **複数スキルで共有可能**
3. **遅延読み込み**（必要な時だけ）

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

### 内部用スキル

ユーザーから隠す：

```yaml
---
name: internal-helper
description: Internal helper for other skills
user-invocable: false
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

## テスト

### 基本動作確認

1. `/skill-name` で直接呼び出し
2. 引数あり・なしで動作確認
3. エラーケースの確認

### 自動起動確認

1. 関連する質問をして自動起動されるか確認
2. 現在のコンテキストでスキルが認識されているか確認

> **Note:** Claude Code のコンテキスト確認方法については、実行環境に応じて異なる場合がある。

### チェックリスト

- [ ] フロントマターの YAML が有効
- [ ] `name` は小文字・ハイフンのみ
- [ ] `description` は明確
- [ ] references のパスが正しい
- [ ] 本文は500行以下
- [ ] `/name` で呼び出し可能
- [ ] エラーケースが適切に処理される
- [ ] README.md を更新

---

## アンチパターン

### 1. 巨大なスキル

```yaml
# BAD: 1000行のSKILL.md
---
name: everything-about-android
---
# 1000行のドキュメント...

# GOOD: 分割
---
name: android-architecture
references:
  - path: ./viewmodel.md
  - path: ./repository.md
---
# 200行の概要
```

### 2. 曖昧な説明

```yaml
# BAD
description: Helps with code

# GOOD
description: Reviews Kotlin code for null safety, coroutine usage,
  and Android lifecycle awareness
```

### 3. $ARGUMENTS の未使用

```markdown
# BAD: 引数を無視
Fix the issue.

# GOOD: 引数を活用
Fix GitHub issue $ARGUMENTS following our standards.
```

### 4. エラーハンドリングなし

```markdown
# BAD: エラーを考慮していない

## Processing
1. Read the file
2. Process it

# GOOD: エラーケースを考慮

## Processing
1. Read the file
   - If not found: Error with helpful message
2. Process it
   - If invalid format: Error with expected format
```

---

## 参考

- [command-frontmatter.md](command-frontmatter.md) - フロントマター詳細
- [skills-guide.md](skills-guide.md) - スキルの書き方
- [commands-guide.md](commands-guide.md) - コマンドの書き方
