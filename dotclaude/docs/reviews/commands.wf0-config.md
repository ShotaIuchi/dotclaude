# Review: wf0-config.md

> Reviewed: 2026-01-26
> Original: commands/wf0-config.md

## 概要 (Summary)

`.wf/config.json`の設定を対話的に編集するためのコマンド定義ドキュメント。`show`、`init`、カテゴリ指定、対話モードの4つの使用方法を提供し、ブランチ設定・Worktree設定・コミット設定・検証コマンド設定・Jira連携設定の5つのカテゴリを管理する。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [x] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [x] **情報の正確性 (Correct information)**: 記載内容が正確
- [ ] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Configuration Categories テーブル | `branch`カテゴリに`allow_pattern_candidates`が記載されていない | Config Schemaには`allow_pattern_candidates`が含まれているため、テーブルに追加するか、設定対象外であることを明記する | ✓ Fixed (2026-01-26) |
| 2 | Branch Settings ダイアログ | `allow_pattern_candidates`の対話ダイアログが欠落 | `release/.*`や`hotfix/.*`パターンを設定するダイアログを追加する | ✓ Fixed (2026-01-26) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | `show` subcommand | `allow_pattern_candidates`の表示がない | 出力例に`Allow patterns: release/.*, hotfix/.*`を追加する | ✓ Fixed (2026-01-26) |
| 2 | Verify Settings ダイアログ | build/lintコマンドの詳細ダイアログが「Similar dialogs」と省略されている | 他のwf0系コマンド（wf0-restore等）と同様に明示的に記述するか、省略が意図的であることを明記する | ✓ Fixed (2026-01-26) |
| 3 | Notes セクション | `config.json`が存在しない場合の挙動が不明確 | `init`を促すだけでなく、引数なしで実行した場合に自動的に`init`フローに入るかどうかを明記する | ✓ Fixed (2026-01-26) |
| 4 | Processing セクション | `$ARGUMENTS`の解説がない | 他のコマンド（wf0-status等）では暗黙的に使用されているが、新規読者向けに簡潔な説明があると良い | ✓ Fixed (2026-01-26) |

### 将来の検討事項 (Future Considerations)

- `reset`サブコマンドの追加（設定をデフォルトにリセット）
- `export`/`import`サブコマンドの追加（設定のバックアップ・復元）
- `--dry-run`オプションの追加（変更をプレビューのみ）
- カテゴリ間の依存関係のバリデーション（例：worktree有効時のroot_dir必須チェック）

## 総評 (Overall Assessment)

全体として、他のwf0系コマンドドキュメント（wf0-status, wf0-restore等）と一貫したスタイルで書かれており、2段階対話フローの設計も明確である。特にAskUserQuestionの使用例が具体的で実装しやすい。

主な改善点は`allow_pattern_candidates`の扱いの明確化である。Config Schemaには含まれているがカテゴリテーブルやダイアログには記載がないため、意図的な省略なのか漏れなのかが不明。対話で設定できない項目があるならその旨を明記するか、対話フローを追加すべき。

ドキュメントの品質は高く、実装に必要な情報は概ね揃っている。上記の改善を行えば、より完全なコマンド定義となる。
