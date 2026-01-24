# Skills Guide

Claude Code のスキル（`.claude/skills/*/SKILL.md`）の書き方ガイド。

## スキルとは

スキルは Claude に特定の知識やタスク実行方法を教える構造化ドキュメント。
ユーザーが `/skill-name` で呼び出すか、Claude が自動的に適用する。

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

| Field | Description |
|-------|-------------|
| `name` | スキル名。小文字・ハイフン・数字のみ（最大64文字） |

### 推奨フィールド

| Field | Description |
|-------|-------------|
| `description` | スキルの説明。Claude が自動起動を判断する際に使用 |
| `references` | 参照するプロジェクト内ファイル |
| `external` | 外部ドキュメントへの参照 |

### 動作制御フィールド

| Field | Default | Description |
|-------|---------|-------------|
| `disable-model-invocation` | false | `true` で手動起動のみ |
| `user-invocable` | true | `false` で `/` メニューから非表示（Claude のみ使用） |
| `allowed-tools` | all | 使用可能ツールを制限 |
| `model` | inherit | 使用モデル: `haiku`, `sonnet`, `opus`（下記参照） |
| `context` | - | `fork` でサブエージェント実行 |
| `agent` | - | `context: fork` 時のエージェント型 |

**モデル選択ガイダンス:**

| Model | 特徴 | 推奨用途 |
|-------|------|----------|
| `inherit` | 親セッションのモデルを継承（デフォルト） | 通常のスキル |
| `haiku` | 高速・低コスト | シンプルな検索・参照タスク |
| `sonnet` | バランス型 | コード生成・分析 |
| `opus` | 最高性能 | 複雑な推論・設計タスク |

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

**ベストプラクティス:**
- 英語で記述（Claude の理解精度向上）
- 「When to use」を明確に
- 具体的な技術・パターン名を含める

---

## references の使い方

プロジェクト内のファイルを参照する：

```yaml
references:
  - path: ../../references/common/clean-architecture.md
  - path: ../../references/platforms/android/architecture.md
```

**パス規則:**
- SKILL.md からの相対パス
- `../` で親ディレクトリを辿る

**メリット:**
- スキル本文を簡潔に保てる
- 複数スキルで同じリファレンスを共有
- Claude が必要な時だけ読み込む

---

## external の使い方

外部ドキュメントを ID で参照する：

```yaml
external:
  - id: android-arch-guide
  - id: jetpack-compose-docs
```

ID は `~/.claude/references/external-links.yaml` で定義：

```yaml
android-arch-guide:
  url: https://developer.android.com/topic/architecture
  description: Official Android Architecture Guide
```

**external-links.yaml の構造:**

```yaml
# 必須フィールド: url
# 推奨フィールド: description
# 任意フィールド: tags, last-updated

<id>:
  url: <URL>              # 必須: 参照先URL
  description: <text>      # 推奨: 内容の説明（Claudeが参照判断に使用）
  tags:                    # 任意: 分類タグ
    - android
    - architecture
  last-updated: 2026-01-01 # 任意: 最終確認日
```

**完全な例:**

```yaml
# ~/.claude/references/external-links.yaml
android-arch-guide:
  url: https://developer.android.com/topic/architecture
  description: Official Android Architecture Guide covering MVVM, Repository pattern
  tags: [android, architecture]

jetpack-compose-docs:
  url: https://developer.android.com/jetpack/compose
  description: Jetpack Compose official documentation
  tags: [android, ui, compose]

kotlin-coroutines:
  url: https://kotlinlang.org/docs/coroutines-overview.html
  description: Kotlin Coroutines documentation for async programming
  tags: [kotlin, async]
```

---

## サポートファイルの活用

詳細情報は別ファイルに分離：

```
my-skill/
├── SKILL.md              # メイン（500行以下推奨）
├── patterns.md           # 実装パターン詳細
├── examples.md           # 使用例集
└── troubleshooting.md    # トラブルシューティング
```

**SKILL.md から参照:**

```markdown
## Detailed References

- For implementation patterns, see [patterns.md](patterns.md)
- For usage examples, see [examples.md](examples.md)
```

---

## スキルの種類

### 1. Reference Content（知識提供型）

知識やガイドラインを提供：

```yaml
---
name: api-conventions
description: API design patterns and conventions for this codebase
---

# API Conventions

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

### 2. Task Content（タスク実行型）

手順を実行する：

```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true  # 手動起動のみ
---

# Deploy

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to deployment target
4. Verify deployment succeeded
```

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

**$ARGUMENTS 変数:**

`$ARGUMENTS` はスキル呼び出し時にユーザーが渡した引数を含む。

```
# ユーザー入力
/deep-research authentication flow

# $ARGUMENTS の値
"authentication flow"
```

スキル内で `$ARGUMENTS` を使用してタスクをパラメータ化できる。

**エージェント型:**

| Agent | 用途 |
|-------|------|
| `Explore` | コードベース探索・調査（読み取り中心） |
| `Plan` | 設計・計画（分析と構造化） |
| `general-purpose` | 汎用タスク（デフォルト） |

これらは Claude Code で利用可能な標準エージェント型である。カスタムエージェントは `agents/` ディレクトリで定義可能。

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

**利用可能なツール名:**

| Tool | 機能 |
|------|------|
| `Read` | ファイル読み取り |
| `Write` | ファイル書き込み |
| `Edit` | ファイル編集（部分置換） |
| `Glob` | ファイルパターン検索 |
| `Grep` | ファイル内容検索 |
| `Bash` | シェルコマンド実行 |
| `WebFetch` | Web コンテンツ取得 |
| `WebSearch` | Web 検索 |
| `Task` | サブタスク実行 |
| `Skill` | 他スキル呼び出し |
| `NotebookEdit` | Jupyter Notebook 編集 |

**制限の組み合わせ例:**

```yaml
# 読み取り専用（調査向け）
allowed-tools: [Read, Grep, Glob]

# 編集可能（実装向け）
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash]

# Web 調査向け
allowed-tools: [Read, Grep, WebFetch, WebSearch]
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
