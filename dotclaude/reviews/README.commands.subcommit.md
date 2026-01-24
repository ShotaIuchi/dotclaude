# Review: subcommit.md

> Reviewed: 2026-01-24
> Original: dotclaude/commands/subcommit.md

## 概要 (Summary)

`/subcommit` コマンドは、メインセッションをブロックせずにサブエージェントでコミット処理を非同期実行するためのコマンド定義である。バックグラウンドでコミットを行うことで、ユーザーが他の作業を継続できる点が特徴。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [x] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [x] **情報の正確性 (Correct information)**: 記載内容が正確
- [x] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | 6行目 Frontmatter | `description` と `argument-hint` が定義されているが、命名規則に準拠しているかの確認が必要 | 他の commands ファイルと比較して形式の一貫性を確認 | ✓ Verified (2026-01-24) |
| 2 | 69行目 Prompt Template | subagent_type が `Bash` となっているが、コミット操作には git コマンドの実行と判断が必要で、`general-purpose` の方が適切 | `subagent_type` を `general-purpose` に変更し、Bash ツールへのアクセスを明示 | ✓ Fixed (2026-01-24) |
| 3 | 91行目 Co-Authored-By | `Claude <noreply@anthropic.com>` となっているが、他のドキュメントでは `Claude Opus 4.5 <noreply@anthropic.com>` を使用 | Co-Authored-By の形式を統一: `Claude Opus 4.5 <noreply@anthropic.com>` | ✓ Fixed (2026-01-24) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | 83行目 `git add -A` | ステージされていない変更を自動で全てステージする動作は、意図しないファイル（.env、認証情報等）をコミットするリスクがある | `commit-guard.md` のポリシーに従い、センシティブファイルの除外チェックを追加 | ✓ Fixed (2026-01-24) |
| 2 | 110-121行目 Options | `--dry-run` と `--amend` オプションが定義されているが、実際の Prompt Template には反映されていない | オプションがある場合の Prompt Template の分岐を明確に記述 | ✓ Fixed (2026-01-24) |
| 3 | 119行目 `--amend` | `--amend` 使用時の注意事項が Notes にあるが、警告表示やユーザー確認のフローがない | `--amend` 使用時にユーザー確認を求めるか、直前のコミット情報を表示する処理を追加 | ✓ Fixed (2026-01-24) |

### 将来の検討事項 (Future Considerations)

- **ステージ対象の選択機能**: 変更ファイルの一覧を表示し、ユーザーが選択的にステージできる機能
- **コミットメッセージのプレビュー**: 自動生成されたメッセージを事前に確認・編集できる機能
- **キャンセル機能**: バックグラウンド実行中のコミット処理をキャンセルする方法
- **pre-commit hook 失敗時のリトライ**: フック失敗時の対処手順の明確化

## 総評 (Overall Assessment)

`/subcommit` コマンドは、非同期コミットという有用な機能を提供しており、ドキュメント自体の構成は明確で読みやすい。Usage、Examples、Processing、Options という流れで情報が整理されている。

ただし、以下の点で改善が必要：

1. **安全性の観点**: `git add -A` による自動ステージングは、センシティブファイルの誤コミットリスクがある。`commit-guard.md` や CLAUDE.md のガイドラインとの整合性を取る必要がある。

2. **技術的整合性**: `subagent_type: Bash` の選択は再検討が必要。コミットメッセージの自動生成には変更内容の分析が必要であり、`general-purpose` エージェントの方が適切。

3. **Co-Authored-By の統一**: プロジェクト全体で使用している形式（`Claude Opus 4.5`）に合わせるべき。

全体として良質なドキュメントだが、上記の高優先度の問題を修正することで、より安全で一貫性のあるコマンドになる。
