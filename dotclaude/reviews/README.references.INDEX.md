# Review: INDEX.md

> Reviewed: 2026-01-22
> Original: dotclaude/references/INDEX.md

## 概要 (Summary)

このドキュメントは `references/` ディレクトリ内の共有リファレンスのインデックスとして機能する。skillsから参照されるリファレンスファイルの構造、外部リンク、スキル別のリファレンスマップ、使用方法を提供している。

**目的と役割:**
- リファレンスディレクトリ全体の構造を可視化
- 各スキルがどのリファレンスを参照すべきかを明示
- 設計原則の外部リンクを一元管理
- リファレンスファイルの分類ルールを定義

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 基本的な情報は網羅されているが、実際のファイル構造との不一致がある
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい構造になっている
- [x] **一貫性 (Consistency)**: 用語・スタイルは統一されている

### 技術的正確性 (Technical Accuracy)

- [x] **情報の正確性 (Correct information)**: ディレクトリ構造が実際のファイルと一致している ✓ Fixed (2026-01-22)
- [x] **最新性 (Up-to-date content)**: Kotlin KMPファイルが反映されている ✓ Fixed (2026-01-22)

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Directory Structure (Line 9-31) | 実際のファイル構造と不一致。多数のKMPファイルが未記載 | 以下のファイルを追加: `kmp-expect-actual.md`, `kmp-di-koin.md`, `kmp-data-sqldelight.md`, `kmp-network-ktor.md`, `kmp-state-udf.md`, `kmp-error-handling.md`, `kmp-compose-ui.md`, `kmp-testing.md`, `kmp-auth.md`, `kmp-camera.md` | ✓ Fixed (2026-01-22) |
| 2 | languages/kotlin/ セクション (Line 72-76) | 実際に存在する10個のKMPファイルのうち3個のみ記載 | 全てのKMP関連ファイルをテーブルに追加する | ✓ Fixed (2026-01-22) |
| 3 | kmp-architecture リファレンスマップ (Line 111-119) | 新しいKMP参照ファイルが含まれていない | 実際のファイルに基づいてリファレンスマップを更新 | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Design Principles | 外部リンクのみで内部での補足説明がない | 各原則の簡潔な説明を追加することを検討 | ✓ Fixed (2026-01-22) |
| 2 | Reference Map by Skill | YAMLブロック内のパスが `../references/` から始まっている | パスの基準点が明確でない場合、混乱を招く可能性がある。基準の説明を追加 | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- 新しいスキルやリファレンスが追加された際の更新手順を明文化
- バージョン管理や更新履歴の記録を検討
- 自動生成スクリプトによるINDEX.mdの同期維持
- 他のプラットフォーム（例: Web, Desktop）への拡張時の構造設計

## 総評 (Overall Assessment)

INDEX.mdは全体的に良く構造化されており、リファレンスシステムの設計意図が明確に伝わる。しかし、**実際のファイル構造との同期が取れていない**点が最も重要な課題である。特にKotlin/KMP関連のファイルが大幅に増加しているにも関わらず、INDEX.mdに反映されていない。

**推奨アクション:**
1. 実際の `languages/kotlin/` ディレクトリ内のファイルをすべてINDEX.mdに反映する（高優先度）
2. `kmp-architecture` スキルのリファレンスマップを更新する
3. 今後の保守性向上のため、ファイル追加時のINDEX.md更新ルールを文書化する

**評価: B (良好だが改善必要)**
- 構造設計: A (優れている)
- 情報の正確性: C (不整合あり)
- 保守性: B (更新ルールの明確化が必要)
