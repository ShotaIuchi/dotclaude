# Review: kmp-camera.md

> Reviewed: 2026-01-22
> Original: dotclaude/references/languages/kotlin/kmp-camera.md

## 概要 (Summary)

本ドキュメントは、Kotlin Multiplatform (KMP) / Compose Multiplatform (CMP) でカメラ機能を実装する際のベストプラクティスガイドです。OSネイティブ機能とKMP/CMP間の役割分担を明確にし、expect/actual パターンによるプラットフォーム抽象化、ViewModel/UiState による状態管理、QR/バーコード解析、リアルタイム解析、パーミッション管理など、カメラ機能実装に必要な要素を包括的にカバーしています。

対象読者は KMP/CMP でカメラ機能を実装する開発者であり、Android (CameraX) と iOS (AVFoundation) 両プラットフォームの具体的な実装例を提供しています。

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
| 1 | iOS actual Implementation | `AVCaptureDevice.devicesWithMediaType()` は非推奨 | `AVCaptureDevice.DiscoverySession` を使用する実装例に更新 | ✓ Fixed (2026-01-22) |
| 2 | Android ImageAnalyzer | `InputImage.fromByteArray` の width/height に 0 を渡している | 実際の画像サイズを取得するか、`InputImage.fromBitmap` の使用を検討 | ✓ Fixed (2026-01-22) |
| 3 | iOS RealtimeAnalyzer | `VNImageRequestHandler` の初期化に `NSDictionary()` を使用 | `[:]` または適切なオプション辞書を使用 | ✓ Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | CameraResult.Success | `ByteArray` の `equals()` 実装がない | data class での ByteArray 使用時の注意点を追記するか、`contentEquals` の使用例を示す | ✓ Fixed (2026-01-22) |
| 2 | iOS PhotoCaptureDelegate | `photoDimensions.useContents` の使用例が不完全 | CMVideoDimensions の正しいアクセス方法を明記 | ✓ Fixed (2026-01-22) |
| 3 | Reference Links | 公式ドキュメントへのリンク | KMP Camera/Permission 関連のライブラリ（moko-permissions等）への言及を追加 | ✓ Fixed (2026-01-22) |
| 4 | エラーハンドリング | 例外処理が簡略化されている | プロダクション向けのより堅牢なエラーハンドリングパターンを追加 | ✓ Fixed (2026-01-22) |
| 5 | テスト戦略 | 「Testing strategy」セクションが簡潔 | FakeCameraController の具体的な実装例やテストコード例を追加 | ✓ Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- **CameraX 1.4+ の新機能**: 最新の CameraX バージョンで追加された機能（低遅延キャプチャ、HDR等）への対応
- **iOS 17+ の PhotoKit 連携**: 最新の iOS フレームワークとの統合パターン
- **Compose Multiplatform の Camera Composable**: CMP 側でのカメラプレビュー Composable の実装パターン（現在は expect/actual のみ）
- **Desktop/Web 対応**: KMP が対応する他プラットフォーム（JVM Desktop、JS/WASM）へのカメラ対応の考慮
- **MLKit/Vision 以外の選択肢**: ZXing など他のバーコードライブラリとの比較・選択指針

## 総評 (Overall Assessment)

本ドキュメントは、KMP/CMP でのカメラ機能実装における優れたリファレンスガイドです。

**強み:**
- 役割分担の原則が明確に示されており、設計方針を理解しやすい
- 依存関係図やディレクトリ構造が視覚的に示されている
- expect/actual パターンの具体的なコード例が Android/iOS 両方で提供されている
- Decision Criteria Table により、機能ごとの実装難易度が把握できる
- Task Breakdown for Agents セクションにより、段階的な実装が可能

**改善余地:**
- ~~一部の iOS API が非推奨になっている可能性があり、最新の API への更新が望ましい~~ ✓ Fixed
- ~~テストコードの具体例がないため、TDD アプローチを取る開発者向けの情報が不足~~ ✓ Fixed
- Compose Multiplatform でのプレビュー表示部分（actual Composable）の実装例がない

**総合評価:** 高品質なリファレンスドキュメント。実装を始める前に一読すべき内容が網羅されており、特に expect/actual パターンの理解と適用に役立つ。API の最新化とテスト例の追加により、さらに実用的なドキュメントになった。

## Fix History

| Date | Issues Fixed | Applied By |
|------|--------------|------------|
| 2026-01-22 | H1, H2, H3, M1, M2, M3, M4, M5 | doc-fixer agent |
