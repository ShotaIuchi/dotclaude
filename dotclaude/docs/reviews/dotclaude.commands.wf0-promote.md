# Review: wf0-promote.md

> Reviewed: 2026-01-25
> Original: dotclaude/commands/wf0-promote.md

## 概要 (Summary)

ローカルワークフローをGitHub IssueまたはJiraチケットに昇格させるコマンドのドキュメント。`source.type: "local"`のワークフローを外部のイシュートラッカーにリンクし、チーム共有や進捗管理を可能にする。処理フローは検証、Issue作成、state.json更新、キックオフ更新、オプションのwork-id変更、コミットまでをカバー。

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
| 1 | Step 3 `sed`コマンド | macOS/Linux間で`sed -i`の挙動が異なる。`sed -i ''`はmacOS専用 | クロスプラットフォーム対応方法を記載するか、スクリプト側で分岐処理を推奨 | ✓ Fixed (2026-01-25) |
| 2 | Step 3 `gh issue create` | エラーハンドリングがない。Issue作成失敗時の処理が未定義 | `result`の検証と失敗時のロールバック処理を追加 | ✓ Fixed (2026-01-25) |
| 3 | Step 4 Jira処理 | `read`コマンドによる対話入力が必要。自動化やCI環境で動作不可 | 環境変数または設定ファイルでの代替入力方法を提示 | ✓ Fixed (2026-01-25) |
| 4 | Step 7 work-id変更 | 対話的なプロンプトと概要説明のみで、実装の詳細がない | 具体的なbashスクリプト例を追加（ディレクトリリネーム、state.json更新、git branch更新） | ✓ Fixed (2026-01-25) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Step 3 sedパターン | `sed -n '/^## Goal/,/^## /p'`は最終セクションの場合に失敗する可能性あり | より堅牢なパターン、またはマークダウンパーサーの使用を検討 | ✓ Fixed (2026-01-25) |
| 2 | Step 4 Jira URL | `https://your-domain.atlassian.net`がハードコード | `.wf/config.json`からJiraドメインを読み取る実装を追加 | ✓ Fixed (2026-01-25) |
| 3 | 日本語混在 | Step 7で日本語UI表示があるが、他はすべて英語 | UIメッセージの言語を統一（英語推奨）、または国際化対応の方針を明記 | ✓ Fixed (2026-01-25) |
| 4 | Prerequisites | Jira CLIの具体的なツール名や設定方法が不明確 | 推奨Jira CLI（例: `jira-cli`）とインストール・設定手順へのリンクを追加 | ✓ Fixed (2026-01-25) |

### 将来の検討事項 (Future Considerations)

- 複数のイシュートラッカー（GitLab Issues, Linear, Asana等）への拡張可能性
- Jira機能の完全実装（現在はプレースホルダー） ✓ Partially addressed (2026-01-25)
- 昇格のロールバック機能（誤って昇格した場合の取り消し）
- 昇格履歴の永続化（どのイシューがいつ作成されたかの追跡）
- `--dry-run`オプションによる事前確認機能

## 総評 (Overall Assessment)

ドキュメントは全体的に良く構成されており、処理フローが明確に記述されている。GitHub Issue昇格の実装は詳細で実用的。ただし、Jira対応は不完全（プレースホルダー状態）であり、実運用には追加実装が必要。

主な懸念点:
1. **クロスプラットフォーム対応**: macOS固有の`sed`構文が使用されており、Linux環境での動作に問題が生じる可能性
2. **エラーハンドリング**: 外部コマンド（`gh`、`jira`）の失敗時の処理が不十分
3. **対話的入力への依存**: Jira処理で`read`コマンドを使用しており、自動化環境では動作しない

推奨アクション:
1. 高優先度の技術的問題を修正
2. Jira機能を完全実装するか、明示的に「未実装」とマークして将来対応を明記
3. クロスプラットフォーム対応のテストを実施
