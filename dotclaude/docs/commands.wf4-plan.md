# /wf4-plan

実装計画（Plan）ドキュメントを作成するコマンド。

## 使用方法

```
/wf4-plan [subcommand]
```

## サブコマンド

- `(なし)`: 新規作成
- `update`: 既存Planの更新
- `step <n>`: 特定ステップの詳細表示

## 処理内容

1. **前提条件チェック**
   - Specドキュメントの存在確認

2. **Specの読み込みと分析**
   - 影響コンポーネント、詳細変更、テスト戦略を抽出

3. **詳細コードベース調査**
   - 変更対象ファイル、作成ファイル、テストファイルの特定
   - ファイル間の依存関係分析
   - 変更順序の決定
   - リスク評価

4. **ステップ分割**
   - 1ステップ = 1 /wf6-implement実行
   - 依存順序を考慮
   - リスク分散
   - 目安: 50-200行変更、1-5ファイル変更

5. **Planの作成**
   - テンプレートに調査結果を反映
   - 5-10ステップに分割

## stepサブコマンド

特定ステップの詳細表示:

```
📋 Step 1: AuthService実装
═══════════════════════════════════════

Purpose: 認証サービスの基本実装

Target Files:
- src/services/auth.ts
- src/types/auth.ts

Tasks:
1. AuthServiceクラスの作成
2. 認証メソッドの実装

Completion Criteria:
- [ ] ログインAPIが動作する
- [ ] トークン生成が正しく動作する

Estimate: medium
Dependencies: none
```

## 出力例

```
✅ Plan document created

File: docs/wf/FEAT-123-export-csv/02_PLAN.md

Implementation Steps:
1. データモデル作成 (small)
2. サービス実装 (medium)
3. API統合 (small)

Total: 3 steps

Next step:
- If review is needed: /wf5-review
- To start implementation: /wf6-implement
```

## 注意事項

- Spec内容を超える変更をPlanに含めない
- 実装順序は依存関係を厳密に考慮
- 各ステップは独立してテスト可能な単位にする
