# Review: doc-fixer.md

> Reviewed: 2026-01-22
> Original: dotclaude/agents/task/doc-fixer.md

## 概要 (Summary)

このドキュメントは`doc-fixer`エージェントの仕様を定義しています。このエージェントは`.review.md`ファイルから抽出した改善点を対応する元のドキュメントに適用する役割を持ち、`/doc-fix`コマンドから呼び出されて並列処理で複数のレビューファイルを効率的に処理します。

ドキュメントは以下の主要セクションで構成されています：
- Metadata: エージェントの基本情報
- Purpose: エージェントの目的
- Context: 入力パラメータと参照ファイル
- Capabilities: 機能一覧
- Constraints: 制約条件
- Instructions: 詳細な処理手順
- Output Format: 出力形式

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
| H1 | Instructions セクション 2. Derive Original File | 拡張子の優先順位の根拠が不明確。また、`.sh`, `.py`, `.ts`などのコード系ファイルが明示的に除外されている理由の説明がコメントのみ | 拡張子リストの選定基準を明記するか、またはサポート対象拡張子を設定ファイルで管理可能にする設計を検討 | ✓ Fixed (2026-01-22) |
| H2 | Constraints セクション | バックアップ戦略が「git利用可能ならgit依存、そうでなければバックアップなし」となっており、gitが利用できない環境でのデータ損失リスクがある | gitが利用できない場合のフォールバック（例：`.bak`ファイル作成）を検討するか、少なくとも警告メッセージの出力を推奨 | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| M1 | Context > Reference Files | テンプレート参照パスが2つ記載されているが、どちらが優先されるか明記されていない | 優先順位を明記（例：「プロジェクト固有 > グローバル」） | ✓ Fixed (2026-01-22) |
| M2 | Instructions セクション 5. Apply Fixes | 「Literal application」と「Contextual implementation」の判断基準が曖昧 | エージェントがどちらを選択するかの具体的な判断基準（例：「提案テキストに引用符やコードブロックがある場合はLiteral」）を追加 | ✓ Fixed (2026-01-22) |
| M3 | Output Format | `partial`ステータスの定義で「at least one fix applied AND at least one fix failed」とあるが、0件修正成功で1件失敗の場合の扱いが不明確 | 「1件以上成功かつ1件以上失敗」の定義を維持し、「0件成功」は`failure`であることを明示 | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- **ドライラン機能**: 実際に変更を適用せず、適用予定の変更内容をプレビューする機能の追加を検討 ✓ Fixed (2026-01-22)
- **ロールバック機能**: 適用した修正を元に戻す機能の追加（gitに依存しない形式で） ✓ Fixed (2026-01-22)
- **修正適用の粒度設定**: 現在は「all or nothing per issue」だが、1つのissue内で部分的な修正を許可するオプションの検討 ✓ Fixed (2026-01-22)
- **エラーハンドリングの強化**: 現在のpseudocodeでは`catch error`となっているが、具体的なエラー種別（parse error、file permission error等）に応じた処理分岐の追加 ✓ Fixed (2026-01-22)

## 総評 (Overall Assessment)

`doc-fixer`エージェントのドキュメントは全体的に高品質で、エージェントの目的、処理フロー、入出力形式が明確に記載されています。特に以下の点が優れています：

1. **構造化された仕様**: Metadata、Purpose、Capabilities、Constraintsなど、エージェント仕様として必要な要素が網羅されている
2. **詳細な処理手順**: pseudocodeを用いた手順説明により、実装者が理解しやすい
3. **出力形式の明確化**: JSON形式での出力仕様が具体的に定義されている
4. **エラーハンドリング**: partial/failure/successの3段階ステータスにより、呼び出し元が適切に結果を処理できる

改善点としては、バックアップ戦略の強化と、いくつかの曖昧な判断基準の明確化が挙げられます。これらは実装時の解釈の齟齬を防ぐために重要です。

**推奨アクション**: 優先度高の2項目については早期に対応を検討してください。特にバックアップ戦略は、データ損失を防ぐ観点から重要です。
