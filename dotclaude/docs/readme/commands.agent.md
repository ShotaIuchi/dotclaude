# /agent

サブエージェントを直接呼び出すコマンド。

## 使用方法

```
/agent <agent_name> [parameters...]
```

## エージェント一覧

### ワークフロー支援型

| エージェント | 目的 | Base Type |
|-------------|------|-----------|
| `research` | Issue背景調査、関連コード特定 | explore |
| `spec-writer` | 仕様書ドラフト作成 | general |
| `planner` | 実装計画立案 | plan |
| `implementer` | 単一ステップ実装支援 | general |

### タスク特化型

| エージェント | 目的 | Base Type |
|-------------|------|-----------|
| `reviewer` | コードレビュー | general |
| `test-writer` | テスト作成 | general |
| `refactor` | リファクタリング提案 | plan |
| `doc-writer` | ドキュメント作成 | general |

### プロジェクト分析型

| エージェント | 目的 | Base Type |
|-------------|------|-----------|
| `codebase` | コードベース調査 | explore |
| `dependency` | 依存関係分析 | explore |
| `impact` | 影響範囲特定 | explore |

## 使用例

```bash
# Issue背景調査
/agent research issue=123

# コードベース調査
/agent codebase query="認証フローの実装箇所"

# コードレビュー
/agent reviewer files="src/auth/*.ts"

# 依存関係分析
/agent dependency package="lodash"

# 影響範囲特定
/agent impact target="src/utils/format.ts"

# テスト作成
/agent test-writer target="src/services/user.ts"

# ドキュメント作成
/agent doc-writer target="src/api/" type="api"
```

## パラメータ形式

パラメータは`key=value`形式で指定:

```
/agent research issue=123
/agent codebase query="search query"
/agent reviewer files="src/**/*.ts" focus="security"
```

## エラーハンドリング

### エージェントが見つからない場合

```
Error: Agent 'unknown' not found

Available agents:
- workflow: research, spec-writer, planner, implementer
- task: reviewer, test-writer, refactor, doc-writer
- analysis: codebase, dependency, impact
```

### 必須パラメータが不足している場合

```
Error: Required parameters missing

Usage: /agent <agent_name> <param>=<value>

Example: /agent research issue=123
```

## 注意事項

- ワークフロー支援型エージェントは対応するワークフローコマンドからの使用を推奨
- 分析型エージェントは読み取り専用モードで動作
- 実行結果はstate.jsonに記録（アクティブな作業がある場合）
- **エージェント定義ファイルが存在する必要あり**。`/agent list`で利用可能なエージェントを確認
