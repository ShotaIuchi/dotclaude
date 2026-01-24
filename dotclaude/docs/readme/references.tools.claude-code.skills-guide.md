# スキルガイド

## 概要

Claude Code のスキル（`.claude/skills/*/SKILL.md`）の書き方ガイド。

スキルは Claude に特定の知識やタスク実行方法を教える構造化ドキュメント。ユーザーが `/skill-name` で呼び出すか、Claude が自動的に適用する。

---

## ディレクトリ構造

```
.claude/skills/
└── skill-name/
    ├── SKILL.md           # 必須: メイン定義
    ├── reference.md       # 任意: 詳細リファレンス
    ├── examples/          # 任意: 使用例
    └── scripts/           # 任意: 実行スクリプト
```

**配置場所と優先度:**

| 場所 | スコープ | 優先度 |
|------|---------|--------|
| `.claude/skills/` | プロジェクト固有 | 高 |
| `~/.claude/skills/` | 全プロジェクト共通 | 低 |

---

## SKILL.md の基本構造

```markdown
---
name: skill-name
description: When and why Claude should use this skill
references:
  - path: ../../references/some-file.md
external:
  - id: external-doc-id
---

# Skill Title

## Purpose
このスキルが提供する価値

## Key Principles
従うべき原則

## Implementation Patterns
具体的な実装パターン

## Examples
使用例

## Detailed References
- [Reference File](reference.md)
```

---

## フロントマターフィールド

### 必須フィールド

| フィールド | 説明 |
|------------|------|
| `name` | スキル名。小文字・ハイフン・数字のみ（最大64文字） |

### 推奨フィールド

| フィールド | 説明 |
|------------|------|
| `description` | スキルの説明。Claude が自動起動を判断する際に使用 |
| `references` | 参照するプロジェクト内ファイル |
| `external` | 外部ドキュメントへの参照 |

### 動作制御フィールド

| フィールド | デフォルト | 説明 |
|------------|----------|------|
| `disable-model-invocation` | false | `true` で手動起動のみ |
| `user-invocable` | true | `false` で `/` メニューから非表示 |
| `allowed-tools` | all | 使用可能ツールを制限 |
| `model` | inherit | 使用モデル: `haiku`, `sonnet`, `opus` |
| `context` | - | `fork` でサブエージェント実行 |

---

## description の書き方

Claude が「いつこのスキルを使うか」を判断するための重要なフィールド。

```yaml
# BAD: 曖昧
description: Code review

# GOOD: 具体的
description: This skill should be used when implementing Android features,
  creating ViewModels, setting up Repositories, using Hilt, or following
  MVVM/UDF patterns on Android.
```

---

## references の使い方

プロジェクト内のファイルを参照：

```yaml
references:
  - path: ../../references/common/clean-architecture.md
  - path: ../../references/platforms/android/architecture.md
```

**パス規則:**
- SKILL.md からの相対パス
- `../` で親ディレクトリを辿る

---

## サブエージェント実行

`context: fork` で独立したコンテキストで実行：

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:

1. Find relevant files
2. Read and analyze
3. Summarize findings
```

**エージェント型:**

| Agent | 用途 |
|-------|------|
| `Explore` | コードベース探索・調査（読み取り中心） |
| `Plan` | 設計・計画（分析と構造化） |
| `general-purpose` | 汎用タスク（デフォルト） |

---

## 呼び出し制御

| 設定 | ユーザー | Claude | 用途 |
|------|---------|--------|------|
| デフォルト | `/skill` で呼び出し可 | 自動起動可 | 通常のスキル |
| `disable-model-invocation: true` | 可 | 不可 | 危険な操作 |
| `user-invocable: false` | 不可 | 可 | 内部用スキル |

---

## ツール制限

読み取り専用スキル：

```yaml
---
name: code-analyzer
description: Analyze code without making changes
allowed-tools:
  - Read
  - Grep
  - Glob
---
```

---

## 実装チェックリスト

- [ ] `name` は小文字・ハイフンのみ
- [ ] `description` は具体的で明確
- [ ] 本文は500行以下
- [ ] 詳細は参照ファイルに分離
- [ ] references のパスが正しい
- [ ] `/skill-name` で呼び出しテスト済み
- [ ] skills/README.md を更新

---

## 参考

- [command-frontmatter.md](command-frontmatter.md) - フロントマター詳細
- [commands-guide.md](commands-guide.md) - コマンドの書き方
- [best-practices.md](best-practices.md) - ベストプラクティス
