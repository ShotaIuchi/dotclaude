# Kotlin/KMP Project Conventions

公式ドキュメントを補完するプロジェクト固有の規約・パターン。

---

## ディレクトリ構造

```
shared/
├── commonMain/kotlin/{package}/
│   ├── presentation/
│   │   ├── {Feature}ViewModel.kt
│   │   └── {Feature}UiState.kt
│   ├── domain/
│   │   ├── model/
│   │   └── usecase/
│   └── data/
│       ├── repository/
│       ├── local/
│       ├── remote/
│       └── mapper/
├── androidMain/kotlin/     # Android expect/actual
├── iosMain/kotlin/         # iOS expect/actual
├── desktopMain/kotlin/     # Desktop expect/actual（オプション）
├── commonTest/kotlin/      # 共通テスト
├── androidUnitTest/kotlin/
└── iosTest/kotlin/
```

### モジュール構成

| Module | Responsibility | Tech Stack |
|--------|----------------|------------|
| `shared` | ビジネスロジック全体 | Koin, Ktor, SQLDelight |
| `androidApp` | Android UI | Jetpack Compose |
| `iosApp` | iOS UI | SwiftUI / Compose MP |
| `desktopApp` | Desktop UI（オプション） | Compose MP |

## 命名規則

### クラス/ファイル命名

| Type | Pattern | Example |
|------|---------|---------|
| SharedViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UI Event | `{Feature}Event` | `UserListEvent` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository Interface | `{Entity}Repository` | `UserRepository` |
| Repository Impl | `{Entity}RepositoryImpl` | `UserRepositoryImpl` |
| DataSource | `{Entity}{Type}DataSource` | `UserRemoteDataSource` |
| Entity (SQLDelight) | `{Entity}Entity` | `UserEntity` |
| API Response | `{Entity}Response` | `UserResponse` |
| Mapper | `{Entity}Mapper` | `UserMapper` |
| Platform Class | `Platform{Component}` | `PlatformContext`, `PlatformLogger` |
| expect/actual | `{Platform}{Feature}` | `AndroidDatabase`, `IosDatabase` |
| Koin Module | `{scope}Module` | `commonModule`, `androidModule` |

### プラットフォーム固有ファイル命名

| Platform | Suffix | Example |
|----------|--------|---------|
| Android | `.android.kt` or `androidMain/` | `DatabaseDriver.android.kt` |
| iOS | `.ios.kt` or `iosMain/` | `DatabaseDriver.ios.kt` |
| Desktop | `.desktop.kt` or `desktopMain/` | `DatabaseDriver.desktop.kt` |

## Gradle 依存関係構成

### Version Catalog (`gradle/libs.versions.toml`)

```toml
[versions]
kotlin = "2.1.0"
koin = "4.0.0"
ktor = "3.0.0"
sqldelight = "2.0.2"
coroutines = "1.9.0"
compose-multiplatform = "1.7.0"

[libraries]
koin-core = { module = "io.insert-koin:koin-core", version.ref = "koin" }
koin-compose = { module = "io.insert-koin:koin-compose", version.ref = "koin" }
ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }
ktor-client-content-negotiation = { module = "io.ktor:ktor-client-content-negotiation", version.ref = "ktor" }
sqldelight-runtime = { module = "app.cash.sqldelight:runtime", version.ref = "sqldelight" }
sqldelight-coroutines = { module = "app.cash.sqldelight:coroutines-extensions", version.ref = "sqldelight" }
```

### commonMain 依存関係パターン

```kotlin
sourceSets {
    commonMain.dependencies {
        // DI
        implementation(libs.koin.core)
        // Network
        implementation(libs.ktor.client.core)
        implementation(libs.ktor.client.content.negotiation)
        implementation(libs.ktor.serialization.kotlinx.json)
        // Database
        implementation(libs.sqldelight.runtime)
        implementation(libs.sqldelight.coroutines)
        // Coroutines
        implementation(libs.kotlinx.coroutines.core)
    }
    androidMain.dependencies {
        implementation(libs.ktor.client.okhttp)
        implementation(libs.sqldelight.android.driver)
    }
    iosMain.dependencies {
        implementation(libs.ktor.client.darwin)
        implementation(libs.sqldelight.native.driver)
    }
}
```

## エラーハンドリング

### AppException 階層

```kotlin
sealed class AppException : Exception() {
    sealed class Network : AppException() {
        data class HttpError(val code: Int, val body: String?) : Network()
        data object Timeout : Network()
        data object NoConnection : Network()
    }
    sealed class Data : AppException() {
        data class NotFound(val id: String) : Data()
        data object ParseError : Data()
    }
    sealed class Auth : AppException() {
        data object Unauthorized : Auth()
        data object SessionExpired : Auth()
    }
}
```

### DataResult 型

```kotlin
sealed interface DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>
    data class Error(val exception: AppException) : DataResult<Nothing>
    data object Loading : DataResult<Nothing>
}
```

## UDF (Unidirectional Data Flow) パターン

```
User Action → Event → ViewModel → UseCase → Repository
                         ↓
                    UiState 更新
                         ↓
                   Compose 再描画
```

- ViewModel は `StateFlow<UiState>` を公開
- Event は sealed interface で定義
- 状態更新は ViewModel 内のみで行う
