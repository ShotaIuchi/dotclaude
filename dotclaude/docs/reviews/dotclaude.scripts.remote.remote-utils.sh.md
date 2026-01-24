# Review: remote-utils.sh

> Reviewed: 2026-01-24
> Original: dotclaude/scripts/remote/remote-utils.sh

## 概要 (Summary)

このファイルはWFリモートワークフロー操作のためのヘルパー関数群を提供するBashスクリプトである。主な機能として、GitHub Issueコメントでのコマンド監視、state.jsonの更新、GitHub Issueへのステータス投稿、Claude Code CLIの呼び出し、およびGit操作のサポートを提供する。

リモートデーモン機能の中核をなすユーティリティであり、人間とClaudeの非同期コラボレーションを可能にする重要なコンポーネントである。

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
| 1 | `wf_remote_update_status` (行84-88) | `jq`コマンドが失敗した場合、`$state_file.tmp`が不完全な状態で書き込まれ、その後の`mv`で元ファイルが破損する可能性がある | `jq`の終了ステータスを確認してから`mv`を実行する、または`&&`で連結する | ✓ Fixed (2026-01-25) |
| 2 | `wf_remote_check_commands` (行33-43) | `tonumber`が`last_id`が空文字列の場合にエラーになる可能性がある | 空文字列チェックを`jq`のフィルタ内で行うか、デフォルト値を設定する | ✓ Fixed (2026-01-25) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | `wf_remote_invoke_claude` (行178) | `claude --print`の出力が標準出力に混在し、成功/失敗の判断が呼び出し元で難しい | 出力を一時ファイルに保存するか、成功時の期待される出力パターンを確認する仕組みを追加 | ✓ Fixed (2026-01-25) |
| 2 | `wf_remote_post_status` (行117) | `gh issue comment`の失敗が黙殺される(`|| true`) | 重要なステータス通知の場合は失敗をログに記録するか、リトライ機能を追加 | ✓ Fixed (2026-01-25) |
| 3 | スクリプト全体 | ShellCheck による静的解析が未実施の可能性 | CI/CDパイプラインにShellCheckを追加し、潜在的な問題を早期に検出 | ✓ Fixed (2026-01-25) |

### 将来の検討事項 (Future Considerations)

- ログ出力の標準化（現在は`echo "[ERROR]"`等を使用しているが、統一されたログ関数の導入を検討）
- 設定可能なタイムアウト値の導入（`gh api`呼び出しなど）
- ユニットテストの追加（`bats`フレームワーク等を使用）
- コマンドパターンの拡張性（現在は`approve|next|pause|stop`のみハードコード）

## 総評 (Overall Assessment)

remote-utils.shはリモートワークフロー機能の中核を担う重要なユーティリティスクリプトである。全体的に良い構造を持ち、関数の命名規則（`wf_remote_*`）が統一され、各関数にはパラメータと戻り値のドキュメントが付与されている。

主要な強み:
- 明確な責任分離（各関数が単一の責務を持つ）
- GitHub CLI（`gh`）と`jq`の適切な使用
- 内部関数（`_wf_remote_*`）と公開関数の区別

改善が必要な領域:
- エラーハンドリングの堅牢性（特に`jq`処理とファイル操作）
- 失敗時のフォールバック処理
- テスト可能性の向上

現状は機能的に動作するコードであるが、本番環境での信頼性を高めるためには、上記の優先度高の項目への対応を推奨する。
