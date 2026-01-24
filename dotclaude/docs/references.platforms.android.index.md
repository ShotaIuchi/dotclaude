# Android リファレンス

## 概要

Google 公式 Android Architecture Guide に基づいた Android アプリ開発のリファレンス。
MVVM、UDF（Unidirectional Data Flow）、Repository パターンを定義。

---

## ファイル一覧と優先度

| ファイル | 説明 | 優先度 |
|----------|------|--------|
| [architecture.md](architecture.md) | Android MVVM/UDF アーキテクチャ詳細 | 公式ガイド準拠 |

---

## 外部リンク

### 公式ドキュメント（最優先）

| リンク | 説明 | 優先度 |
|--------|------|--------|
| [Android Architecture Guide](https://developer.android.com/topic/architecture) | 最重要 | 必読 |
| [Android UI Layer Guide](https://developer.android.com/topic/architecture/ui-layer) | UI設計 | 必読 |
| [Android Data Layer Guide](https://developer.android.com/topic/architecture/data-layer) | データ設計 | 必読 |
| [Android Domain Layer Guide](https://developer.android.com/topic/architecture/domain-layer) | ビジネスロジック | 推奨 |

### Jetpack ライブラリ

| リンク | 説明 |
|--------|------|
| [Jetpack Compose](https://developer.android.com/jetpack/compose) | UI フレームワーク |
| [Hilt](https://developer.android.com/training/dependency-injection/hilt-android) | DI 標準 |
| [Room](https://developer.android.com/training/data-storage/room) | データベース |

---

## 関連リファレンス

- Clean Architecture - 共通アーキテクチャ原則
- Testing Strategy - テスト戦略
- Coroutines - 非同期処理

---

## 関連スキル

- **android-architecture**: Android機能の実装、ViewModel/Repository作成、Hilt利用、Jetpack Compose、MVVM/UDFパターン時に使用
