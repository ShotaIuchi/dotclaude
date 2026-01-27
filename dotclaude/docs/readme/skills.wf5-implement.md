# /wf5-implement

Planの1ステップを実装するコマンド。

## 使用方法

```
/wf5-implement [step_number]
```

## 制約

- **計画外の変更禁止**: Planに記載された内容のみ実装
- **1実行 = 1ステップ**: 1回の実行で1ステップのみ

## 処理

1. 前提条件チェック（`02_PLAN.md`必須）
2. 対象ステップ決定（引数 or current_step + 1）
3. Planからステップ情報抽出
4. 実装（ファイル変更、テスト実行）
5. 実装ログ記録（`04_IMPLEMENT_LOG.md`）
6. state.json更新（ステップ完了、全完了時は next: wf6-verify）
7. 完了条件検証
8. コミット（タイプ自動検出: fix/refactor/test/docs/feat）

## 計画外の変更について

- **軽微**（typo、import追加等）: Notes記録で続行
- **重大**（設計変更等）: 中断し `/wf3-plan update` を提案

## エージェント参照

[implementer エージェント](../../agents/workflow/implementer.md) に委譲。
