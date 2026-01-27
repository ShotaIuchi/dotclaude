# /wf2-spec

仕様書（Spec）ドキュメントを作成するコマンド。

## 使用方法

```
/wf2-spec [subcommand]
```

## サブコマンド

- `(なし)`: 新規Spec作成
- `update`: 既存Specを更新
- `validate`: Kickoffとの整合性チェック

## 処理

1. 前提条件チェック（`01_KICKOFF.md`必須）
2. Kickoff分析（Goal、成功条件、制約、依存関係）
3. コードベース調査（Glob/Grep、Exploreエージェント使用）
4. Spec作成（テンプレート使用）
5. 整合性チェック（Kickoff、既存仕様、テスト戦略）
6. state.json更新（current: wf2-spec, next: wf3-plan）
7. コミット

## 注意事項

- Kickoffの内容を勝手に変更しない
- 既存仕様との矛盾は警告
- 技術的に不可能な場合はKickoff修正を提案

## エージェント参照

[spec-writer エージェント](../../agents/workflow/spec-writer.md) に委譲。
