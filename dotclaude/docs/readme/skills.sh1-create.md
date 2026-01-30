# /sh1-create

バッチワークフロー実行のスケジュール管理コマンド。

## 使用方法

```
/sh1-create create github="label:scheduled"
/sh1-create show
/sh1-create edit [work-id]
/sh1-create validate
/sh1-create clear
```

## サブコマンド

| サブコマンド | 説明 |
|------------|------|
| `create` | ソースからスケジュール作成（GitHub/Jira/local） |
| `show` | 現在のスケジュール表示 |
| `edit` | 優先度・依存関係を編集 |
| `validate` | 循環依存等の検証 |
| `clear` | スケジュール削除 |

## 処理

- **create**: ソースからIssue取得 → work-id生成 → 依存関係検出 → 循環チェック → 優先度割当 → schedule.json保存
- **show**: ステータス、進捗、優先度順のwork一覧を表示
- **edit**: `priority=<1-10>`, `depends=<ids>`, `remove-dep=<id>`
- **validate**: 循環依存、未解決参照、優先度競合をチェック

## 注意事項

- `gh` CLI（GitHub用）、`jq`（JSON処理）が必要
- `.wf/schedule.json`に保存
