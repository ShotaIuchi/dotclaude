# /wf2-spec

仕様書（Spec）ドキュメントを作成するコマンド。

## 使用方法

```
/wf2-spec [subcommand]
```

## サブコマンド

- `(なし)`: 新規作成
- `update`: 既存Specを更新
- `validate`: Kickoffとの整合性チェック

## 処理

1. 前提条件チェック（Kickoffが存在するか確認）
2. Kickoffの読み込みと分析
3. コードベース調査
4. Spec作成
5. 整合性チェック
6. `state.json`更新（current: wf2-spec, next: wf3-plan）
7. コミット

## 完了メッセージ

```
✅ Spec document created

File: docs/wf/<work-id>/01_SPEC.md

Affected Components:
- <component1> (high)
- <component2> (medium)

Next step: Run /wf3-plan to create the implementation plan
```

## 注意事項

- Kickoff内容を勝手に変更しない
- 既存仕様との矛盾があれば警告
- 技術的に実現不可能な場合はKickoff修正を提案
