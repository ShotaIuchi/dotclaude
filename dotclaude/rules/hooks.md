# Hooks System

Claude Codeのフックによる自動化ルール。

## 概要

`hooks.json`で定義されたフックは、ツール実行の前後やセッションイベント時に自動実行される。
人間が見逃すミスを自動検出し、品質の底上げを行う。

## 対応言語

| 言語 | 拡張子 | 検出対象 | 推奨代替 |
|------|--------|----------|----------|
| TypeScript/JavaScript | `.ts`, `.tsx`, `.js`, `.jsx` | `console.log` | - |
| Kotlin | `.kt`, `.kts` | `println`, `Log.d/e/w/i/v` | Timber |
| Swift | `.swift` | `print`, `NSLog`, `debugPrint` | os_log, Logger |
| Java | `.java` | `System.out.print`, `Log.d/e/w/i/v` | Timber |
| Python | `.py` | `print()` | logging module |
| Go | `.go` | `fmt.Print`, `log.Print` | - |
| Rust | `.rs` | `println!`, `print!`, `dbg!` | tracing, log crate |

## 有効なフック

### PreToolUse (ツール実行前)

| フック | 対象 | 動作 |
|--------|------|------|
| Dev server tmux強制 | `npm run dev`等 | tmux外での実行をブロック |
| Git push確認 | `git push` | プッシュ前にリマインダー表示 |
| 非標準.md警告 | `.md`ファイル作成 | テンプレート外のmd作成を警告 |

### PostToolUse (ツール実行後)

| フック | 対象 | 動作 |
|--------|------|------|
| デバッグログ警告 | 上記全言語 | デバッグ用出力の存在を警告 |
| PR URL表示 | `gh pr create` | 作成されたPR URLを表示 |

### Stop (レスポンス完了後)

| フック | 対象 | 動作 |
|--------|------|------|
| 未コミットデバッグログ検査 | 全言語 | 変更ファイル内のデバッグログを検出 |

## CONSTITUTION との関連

### Article 6: コマンド実行前検証

フックはArticle 6「コマンド実行前検証」を自動化する手段である。

- PreToolUseフックで危険なコマンドをブロック
- PostToolUseフックでエラーを即座に検出

### Article 2: 同時ドキュメント作成

非標準.md警告フックは、ドキュメントが適切な場所に作成されることを促す。

## カスタマイズ

プロジェクト固有のフックは `.claude/hooks.json` で追加可能。

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool == \"Edit\" && tool_input.file_path matches \"your-pattern\"",
        "hooks": [{ "type": "command", "command": "your-command" }],
        "description": "Your custom hook"
      }
    ]
  }
}
```

## 除外設定

特定のファイルでデバッグログを許可する場合は、コメントで無効化できる：

```kotlin
// 開発用ログ（本番では削除）
println("debug: $value") // hook-ignore
```

（現在の実装ではコメント行は検出対象外）

## 依存関係

- Node.js: フックスクリプト実行に必要
