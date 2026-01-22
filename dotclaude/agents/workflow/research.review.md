# Review: research.md

> Reviewed: 2026-01-22
> Original: dotclaude/agents/workflow/research.md

## 概要 (Summary)

このドキュメントは、GitHub Issueの背景調査とコードベース調査を行う「research」エージェントの定義書である。wf1-kickoffの事前準備として、Issueの理解を深めるための情報収集を担当する。Metadata、Purpose、Context、Capabilities、Constraints、Instructions、Output Formatの各セクションで構成されている。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [ ] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [ ] **情報の正確性 (Correct information)**: 記載内容が正確
- [x] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Instructions セクション | コード検索に`grep`と`find`コマンドを直接使用しているが、Claude Codeでは専用ツール（Grep, Glob）の使用が推奨されている | `grep -r`を`Grep`ツール、`find`を`Glob`ツールに置き換える旨の説明を追加する | ✓ Fixed (2026-01-22) |
| 2 | Output Format | 出力先の指定がない。調査結果をどこに保存するか（例：`.wf/research/<issue>.md`）が不明確 | 出力ファイルのパス規則を明示する | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Context セクション | `work-id`から自動取得する仕組みの詳細説明がない | `work-id`の形式や取得ロジックへの参照を追加する | ✓ Fixed (2026-01-22) |
| 2 | Capabilities | 「Understanding Dependencies」の内容が抽象的 | 具体的な依存関係の調査方法（package.json、import文解析等）を例示する | ✓ Fixed (2026-01-22) |
| 3 | Constraints | 「structured format」でレポートするとあるが、Output Formatとの関連が明示されていない | Constraintsセクション内でOutput Formatセクションへの参照を追加する | ✓ Fixed (2026-01-22) |
| 4 | Instructions 2 | 分析観点の英語表記が日本語プロジェクトとして統一感を欠く | 他のエージェント定義との整合性を確認し、言語を統一する | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- エラーハンドリング：Issueが存在しない場合や、`gh`コマンドが認証されていない場合の対応手順を追加する ✓ Fixed (2026-01-22)
- 調査の深度制限：大規模コードベースでの調査時間上限やファイル数上限の設定を検討する ✓ Fixed (2026-01-22)
- キャッシュ戦略：同一Issueに対する再調査時に前回の結果を活用する仕組みを検討する ✓ Fixed (2026-01-22)
- 他エージェントとの連携：wf1-kickoffへの引き継ぎ方法の詳細化 ✓ Fixed (2026-01-22)

## 総評 (Overall Assessment)

全体として、researchエージェントの役割と機能が明確に定義されており、実用的なドキュメントである。特にOutput Formatセクションは構造化されたMarkdownテンプレートを提供しており、一貫した出力を担保できる。

改善すべき主な点は以下の2点：

1. **ツール使用の整合性**: Claude Code環境では`grep`や`find`ではなく専用ツール（Grep, Glob）を使用すべきであり、Instructionsセクションの更新が必要
2. **出力先の明確化**: 調査結果の保存場所が未定義であり、ワークフロー全体での成果物管理との整合性を確保する必要がある

これらの改善を行うことで、より実践的で他のワークフローコマンドとの連携がスムーズなエージェント定義になると考えられる。
