# Review: SKILL.md

> Reviewed: 2026-01-22
> Original: dotclaude/skills/kmp-architecture/SKILL.md

## 概要 (Summary)

このドキュメントは、Kotlin Multiplatform (KMP) アーキテクチャに関するスキル定義ファイルである。KMP機能の実装、共有モジュールの作成、expect/actualパターンの使用、Koin/SQLDelight/Ktorの設定、Compose Multiplatformの実装時に参照されることを目的としている。コアプリンシプル、モジュール構造、ディレクトリ構造、expect/actualパターンの基本的な説明を提供している。

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
| 1 | 全体構成 | Android/iOS SKILLファイルに存在する「Naming Conventions」セクションが欠落している | 他のアーキテクチャスキルファイルとの一貫性のため、命名規則セクションを追加する（例：SharedViewModel, PlatformContext等のパターン） | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Layer Structure | Android/iOS SKILLには「Layer Structure」テーブルがあるが、KMPには「Module Structure」のみ | 各レイヤー（Presentation, Domain, Data）の責務を明示したテーブルを追加することで、他のドキュメントとの統一性を向上させる | ✓ Fixed (2026-01-22) |
| 2 | Core Principles | 「Single Source of Truth (SSOT)」が他のスキルファイルには記載されているがKMPには欠落 | SSOTの原則を追加し、共有モジュールにおけるリポジトリの役割を明確化する | ✓ Fixed (2026-01-22) |
| 3 | expect/actual Pattern | コード例が最小限で、iosMainのactual classの実装が空 | iosMain側の実装例をより実践的なものに拡充する（例：NSObject継承やプラットフォーム固有のAPI使用例） | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- Compose Multiplatformの使用に関する具体的なガイダンスの追加（descriptionでは言及されているが本文では詳述されていない） ✓ Fixed (2026-01-22)
- Koin、SQLDelight、Ktorの基本的な設定パターンの追記（tech stackとして言及されているが詳細がない） ✓ Fixed (2026-01-22)
- プラットフォーム間でのテスト戦略の考慮点（commonTestとplatform-specific testの関係） ✓ Fixed (2026-01-22)

## 総評 (Overall Assessment)

全体として、KMP SKILLドキュメントは基本的な構造と必要な情報を適切に提供している。参照ファイル（clean-architecture.md、testing-strategy.md、coroutines.md、kmp-architecture.md）はすべて存在しており、リンク切れはない。

主要な改善点は、同じskillsディレクトリ内のAndroid/iOSアーキテクチャスキルファイルとの構造的一貫性である。特に「Naming Conventions」セクションの欠落は、プロジェクト全体でのドキュメント統一性を損なっている。

技術的な内容は正確であり、KMPの公式ドキュメントやGoogleの推奨事項と整合している。expect/actualパターンの説明は簡潔で分かりやすいが、より実践的な例を追加することで価値が向上する。

**推奨アクション**: 命名規則セクションの追加を優先的に実施し、その後、レイヤー構造テーブルとSSOT原則の追記を検討する。
