# /wf2-kickoff

Kickoffドキュメントを作成または更新するコマンド。

## 使用方法

```
/wf2-kickoff [subcommand] [options]
```

## サブコマンド

- `(なし)`: 新規作成またはインタラクティブモードで確認
- `update`: 既存Kickoffの更新
- `revise "<instruction>"`: 指示に基づく修正
- `chat`: ブレインストーミング対話モード

## 処理内容

1. **現在の作業状態確認**
   - active_workの確認

2. **ソース情報の取得**
   - github: Issueから情報取得
   - jira: state.jsonから情報取得
   - local: Plan Modeで要件探索

3. **サブコマンド別処理**

### 新規作成

**GitHub/Jiraソースの場合:**
- Issue内容を分析
- ユーザーと対話してGoal、Success Criteria、Constraintsなどを確認
- `00_KICKOFF.md`を作成

**Localソースの場合:**
- Plan Modeに入り要件を探索
- `plan.md`を作成
- plan.mdの内容から`00_KICKOFF.md`を作成

### update
- 現在のKickoffを読み込み
- ユーザーと対話して変更を確認
- `05_REVISIONS.md`に履歴を追加

### revise
- 指示に基づいて自動修正
- ユーザー確認後に更新

### chat
- 自由対話モードで質問・議論

## 対話ガイド

**Goalについて:**
- この作業で何を達成したいか？
- なぜこの機能/修正が必要か？

**Success Criteriaについて:**
- 完了の条件は？
- どのように成功を測定するか？

**Constraintsについて:**
- 技術的制約はあるか？
- パフォーマンス要件はあるか？

## 出力例

```
✅ Kickoff document created

File: docs/wf/FEAT-123-export-csv/00_KICKOFF.md
Revision: 1

Next step: Run /wf3-spec to create the specification
```

## 注意事項

- 既存内容を上書きする前に必ず確認
- Revision履歴を必ず維持
- Issue内容との矛盾をチェック
