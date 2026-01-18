---
name: Kotlin Multiplatform Architecture
description: This skill should be used when implementing KMP features, creating shared modules, using expect/actual, setting up Koin/SQLDelight/Ktor, or implementing Compose Multiplatform.
---

# Kotlin Multiplatform Architecture

Kotlin 公式ドキュメントおよび Google の KMP 推奨に基づくマルチプラットフォーム開発パターン。

## 基本原則

1. **ビジネスロジックの共有** - Domain/Data Layer を shared モジュールに配置
2. **プラットフォーム固有コードの最小化** - expect/actual で抽象化
3. **単方向データフロー (UDF)** - イベントは上流へ、状態は下流へ
4. **依存関係の方向** - shared モジュールはプラットフォームに依存しない

```
Platform UI → Shared (Presentation → Domain → Data)
```

## モジュール構成

| モジュール | 責務 | 技術スタック |
|-----------|------|-------------|
| shared | ビジネスロジック全般 | Koin, Ktor, SQLDelight |
| androidApp | Android UI | Jetpack Compose |
| iosApp | iOS UI | SwiftUI / Compose MP |
| desktopApp | Desktop UI | Compose MP |

## ディレクトリ構造

```
shared/
├── commonMain/kotlin/      # 全プラットフォーム共通
│   ├── presentation/
│   ├── domain/
│   └── data/
├── androidMain/kotlin/     # Android 固有 (expect/actual)
├── iosMain/kotlin/         # iOS 固有 (expect/actual)
└── commonTest/kotlin/      # 共通テスト
```

## expect/actual パターン

```kotlin
// commonMain
expect class PlatformContext

// androidMain
actual typealias PlatformContext = android.content.Context

// iosMain
actual class PlatformContext
```

## 詳細リファレンス

より詳しい実装例やベストプラクティスは [references/ARCHITECTURE.md](references/ARCHITECTURE.md) を参照。
