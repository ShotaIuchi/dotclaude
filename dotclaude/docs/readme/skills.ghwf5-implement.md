# /ghwf5-implement

Planの全ステップを一括実装するコマンド。

## 使用方法

```
/ghwf5-implement          # 全ステップを一括実装
```

## 前提条件

- `ghwf4-review` 完了済み（Planレビュー）
- `03_PLAN.md` が存在

## 処理

1. コンテキスト読み込み（state.json、03_PLAN.md、Issue/PRコメント）
2. 未完了の最初のステップから順に全ステップを実装
   - ステップごとにコードを実装
   - ステップごとにコミット（pushはしない）
   - コミットタイプは自動検出（fix/refactor/test/docs/feat）
3. 全ステップ完了後、05_IMPLEMENTATION.md を更新
4. 最後にまとめて1回push
5. PRチェックリスト更新、`ghwf:step-5`ラベル追加
6. state.json更新（next: ghwf6-verify）

## エラー時の動作

- ステップ実装に失敗した場合、完了済みステップまでcommit & pushして停止
- 05_IMPLEMENTATION.mdに失敗ステップを記録
- 残りステップは再実行で対応可能
