# /wf1-kickoff

Kickoff ドキュメントを作成・更新するコマンド。

## 使用方法

```
/wf1-kickoff [サブコマンド] [オプション]
```

## サブコマンド

- `(なし)`: 新規作成または対話モードで確認
- `update`: 既存の Kickoff を更新
- `revise "<指示>"`: 指示に基づいて修正
- `chat`: 壁打ち対話モード

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. 現在の作業状態を確認

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
if [ -z "$work_id" ]; then
  echo "アクティブな作業がありません"
  echo "/wf0-workspace または /wf0-restore を実行してください"
  exit 1
fi

docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
revisions_path="$docs_dir/05_REVISIONS.md"
```

### 2. GitHub Issue 情報の取得

work-id から Issue 番号を抽出して情報取得：

```bash
issue_number=$(echo "$work_id" | sed 's/^[A-Z]*-\([0-9]*\)-.*/\1/')
gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone
```

### 3. サブコマンド別処理

#### 新規作成（サブコマンドなし）

1. Issue の内容を分析
2. ユーザーと対話して以下を確認：
   - Goal（目標）
   - Success Criteria（成功条件）
   - Constraints（制約）
   - Non-goals（スコープ外）
   - Dependencies（依存関係）

3. `00_KICKOFF.md` を作成

**テンプレート参照:** `~/.claude/templates/00_KICKOFF.md` を読み込んで使用してください。

テンプレートのプレースホルダを対話で決定した内容で置換します。

#### update

1. 現在の `00_KICKOFF.md` を読み込み
2. ユーザーと対話して変更点を確認
3. `00_KICKOFF.md` を更新
4. `05_REVISIONS.md` に履歴を追記
   - **テンプレート参照:** `~/.claude/templates/05_REVISIONS.md` を読み込んで使用
5. state.json の `kickoff.revision` をインクリメント

#### revise "<指示>"

1. 現在の `00_KICKOFF.md` を読み込み
2. 指示に基づいて自動修正
3. 変更内容をユーザーに確認
4. 承認されたら更新
5. `05_REVISIONS.md` に履歴を追記

#### chat

1. 現在の `00_KICKOFF.md` を読み込み（存在すれば）
2. Issue 情報を表示
3. 自由対話モードで質問や議論
4. 対話内容は Notes セクションに反映可能

### 4. state.json の更新

```bash
# current を更新
jq ".works[\"$work_id\"].current = \"wf1-kickoff\"" .wf/state.json > tmp && mv tmp .wf/state.json

# 完了後は next を更新
jq ".works[\"$work_id\"].next = \"wf2-spec\"" .wf/state.json > tmp && mv tmp .wf/state.json

# kickoff 情報を更新
jq ".works[\"$work_id\"].kickoff.revision = <new_revision>" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].kickoff.last_updated = \"<timestamp>\"" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 5. 壁打ち対話のガイド

Kickoff 作成時は以下の観点でユーザーと対話：

**Goal について:**
- この作業で何を達成したいですか？
- なぜこの機能/修正が必要ですか？
- ユーザーにどのような価値を提供しますか？

**Success Criteria について:**
- 完了とみなす条件は何ですか？
- どうやって成功を測定しますか？
- 最低限達成すべきことは何ですか？

**Constraints について:**
- 技術的な制約はありますか？
- パフォーマンス要件はありますか？
- 互換性の要件はありますか？

**Non-goals について:**
- 今回は対応しないことは何ですか？
- 将来の課題として残すことは？

**Dependencies について:**
- 他の作業に依存していますか？
- 外部サービスや API に依存していますか？

### 6. 完了メッセージ

```
✅ Kickoff ドキュメントを作成しました

ファイル: docs/wf/<work-id>/00_KICKOFF.md
Revision: 1

次のステップ: /wf2-spec を実行して仕様書を作成してください
```

## 注意事項

- 既存の内容を上書きする前に必ず確認
- Revision 履歴は必ず保持
- Issue の内容と矛盾がないか確認
