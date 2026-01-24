# /wf0-status

現在のワークフローステータスを表示するコマンド。

## 使用方法

```
/wf0-status [work-id]
```

## 引数

- `work-id`: 表示する作業のID（オプション）
  - 省略時: `state.json`の`active_work`を使用
  - `all`を指定: すべての作業を表示

## 処理内容

1. **state.jsonの読み込み**
   - 存在しない場合は初期化を促す

2. **表示対象の決定**
   - 引数に応じて単一の作業または全作業を表示

3. **ステータス表示**
   - ブランチ情報、現在/次のフェーズ
   - ドキュメントの存在確認
   - フェーズ進捗の可視化

4. **Git状態の表示**（オプション）
   - 現在のブランチ、未コミット変更数

5. **Worktree情報**（有効時）
   - worktreeのパス表示

## 出力例

```
📋 WF Status: FEAT-123-export-csv
═══════════════════════════════════════

Branch:   feat/123-export-csv
Base:     develop
Current:  wf1-kickoff
Next:     wf2-spec

📁 Documents:
   docs/wf/FEAT-123-export-csv/
   ├── 00_KICKOFF.md    [exists]
   ├── 01_SPEC.md       [missing]
   └── ...

🔄 Phase Progress:
   [✓] wf1-kickoff
   [→] wf1-kickoff     ← current
   [ ] wf2-spec
   ...

💡 Next: /wf2-spec
```

## 注意事項

- state.jsonが存在しない場合は初期化を促す
- active_workが未設定の場合はメッセージを表示
- 指定したwork-idが存在しない場合はエラー
