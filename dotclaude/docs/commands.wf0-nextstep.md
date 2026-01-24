# /wf0-nextstep

次のワークフローコマンドを確認なしで即座に実行するコマンド。

## 使用方法

```
/wf0-nextstep [work-id]
```

## 引数

- `work-id`: 対象のwork ID（オプション）
  - 省略時: `state.json`の`active_work`を使用

## 処理内容

1. **state.jsonの読み込み**
   - 存在しない場合は初期化を促す

2. **work-idの解決**
   - 引数またはactive_workから取得

3. **次のフェーズの決定**
   - nextフィールドを確認
   - null/empty/complete の場合は完了処理

4. **コマンドの即座実行**
   - wf5-implement: 未完了ステップがあればステップ引数付きで実行
   - その他: 次のフェーズコマンドを実行

## 出力例

```
🚀 Executing /wf2-spec...

(wf2-specコマンドの出力)
```

## 完了時の出力

```
✅ This work is complete

PR: https://github.com/...
```

## 注意事項

- **確認なしで即座実行**: このコマンドはユーザー確認なしで次のコマンドを実行
- state.jsonが存在しない場合は`/wf1-kickoff`を促す
- work-idが解決できない場合は明確なエラーを表示
- 完了した作業にはステータスを表示して終了
