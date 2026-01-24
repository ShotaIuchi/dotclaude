# /wf0-restore

既存のワークスペースを復元するコマンド。別のPCで作業を再開する場合やworktreeの再作成に使用。

## 使用方法

```
/wf0-restore [work-id]
```

## 引数

- `work-id`: 復元する作業のID（オプション）
  - 省略時: `state.json`の`active_work`を使用
  - `active_work`も未設定: 候補を表示して選択

## 処理内容

1. **前提条件チェック**
   - `jq`、`git`コマンドの存在確認

2. **work-idの解決**
   - 引数、active_work、または候補からの選択

3. **リモートから最新情報を取得**
   - `git fetch --all --prune`

4. **ブランチの復元**
   - ローカルに存在: チェックアウト
   - リモートのみ: ローカルブランチ作成

5. **worktreeの復元**（オプション）
   - config.worktree.enabledがtrueの場合

6. **active_workの更新**

## 出力例

```
✅ Workspace restored

Work ID: FEAT-123-export-csv
Branch: feat/123-export-csv
Base: develop
Current: wf3-spec
Next: wf4-plan

Documents:
- docs/wf/FEAT-123-export-csv/

Next step: Run /wf4-plan
```

## 注意事項

- state.jsonが存在しない場合はエラー
- 指定したwork-idが存在しない場合はエラー
- ブランチがローカル・リモートどちらにも存在しない場合はエラー
- worktreeのルートディレクトリは自動作成
