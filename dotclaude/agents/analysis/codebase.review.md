# Review: codebase.md

> Reviewed: 2026-01-22
> Original: dotclaude/agents/analysis/codebase.md

## 概要 (Summary)

このドキュメントは「codebase」エージェントの定義ファイルです。コードベースの構造、パターン、実装を調査するための探索型エージェントとして設計されています。特定の機能やモジュールがどこでどのように実装されているかを特定することを目的としています。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [x] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [ ] **情報の正確性 (Correct information)**: 記載内容が正確
- [ ] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Instructions セクション (行63-73) | `grep` や `find` コマンドの直接使用を推奨しているが、Claude Code では専用ツール（Grep、Glob）の使用が推奨されている | `grep -r` → Grep ツール、`find` → Glob ツールを使用するよう記述を更新 | ✓ Fixed (2026-01-22) |
| 2 | Search Strategy Selection (行59-74) | シェルコマンドの例が Claude Code の実際のツール使用方法と一致していない | Claude Code の Grep、Glob、Read ツールの使用例に置き換える | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Output Format (行97-157) | TypeScript 固有の例（`*.ts`, `*.tsx`）のみが記載されている | プロジェクトの実際の言語構成（Markdown が主体）に合わせた例を追加するか、言語非依存の記述に変更 | ✓ Fixed (2026-01-22) |
| 2 | Reference Files (行23) | 「Source code within the project」のみで具体性がない | 参照すべき主要なファイルやディレクトリの例を追記 | ✓ Fixed (2026-01-22) |
| 3 | Capabilities セクション | 機能の説明が抽象的 | 各機能に具体的な使用例やシナリオを追加 | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- 多言語プロジェクト対応のための検索パターンの拡充 ✓ Fixed (2026-01-22)
- 実行例セクションの追加（実際の調査クエリと結果の例） ✓ Fixed (2026-01-22)
- 他のエージェント（doc-reviewer など）との連携方法の明記 ✓ Fixed (2026-01-22)
- パフォーマンス考慮事項（大規模コードベースでの推奨検索戦略） ✓ Fixed (2026-01-22)

## 総評 (Overall Assessment)

このドキュメントは全体的に良く構成されており、コードベース調査エージェントの目的、機能、制約、出力形式が明確に定義されています。

**強み:**
- 明確な構造とセクション分け
- 調査プロセスのステップバイステップの説明
- 包括的な出力フォーマットの定義
- 適切な制約の設定（読み取り専用、機密ファイル除外）

**改善が必要な点:**
最も重要な改善点は、シェルコマンド（`grep`、`find`）の使用例を Claude Code の専用ツール（Grep、Glob、Read）に置き換えることです。これは Claude Code の使用ガイドラインに準拠し、実際の使用時の混乱を防ぐために重要です。

**推奨アクション:**
1. 検索戦略セクションのコマンド例を Claude Code ツールに更新
2. 言語固有の例をより汎用的なものに拡張
3. 具体的な使用シナリオを追加して実用性を向上
