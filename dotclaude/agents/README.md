# サブエージェントシステム

WF管理システムで使用されるサブエージェントの定義と使用方法。

## 概要

サブエージェントは、Claude CodeのTaskツールを活用した専門エージェントです。
各エージェントは特定のタスクに最適化されており、ワークフローコマンドから呼び出されるか、
`/agent`コマンドで直接実行できます。

## エージェント分類

### ワークフロー支援型 (workflow/)

ワークフローコマンドと連携して動作するエージェント。

| エージェント | 目的 | 呼び出し元 |
|-------------|------|-----------|
| [`research`](workflow/research.md) | Issue背景調査、関連コード特定 | wf2-kickoff |
| [`spec-writer`](workflow/spec-writer.md) | 仕様書ドラフト作成 | wf3-spec |
| [`planner`](workflow/planner.md) | 実装計画立案 | wf4-plan |
| [`implementer`](workflow/implementer.md) | 単一ステップ実装支援 | wf6-implement |

### タスク特化型 (task/)

単独で実行可能な汎用タスクエージェント。

| エージェント | 目的 |
|-------------|------|
| [`reviewer`](task/reviewer.md) | コードレビュー |
| [`doc-reviewer`](task/doc-reviewer.md) | ドキュメントレビュー（単一ファイル） |
| [`doc-fixer`](task/doc-fixer.md) | レビューファイルからの修正適用 |
| [`test-writer`](task/test-writer.md) | テスト作成 |
| [`refactor`](task/refactor.md) | リファクタリング提案 |
| [`doc-writer`](task/doc-writer.md) | ドキュメント作成 |

### プロジェクト分析型 (analysis/)

コードベースの調査・分析を行うエージェント。

| エージェント | 目的 |
|-------------|------|
| [`codebase`](analysis/codebase.md) | コードベース調査 |
| [`dependency`](analysis/dependency.md) | 依存関係分析 |
| [`impact`](analysis/impact.md) | 影響範囲特定 |

## 使用方法

### ワークフローコマンド経由

ワークフローコマンドは適切なエージェントを自動的に呼び出します。

```
/wf2-kickoff
→ researchエージェントがIssue背景を調査

/wf3-spec
→ spec-writerエージェントが仕様書ドラフトを作成
```

### 直接呼び出し

`/agent`コマンドで任意のエージェントを直接実行できます。

```
/agent research issue=123
/agent codebase query="認証フローの実装箇所"
/agent reviewer files="src/auth/*.ts"
```

#### コマンド引数

| 引数 | 型 | 必須 | デフォルト | 説明 |
|------|-----|------|----------|------|
| `agent_name` | string | はい | - | 実行するエージェント名（例: `research`, `codebase`） |
| `<param>=<value>` | 様々 | いいえ | - | key=value形式でエージェント固有のパラメータを渡す |

エージェントタイプ別の一般的なパラメータ:
- **workflowエージェント**: `issue`, `work_id`, `phase`
- **taskエージェント**: `files`, `target`, `scope`
- **analysisエージェント**: `query`, `path`, `depth`

完全なパラメータ仕様は各エージェントのドキュメントを参照してください。

## 並列実行

**独立したagentは並列実行する。** 詳細は [`rules/parallel-execution.md`](../rules/parallel-execution.md) を参照。

### 並列実行可否

| カテゴリ | 並列実行 | 理由 |
|----------|----------|------|
| analysis/* | ✅ 可能 | 読み取り専用、副作用なし |
| task/reviewer | ✅ 可能 | 読み取り専用 |
| task/doc-reviewer | ✅ 可能 | 読み取り専用 |
| workflow/* | ⚠️ 注意 | state.json更新の競合に注意 |
| task/doc-fixer | ❌ 順次 | ファイル編集の競合回避 |

### 例: 並列レビュー

```
# 3つのagentを同時起動
/agent reviewer files="src/auth/*.kt"
/agent impact path="src/auth"
/agent codebase query="認証の既存実装"
```

## エージェント定義フォーマット

各エージェントは以下の形式で定義されます。

```markdown
# Agent: {name}

## Metadata
- **ID**: {identifier}
- **Base Type**: {explore | plan | bash | general}
- **Category**: {workflow | task | analysis}

## Purpose
{目的}

## Context
{必要なstate.json / ドキュメント}

## Capabilities
{できること}

## Constraints
{制約}

## Instructions
{実行手順}

## Output Format
{出力形式}
```

## state.jsonとの連携

エージェントの実行状態はstate.jsonに記録されます。完全なスキーマ定義は[state.jsonスキーマ](../rules/state.schema.md)を参照。

```json
{
  "works": {
    "<work-id>": {
      "agents": {
        "last_used": "research",
        "sessions": {
          "research": {
            "status": "completed",
            "last_run": "2026-01-17T10:30:00+09:00"
          }
        }
      }
    }
  }
}
```

## ディレクトリ構造

> **注意**: この構造は手動で管理されています。検証するには、プロジェクトルートから`ls -R agents/`を実行してください。

```
agents/
├── README.md           # このファイル
├── _base/
│   ├── context.md      # 共通コンテキスト
│   └── constraints.md  # 共通制約
├── workflow/
│   ├── research.md
│   ├── spec-writer.md
│   ├── planner.md
│   └── implementer.md
├── task/
│   ├── reviewer.md
│   ├── doc-reviewer.md
│   ├── doc-fixer.md
│   ├── test-writer.md
│   ├── refactor.md
│   └── doc-writer.md
└── analysis/
    ├── codebase.md
    ├── dependency.md
    └── impact.md
```
