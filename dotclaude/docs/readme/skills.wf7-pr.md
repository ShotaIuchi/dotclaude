# /wf7-pr

検証後にPRを作成・更新するコマンド。

## 使用方法

```
/wf7-pr [subcommand]
```

## サブコマンド

- `(なし)`: 新規PR作成
- `update`: 既存PRを更新

## 処理

1. 前提条件チェック（wf6-verify完了確認）
2. 既存PR確認（`gh pr view`）
3. ブランチをpush（`git push -u origin <branch>`）
4. PRタイトル生成（Kickoff Goalから、GitHub Issue紐づけ `(#N)`）
5. PR作成（`gh pr create`）
   - Summary: Kickoff Goal/Specからの要点
   - Changes: Planステップからの変更一覧
   - Test Plan: テスト方針
   - Related Issues: `Closes #N`
   - ドキュメントリンク
6. state.json更新（current: wf7-pr, next: complete, PR URL記録）

## update サブコマンド

1. 最新変更をpush
2. 必要に応じて`gh pr edit`でPR説明を更新

## エラー処理

| エラー | 対応 |
|-------|------|
| 検証未完了 | `/wf6-verify`を先に実行するよう案内 |
| PR既存 | `update`サブコマンドを案内 |
| Push失敗 | エラー表示、リモート状態確認を案内 |
| gh未認証 | `gh auth login`を案内 |

## 注意事項

- 検証PASSが必須
- Issue番号はタイトル`(#N)`とボディ`Closes #N`で自動リンク
- 既存PRは検出して適切に処理
