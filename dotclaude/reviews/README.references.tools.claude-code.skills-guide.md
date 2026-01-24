# Review: skills-guide.md

> Reviewed: 2026-01-24
> Original: dotclaude/references/tools/claude-code/skills-guide.md

## 概要 (Summary)

このドキュメントは Claude Code のスキル（`.claude/skills/*/SKILL.md`）の書き方を解説するガイドである。スキルの定義、ディレクトリ構造、SKILL.md の構造、フロントマターフィールド、description の書き方、references/external の使い方、サポートファイルの活用、スキルの種類、サブエージェント実行、呼び出し制御、ツール制限、実装チェックリストを網羅的にカバーしている。

対象読者は Claude Code でカスタムスキルを作成・管理する開発者である。

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
| 1 | フロントマターフィールド | `model` フィールドの値 `haiku`, `sonnet`, `opus` がどのように動作するか説明がない | 各モデルの使い分けガイダンスと、`inherit` の動作について詳細を追加する | ✓ Fixed (2026-01-24) |
| 2 | external の使い方 | `external-links.yaml` のファイル形式や必須フィールドの説明が不足 | external-links.yaml の完全な構造と例を追加する | ✓ Fixed (2026-01-24) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | サブエージェント実行 | `$ARGUMENTS` 変数の説明がない | `$ARGUMENTS` の取得方法と使用例を追加する | ✓ Fixed (2026-01-24) |
| 2 | エージェント型 | `Explore`, `Plan`, `general-purpose` 以外のエージェント型があるか不明 | 利用可能な全エージェント型のリストまたは参照リンクを追加する | ✓ Fixed (2026-01-24) |
| 3 | ツール制限 | `allowed-tools` で指定可能なツール名の完全なリストがない | 使用可能なツール名のリストを追加するか、参照先を明記する | ✓ Fixed (2026-01-24) |

### 将来の検討事項 (Future Considerations)

- スキル作成時のトラブルシューティングセクションの追加
- スキルのデバッグ方法の解説
- スキルのバージョン管理に関するガイダンス
- 複数のスキルが競合した場合の優先度解決ルールの説明
- `context: fork` 時のメモリ/コンテキスト制限についての説明

## 総評 (Overall Assessment)

このドキュメントは Claude Code スキルを作成するための包括的で実用的なガイドである。構造が明確で、表やコード例を効果的に使用しており、読者が迅速にスキル作成を開始できるようになっている。

特に優れている点：
- 明確なディレクトリ構造の説明
- フロントマターフィールドの体系的な整理
- 「BAD/GOOD」パターンによる description の書き方の解説
- Reference Content と Task Content の2種類のスキルタイプの区別
- 実装チェックリストによる品質確保

改善すべき主な点として、一部のフィールド（model、allowed-tools）の詳細な動作説明と、サブエージェント実行時の変数や制限事項の説明が挙げられる。これらを補完することで、より完全なリファレンスとなる。

全体として、スキル作成に必要な情報が十分に提供されており、高品質なドキュメントである。
