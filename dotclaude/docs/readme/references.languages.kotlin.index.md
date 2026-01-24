# Kotlin リファレンス

## 概要

Kotlin 言語と KMP（Kotlin Multiplatform）開発のリファレンス。公式 Kotlin ドキュメントに基づいています。
Coroutines、Flow、マルチプラットフォームアーキテクチャパターンを定義しています。

---

## ファイル一覧と優先度

> **優先度凡例**: ★★★ = 必読 | ★★☆ = 推奨 | ★☆☆ = 参考

### Coroutines

| ファイル | 説明 | 優先度 |
|----------|------|--------|
| [coroutines.md](coroutines.md) | Kotlin Coroutines ベストプラクティス | ★★★ 非同期処理の基盤 |

### KMP 基盤

| ファイル | 説明 | 優先度 |
|----------|------|--------|
| [kmp-architecture.md](kmp-architecture.md) | Kotlin Multiplatform アーキテクチャ | ★★★ KMP 設計の基盤 |
| [kmp-expect-actual.md](kmp-expect-actual.md) | プラットフォーム抽象化のための expect/actual パターン | ★★★ プラットフォーム固有実装 |
| [kmp-state-udf.md](kmp-state-udf.md) | 単方向データフローと MVI パターン | ★★★ 状態管理 |
| [kmp-error-handling.md](kmp-error-handling.md) | 共通エラー型と UI エラー表示 | ★★☆ エラーハンドリングパターン |

### KMP ライブラリ

| ファイル | 説明 | 優先度 |
|----------|------|--------|
| [kmp-di-koin.md](kmp-di-koin.md) | Koin を使った依存性注入 | ★★★ DI パターン |
| [kmp-data-sqldelight.md](kmp-data-sqldelight.md) | SQLDelight によるローカルデータベース | ★★☆ データ永続化 |
| [kmp-network-ktor.md](kmp-network-ktor.md) | Ktor を使った HTTP クライアント | ★★☆ ネットワーク層 |

### KMP 機能

| ファイル | 説明 | 優先度 |
|----------|------|--------|
| [kmp-compose-ui.md](kmp-compose-ui.md) | Compose Multiplatform UI 実装 | ★★★ クロスプラットフォーム UI |
| [kmp-auth.md](kmp-auth.md) | KMP 認証ベストプラクティス | ★★★ 認証の基盤 |
| [kmp-camera.md](kmp-camera.md) | KMP カメラ実装ガイド | ★★☆ デバイス機能 |
| [kmp-testing.md](kmp-testing.md) | テスト戦略と commonTest パターン | ★★☆ テストパターン |

---

## 外部リンク

### 公式ドキュメント（最優先）
- [Kotlin Coroutines（公式）](https://kotlinlang.org/docs/coroutines-overview.html) - ★★★ 非同期処理
- [Kotlin Flow（公式）](https://kotlinlang.org/docs/flow.html) - ★★★ リアクティブストリーム
- [Kotlin Multiplatform（公式）](https://kotlinlang.org/docs/multiplatform.html) - ★★★ KMP 基礎

### マルチプラットフォーム
- [Compose Multiplatform（JetBrains）](https://www.jetbrains.com/lp/compose-multiplatform/) - ★★★ クロスプラットフォーム UI

---

## 関連リファレンス

- [clean-architecture.md](../../common/clean-architecture.md) - 共通アーキテクチャ原則
- [testing-strategy.md](../../common/testing-strategy.md) - テスト戦略

---

## 関連スキル

| スキル | 使用方法 | 説明 |
|--------|---------|------|
| android-architecture | `/android-architecture` | Android MVVM パターン（Coroutines セクション含む） |
| kmp-architecture | `/kmp-architecture` | KMP アーキテクチャパターンとベストプラクティス |
