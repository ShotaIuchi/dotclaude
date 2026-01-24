# Review: test-writer.md

> Reviewed: 2026-01-22
> Original: dotclaude/agents/task/test-writer.md

## 概要 (Summary)

このドキュメントは `test-writer` エージェントの仕様を定義しています。指定されたファイルやモジュールに対してテストを作成するタスクエージェントであり、ユニットテストと統合テストの両方をサポートします。既存のテストスタイルに準拠したテストコード生成を目的としています。

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
| 1 | Instructions セクション | `cat` や `find` などのシェルコマンドを直接使用している | Claude Code のベストプラクティスに従い、Read ツールや Glob ツールの使用を推奨する記述に変更 | ✓ Fixed (2026-01-22) |
| 2 | Reference Files | TypeScript のみを想定した例（jest.config.js, vitest.config.ts）| 他の言語やテストフレームワーク（pytest, go test, JUnit等）への対応も明記 | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Input パラメータ | `type` パラメータの選択肢が "unit" と "integration" のみ | E2Eテストなど他のテストタイプの追加を検討 | ✓ Fixed (2026-01-22) |
| 2 | Constraints | テストを実行しないという制約のみ | テスト生成後の検証方法（構文チェック等）について言及を追加 | ✓ Fixed (2026-01-22) |
| 3 | Output Format | TypeScript/Jest のみを想定した出力形式 | 言語・フレームワーク非依存のテンプレートパターンを追加 | ✓ Fixed (2026-01-22) |
| 4 | Mock Design | Jest のみのモック記法を使用 | 他のフレームワーク（vitest, sinon 等）のモック例も追加 | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- テストカバレッジの自動計測との連携機能 (F1)
- 既存テストとの重複チェック機能 (F2)
- BDD（Behavior-Driven Development）スタイルのテスト記述サポート (F3)
- プロパティベーステスト（property-based testing）のサポート (F4)
- テストデータ生成（faker/factory）パターンの追加 (F5)

## 総評 (Overall Assessment)

`test-writer` エージェントの仕様書として、基本的な構造は十分に整っています。Purpose、Context、Capabilities、Constraints、Instructions、Output Format という標準的なセクション構成で、エージェントの役割と動作が明確に定義されています。

特に優れている点：
- テストケース設計の体系的なアプローチ（Happy Path、Error Cases、Boundary Values、Edge Cases）
- AAA（Arrange-Act-Assert）パターンの明示
- カバレッジ予測を含む詳細な出力形式

改善が望まれる点：
- シェルコマンドの直接使用は Claude Code のツール使用ベストプラクティスに反する可能性がある
- TypeScript/Jest に偏った記述が多く、他の言語・フレームワークへの汎用性が低い

全体として、このドキュメントは実用的なエージェント仕様として機能しますが、マルチ言語・マルチフレームワーク対応を強化することで、より汎用的なテスト作成エージェントとして活用できるようになります。
