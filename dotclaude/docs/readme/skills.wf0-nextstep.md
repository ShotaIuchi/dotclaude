# /wf0-nextstep

次のワークフローコマンドを確認なしで即時実行するコマンド。

## 使用方法

```
/wf0-nextstep [work-id]
```

## 処理

state.jsonの`next`フィールドに基づいて次のコマンドを決定・実行：

| `next`の値 | アクション |
|---|---|
| null/空 | エラー（`/wf0-status`を案内） |
| `"complete"` + PR有 | 完了表示（PR URL） |
| `"complete"` + PR無 | `/wf6-verify pr`を案内 |
| `"wf5-implement"` | 次ステップ番号付きで実行 |
| その他 | 該当フェーズを実行 |

## 注意事項

- ユーザー確認なしで即時実行
- wf5-implementの場合はステップ番号を引数として渡す
