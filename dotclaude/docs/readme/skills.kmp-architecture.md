# Kotlin Multiplatform Architecture スキル

## 概要

Kotlin 公式ドキュメントと Google の KMP 推奨に基づいたマルチプラットフォーム開発パターンのスキル。

---

## 使用場面

以下の場面で使用：

- KMP 機能の実装
- shared モジュールの作成
- expect/actual パターンの使用
- Koin/SQLDelight/Ktor のセットアップ
- Compose Multiplatform の実装

---

## 基本原則

1. **ビジネスロジックの共有** - Domain/Data Layer を shared モジュールに配置
2. **プラットフォーム固有コードの最小化** - expect/actual で抽象化
3. **Single Source of Truth (SSOT)** - shared モジュール内の Repository が SSOT
4. **Unidirectional Data Flow (UDF)** - イベントは上流へ、状態は下流へ
5. **依存方向** - shared モジュールはプラットフォームに依存しない

```
Platform UI -> Shared (Presentation -> Domain -> Data)
```

---

## モジュール構成

| モジュール | 責務 | 技術スタック |
|------------|------|-------------|
| shared | 全ビジネスロジック | Koin, Ktor, SQLDelight |
| androidApp | Android UI | Jetpack Compose |
| iosApp | iOS UI | SwiftUI / Compose MP |
| desktopApp | Desktop UI | Compose MP |

---

## ディレクトリ構成

```
shared/
├── commonMain/kotlin/      # 全プラットフォーム共通
│   ├── presentation/
│   ├── domain/
│   └── data/
├── androidMain/kotlin/     # Android固有 (expect/actual)
├── iosMain/kotlin/         # iOS固有 (expect/actual)
└── commonTest/kotlin/      # 共通テスト
```

---

## expect/actual パターン

```kotlin
// commonMain
expect class PlatformContext

// androidMain
actual typealias PlatformContext = android.content.Context

// iosMain
actual class PlatformContext(val nsObject: platform.darwin.NSObject? = null)
```

---

## 命名規則

| 種類 | パターン | 例 |
|------|----------|-----|
| SharedViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository | `{Entity}Repository` | `UserRepository` |
| Platform Class | `Platform{Component}` | `PlatformContext` |

---

## 使用例

### Koin DI

```kotlin
// commonMain
val commonModule = module {
    single { UserRepository(get()) }
    factory { GetUsersUseCase(get()) }
}

// androidMain
val androidModule = module {
    single<DatabaseDriver> { AndroidSqliteDriver(Database.Schema, get(), "app.db") }
}

// iosMain
val iosModule = module {
    single<DatabaseDriver> { NativeSqliteDriver(Database.Schema, "app.db") }
}
```

### Compose Multiplatform

```kotlin
// commonMain - 共有UI
@Composable
fun UserListScreen(viewModel: UserListViewModel) {
    val state by viewModel.uiState.collectAsState()
    // Shared composable implementation
}
```

---

## テスト戦略

| テスト種類 | 場所 | 目的 |
|------------|------|------|
| Unit Tests | commonTest | 共有ビジネスロジック |
| Platform Tests | androidTest/iosTest | プラットフォーム固有実装 |
| Integration Tests | commonTest | Repository と DataSource の連携 |

---

## 詳細リファレンス

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
- [Kotlin Coroutines Guide](../../references/languages/kotlin/coroutines.md)
- [KMP Architecture Details](../../references/languages/kotlin/kmp-architecture.md)
