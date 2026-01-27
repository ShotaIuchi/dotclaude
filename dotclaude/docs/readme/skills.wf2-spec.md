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

---

## エージェント機能（spec-writerエージェントから統合）

このスキルは`context: fork`設定によりサブエージェントとして実行され、以下の専門機能を持つ。

### 要件構造化

- Kickoffから機能要件（FR）と非機能要件（NFR）を抽出
- Must/Should/Could基準で要件に優先度を割り当て:
  - **Must**: 納品に必須、交渉不可
  - **Should**: 重要だが必須ではない、必要に応じて延期可能
  - **Could**: 望ましいがオプション、あれば良い機能

### スコープ明確化

- In Scope / Out of Scopeの明確な分離
- 曖昧な境界を特定し、質問を生成

### 受入条件作成

- Given/When/Then形式で受入条件を作成
- テスト可能な形式で条件を定義

### ユースケース整理

- ユーザーストーリーを構造化
- エッジケースを特定
