# サブエージェント体系

WF運用システムで使用するサブエージェントの定義と使用方法。

## 概要

サブエージェントは Claude Code の Task ツールを活用した専門特化型のエージェントです。
各エージェントは特定のタスクに最適化されており、ワークフローコマンドから呼び出すか、
`/agent` コマンドで直接実行できます。

## エージェント分類

### ワークフロー支援型（workflow/）

ワークフローコマンドと連携して動作するエージェント。

| エージェント | 用途 | 呼び出し元 |
|-------------|------|-----------|
| `research` | Issue 背景調査、関連コード特定 | wf1-kickoff |
| `spec-writer` | 仕様書ドラフト作成 | wf2-spec |
| `planner` | 実装計画立案 | wf3-plan |
| `implementer` | 1ステップ実装支援 | wf5-implement |

### タスク特化型（task/）

単独で実行可能な汎用タスクエージェント。

| エージェント | 用途 |
|-------------|------|
| `reviewer` | コードレビュー |
| `test-writer` | テスト作成 |
| `refactor` | リファクタリング提案 |
| `doc-writer` | ドキュメント作成 |

### プロジェクト分析型（analysis/）

コードベースの調査・分析を行うエージェント。

| エージェント | 用途 |
|-------------|------|
| `codebase` | コードベース調査 |
| `dependency` | 依存関係分析 |
| `impact` | 影響範囲特定 |

## 使用方法

### ワークフローコマンド経由

ワークフローコマンドが自動的に適切なエージェントを呼び出します。

```
/wf1-kickoff
→ research エージェントが Issue 背景を調査

/wf2-spec
→ spec-writer エージェントが仕様書ドラフトを作成
```

### 直接呼び出し

`/agent` コマンドで任意のエージェントを直接実行できます。

```
/agent research issue=123
/agent codebase query="認証フローの実装箇所"
/agent reviewer files="src/auth/*.ts"
```

## エージェント定義形式

各エージェントは以下の形式で定義されています。

```markdown
# Agent: {名前}

## Metadata
- **ID**: {識別子}
- **Base Type**: {explore | plan | bash | general}
- **Category**: {workflow | task | analysis}

## Purpose
{目的}

## Context
{必要な state.json / ドキュメント}

## Capabilities
{できること}

## Constraints
{制約}

## Instructions
{実行手順}

## Output Format
{出力形式}
```

## state.json との連携

エージェントの実行状態は state.json に記録されます。

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

## ディレクトリ構成

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
│   ├── test-writer.md
│   ├── refactor.md
│   └── doc-writer.md
└── analysis/
    ├── codebase.md
    ├── dependency.md
    └── impact.md
```
