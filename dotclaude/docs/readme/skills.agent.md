# /agent

サブエージェントを直接呼び出すコマンド。

## 使用方法

```
/agent <agent_name> [parameters...]
```

## 利用可能なエージェント

### タスク特化型

| エージェント | 目的 |
|-------------|------|
| `reviewer` | コードレビュー |
| `test-writer` | テスト作成 |
| `refactor` | リファクタリング提案 |
| `doc-writer` | ドキュメント作成 |

### プロジェクト分析型

| エージェント | 目的 |
|-------------|------|
| `codebase` | コードベース調査 |
| `dependency` | 依存関係分析 |
| `impact` | 影響範囲特定 |

## 使用例

```bash
# コードベース調査
/agent codebase query="認証フローの実装箇所"

# コードレビュー
/agent reviewer files="src/auth/*.ts"

# 依存関係分析
/agent dependency package="lodash"

# 影響範囲特定
/agent impact target="src/utils/format.ts"
```

## 注意事項

- 分析系エージェントは読み取り専用で動作
- ワークフロー支援エージェント（research, spec-writer, planner, implementer）は skills/ に統合済み
  - `/wf1-kickoff`, `/wf2-spec`, `/wf3-plan`, `/wf5-implement` を使用
