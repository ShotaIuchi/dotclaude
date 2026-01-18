# /agent

サブエージェントを直接呼び出すコマンド。

## 使用方法

```
/agent <エージェント名> [パラメータ...]
```

## エージェント一覧

### ワークフロー支援型

| エージェント | 用途 |
|-------------|------|
| `research` | Issue 背景調査、関連コード特定 |
| `spec-writer` | 仕様書ドラフト作成 |
| `planner` | 実装計画立案 |
| `implementer` | 1ステップ実装支援 |

### タスク特化型

| エージェント | 用途 |
|-------------|------|
| `reviewer` | コードレビュー |
| `test-writer` | テスト作成 |
| `refactor` | リファクタリング提案 |
| `doc-writer` | ドキュメント作成 |

### プロジェクト分析型

| エージェント | 用途 |
|-------------|------|
| `codebase` | コードベース調査 |
| `dependency` | 依存関係分析 |
| `impact` | 影響範囲特定 |

## 使用例

```bash
# Issue 背景調査
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

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. エージェント名とパラメータの解析

```bash
# $ARGUMENTS から最初の単語をエージェント名として取得
agent_name=$(echo "$ARGUMENTS" | awk '{print $1}')
params=$(echo "$ARGUMENTS" | cut -d' ' -f2-)
```

### 2. エージェント定義の読み込み

エージェント定義ファイルの場所:

```
~/.claude/agents/workflow/<agent_name>.md
~/.claude/agents/task/<agent_name>.md
~/.claude/agents/analysis/<agent_name>.md
```

上記いずれかから該当するエージェント定義を読み込みます。

### 3. コンテキストの準備

以下のファイルを読み込んでコンテキストを構築:

1. `~/.claude/agents/_base/context.md` - 共通コンテキスト
2. `~/.claude/agents/_base/constraints.md` - 共通制約
3. エージェント定義ファイル

### 4. 現在の作業状態を確認（オプション）

アクティブな作業がある場合は、その情報も渡します:

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json 2>/dev/null)
if [ -n "$work_id" ]; then
  docs_dir="docs/wf/$work_id"
  # 関連ドキュメントも読み込み可能
fi
```

### 5. サブエージェントの実行

Claude Code の Task ツールを使用してサブエージェントを起動します。

エージェントの Base Type に応じて適切な subagent_type を選択:

| Base Type | subagent_type |
|-----------|---------------|
| explore | Explore |
| plan | Plan |
| bash | Bash |
| general | general-purpose |

### 6. 実行結果の記録

アクティブな作業がある場合、state.json に実行記録を追加:

```bash
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S+09:00")
jq ".works[\"$work_id\"].agents.last_used = \"$agent_name\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].agents.sessions[\"$agent_name\"] = {\"status\": \"completed\", \"last_run\": \"$timestamp\"}" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 7. 結果の表示

エージェントの実行結果を整形して表示します。

## パラメータ形式

パラメータは `key=value` 形式で指定します。

```
/agent research issue=123
/agent codebase query="検索クエリ"
/agent reviewer files="src/**/*.ts" focus="security"
```

## エラー処理

### エージェントが見つからない場合

```
エラー: エージェント '<agent_name>' が見つかりません

利用可能なエージェント:
- workflow: research, spec-writer, planner, implementer
- task: reviewer, test-writer, refactor, doc-writer
- analysis: codebase, dependency, impact
```

### 必須パラメータが不足している場合

```
エラー: 必須パラメータが不足しています

使用法: /agent <agent_name> <param>=<value>

例: /agent research issue=123
```

## 注意事項

- ワークフロー支援型エージェントは対応するワークフローコマンドから使用することを推奨
- 分析型エージェントは読み取り専用で動作
- 実行結果は state.json に記録される（アクティブな作業がある場合）
