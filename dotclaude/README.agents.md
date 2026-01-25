# agents/

サブエージェント定義ディレクトリ。

## 概要

Claude CodeのTaskツールを活用した専門エージェントを定義。
各エージェントは特定のタスクに最適化されており、ワークフローコマンドから呼び出されるか、`/agent`コマンドで直接実行可能。

## 構造

```
agents/
├── README.md           # 詳細ドキュメント
├── _base/              # 共通定義
│   ├── context.md      # 共通コンテキスト
│   └── constraints.md  # 共通制約
├── workflow/           # ワークフロー支援型
│   ├── research.md     # Issue背景調査
│   ├── spec-writer.md  # 仕様書ドラフト作成
│   ├── planner.md      # 実装計画立案
│   └── implementer.md  # 単一ステップ実装
├── task/               # タスク特化型
│   ├── reviewer.md     # コードレビュー
│   ├── doc-reviewer.md # ドキュメントレビュー
│   ├── doc-fixer.md    # レビュー修正適用
│   ├── doc-writer.md   # ドキュメント作成
│   ├── test-writer.md  # テスト作成
│   └── refactor.md     # リファクタリング
└── analysis/           # 分析型
    ├── codebase.md     # コードベース調査
    ├── dependency.md   # 依存関係分析
    └── impact.md       # 影響範囲特定
```

## 使用方法

```bash
# ワークフローコマンド経由（自動呼び出し）
/wf1-kickoff  # → researchエージェント

# 直接呼び出し
/agent research issue=123
/agent reviewer files="src/*.ts"
```

## 関連

- 詳細: [`agents/README.md`](agents/README.md)
- 並列実行ルール: [`rules/parallel-execution.md`](rules/parallel-execution.md)
