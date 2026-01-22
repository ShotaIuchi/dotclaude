# Review: kmp-expect-actual.md

> Reviewed: 2026-01-22
> Original: dotclaude/references/languages/kotlin/kmp-expect-actual.md

## 概要 (Summary)

本ドキュメントは、Kotlin Multiplatform (KMP) における `expect/actual` パターンを説明するリファレンスドキュメントです。プラットフォーム固有の実装を共通インターフェースで抽象化するパターンについて、具体的なコード例（プラットフォーム情報、ネットワーク監視、UUID生成）を通じて解説しています。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [ ] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [x] **情報の正確性 (Correct information)**: 記載内容が正確
- [x] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | NetworkMonitor (common) | `Flow` 型の import 文が欠落している | `import kotlinx.coroutines.flow.Flow` を追加 | ✓ Fixed (2026-01-22) |
| 2 | NetworkMonitor (Android) | `callbackFlow` 関連の import が欠落 | `import kotlinx.coroutines.flow.callbackFlow` と `import kotlinx.coroutines.channels.awaitClose` を追加 | ✓ Fixed (2026-01-22) |
| 3 | NetworkMonitor (iOS) | `callbackFlow` 関連の import が欠落 | 同上の import を追加 | ✓ Fixed (2026-01-22) |
| 4 | NetworkMonitor (expect) | コンストラクタの定義が不一致 | expect 宣言にもコンストラクタパラメータの説明を追加するか、DI パターンを明示的に説明 | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Best Practices | 項目が4つのみで簡潔すぎる | エラーハンドリング、テスト戦略、パフォーマンス考慮点を追加 | ✓ Fixed (2026-01-22) |
| 2 | 全体 | Desktop (JVM) プラットフォームの例がない | デスクトップ向けの actual 実装例を追加 | ✓ Fixed (2026-01-22) |
| 3 | NetworkMonitor (iOS) | リソース解放が不完全 | `deinit` またはキャンセル時の `nw_path_monitor_cancel` の適切な呼び出しを説明 | ✓ Fixed (2026-01-22) |
| 4 | UUID (iOS) | 非推奨の可能性 | `NSUUID().UUIDString()` から `NSUUID().UUIDString` (プロパティアクセス) への変更を検討 | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- **型エイリアス (typealias)** を使った expect/actual パターンの説明追加
- **依存性注入 (DI)** との連携パターン（Koin での actual 提供方法）の説明
- **テストコード例** の追加（commonTest での Fake 実装サンプル）
- **@OptionalExpectation** アノテーションの説明
- **階層的マルチプラットフォーム (Hierarchical Multiplatform)** での expect/actual の扱い

## 総評 (Overall Assessment)

本ドキュメントは KMP の expect/actual パターンを理解するための良質なリファレンスです。具体的な実用例（Platform, NetworkMonitor, UUID）が含まれており、パターンの適用方法が明確に示されています。

**強み:**
- 実践的なコード例が豊富
- Android と iOS の両方の actual 実装が対比されている
- ファイルパスが明示されており、プロジェクト構造が理解しやすい

**改善が望まれる点:**
- import 文の欠落があり、コピー＆ペーストで即座に動作しない
- expect 宣言と actual 実装でコンストラクタの形状が異なる箇所がある（NetworkMonitor）
- Best Practices セクションがやや簡素

**推奨アクション:**
1. import 文を完全な形で追加する
2. NetworkMonitor の expect/actual のコンストラクタ不一致を解決または説明する
3. デスクトッププラットフォームの例を追加する

全体として **B+ (良好)** の評価です。import 文の補完と NetworkMonitor の修正により、即座に使用可能なリファレンスとなります。
