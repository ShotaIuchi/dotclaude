# Kotlin Multiplatform Architecture Guide

Kotlin 公式ドキュメントおよび Google の KMP 推奨に基づく、マルチプラットフォーム開発のベストプラクティス集。

---

## 目次

1. [アーキテクチャ概要](#アーキテクチャ概要)
2. [プロジェクト構成](#プロジェクト構成)
3. [共通モジュール (shared)](#共通モジュール-shared)
4. [ディレクトリ構造](#ディレクトリ構造)
5. [命名規則](#命名規則)
6. [ベストプラクティス一覧](#ベストプラクティス一覧)

### 詳細ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [kmp-expect-actual.md](./kmp-expect-actual.md) | expect/actual パターン |
| [kmp-di-koin.md](./kmp-di-koin.md) | 依存性注入 (Koin) |
| [kmp-data-sqldelight.md](./kmp-data-sqldelight.md) | データ永続化 (SQLDelight) |
| [kmp-network-ktor.md](./kmp-network-ktor.md) | ネットワーク (Ktor) |
| [kmp-state-udf.md](./kmp-state-udf.md) | 状態管理と UDF |
| [kmp-compose-ui.md](./kmp-compose-ui.md) | Compose Multiplatform |
| [kmp-error-handling.md](./kmp-error-handling.md) | エラーハンドリング |
| [kmp-testing.md](./kmp-testing.md) | テスト戦略 |

---

## アーキテクチャ概要

### 基本原則

1. **ビジネスロジックの共有**
   - Domain Layer と Data Layer を共通モジュール (shared) に配置
   - UI ロジック（ViewModel）も可能な限り共有

2. **プラットフォーム固有コードの最小化**
   - expect/actual で抽象化し、プラットフォーム依存を限定
   - UI は各プラットフォームのネイティブ、または Compose Multiplatform

3. **単方向データフロー (UDF)**
   - イベントは上流へ（UI → ViewModel → Repository）
   - 状態は下流へ（Repository → ViewModel → UI）

4. **依存関係の方向**
   - shared モジュールはプラットフォームモジュールに依存しない
   - プラットフォームモジュールが shared に依存

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Platform UI Layer                                │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │   Android (Compose)  │        │   iOS (SwiftUI)      │          │
│  │   / Compose MP       │        │   / Compose MP       │          │
│  └──────────────────────┘        └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Shared Module                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                        │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   ViewModel (commonMain)                             │    │   │
│  │  │   - UI State 管理                                    │    │   │
│  │  │   - UseCase 呼び出し                                 │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     Domain Layer                             │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   UseCase / Model (commonMain)                       │    │   │
│  │  │   - ビジネスロジック                                   │    │   │
│  │  │   - ドメインモデル                                     │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      Data Layer                              │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   Repository (commonMain)                            │    │   │
│  │  │   - データアクセスの抽象化                             │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │           │                              │                   │   │
│  │           ▼                              ▼                   │   │
│  │  ┌─────────────────┐          ┌─────────────────┐           │   │
│  │  │ Local DataSource│          │Remote DataSource│           │   │
│  │  │  (SQLDelight)   │          │    (Ktor)       │           │   │
│  │  └─────────────────┘          └─────────────────┘           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## プロジェクト構成

### Source Set 階層

```
shared/
├── commonMain/              # 全プラットフォーム共通
│   └── kotlin/
│
├── commonTest/              # 共通テスト
│   └── kotlin/
│
├── androidMain/             # Android 固有
│   └── kotlin/
│
├── androidUnitTest/         # Android テスト
│   └── kotlin/
│
├── iosMain/                 # iOS 共通（ARM64 + X64）
│   └── kotlin/
│
├── iosArm64Main/            # iOS ARM64（実機）
├── iosX64Main/              # iOS X64（シミュレータ）
├── iosSimulatorArm64Main/   # iOS Simulator ARM64（M1/M2 Mac）
│
└── desktopMain/             # Desktop（JVM）固有
    └── kotlin/
```

### build.gradle.kts 設定

```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidLibrary)
    alias(libs.plugins.sqldelight)
    alias(libs.plugins.kotlinSerialization)
}

kotlin {
    // Android ターゲット
    androidTarget {
        compilations.all {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }

    // iOS ターゲット
    listOf(
        iosX64(),
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "Shared"
            isStatic = true
        }
    }

    // Desktop ターゲット（オプション）
    jvm("desktop")

    sourceSets {
        commonMain.dependencies {
            // Coroutines
            implementation(libs.kotlinx.coroutines.core)

            // Ktor（HTTP クライアント）
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)

            // SQLDelight
            implementation(libs.sqldelight.runtime)
            implementation(libs.sqldelight.coroutines.extensions)

            // Koin（DI）
            implementation(libs.koin.core)

            // DateTime
            implementation(libs.kotlinx.datetime)
        }

        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.kotlinx.coroutines.test)
        }

        androidMain.dependencies {
            // Android 固有の Ktor エンジン
            implementation(libs.ktor.client.okhttp)

            // SQLDelight Android ドライバー
            implementation(libs.sqldelight.android.driver)

            // Koin Android
            implementation(libs.koin.android)
        }

        iosMain.dependencies {
            // iOS 固有の Ktor エンジン
            implementation(libs.ktor.client.darwin)

            // SQLDelight iOS ドライバー
            implementation(libs.sqldelight.native.driver)
        }

        val desktopMain by getting {
            dependencies {
                implementation(libs.ktor.client.cio)
                implementation(libs.sqldelight.sqlite.driver)
            }
        }
    }
}
```

### 依存バージョン管理

> **Note**: 各ライブラリの最新 stable バージョンは公式サイトを参照してください:
> - [Kotlin Releases](https://kotlinlang.org/docs/releases.html)
> - [Ktor Releases](https://ktor.io/changelog/)
> - [SQLDelight Releases](https://github.com/cashapp/sqldelight/releases)
> - [Koin Releases](https://github.com/InsertKoinIO/koin/releases)
> - [kotlinx.coroutines Releases](https://github.com/Kotlin/kotlinx.coroutines/releases)
> - [kotlinx.datetime Releases](https://github.com/Kotlin/kotlinx-datetime/releases)
> - [kotlinx.serialization Releases](https://github.com/Kotlin/kotlinx.serialization/releases)

`libs.versions.toml` の基本構造:

```toml
[versions]
kotlin = "..."               # 最新の stable を参照
kotlinx-coroutines = "..."
kotlinx-datetime = "..."
kotlinx-serialization = "..."
ktor = "..."
sqldelight = "..."
koin = "..."

[libraries]
# Coroutines
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "kotlinx-coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "kotlinx-coroutines" }

# Ktor
ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }
ktor-client-okhttp = { module = "io.ktor:ktor-client-okhttp", version.ref = "ktor" }
ktor-client-darwin = { module = "io.ktor:ktor-client-darwin", version.ref = "ktor" }
ktor-client-cio = { module = "io.ktor:ktor-client-cio", version.ref = "ktor" }
ktor-client-content-negotiation = { module = "io.ktor:ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { module = "io.ktor:ktor-serialization-kotlinx-json", version.ref = "ktor" }

# SQLDelight
sqldelight-runtime = { module = "app.cash.sqldelight:runtime", version.ref = "sqldelight" }
sqldelight-coroutines-extensions = { module = "app.cash.sqldelight:coroutines-extensions", version.ref = "sqldelight" }
sqldelight-android-driver = { module = "app.cash.sqldelight:android-driver", version.ref = "sqldelight" }
sqldelight-native-driver = { module = "app.cash.sqldelight:native-driver", version.ref = "sqldelight" }
sqldelight-sqlite-driver = { module = "app.cash.sqldelight:sqlite-driver", version.ref = "sqldelight" }

# Koin
koin-core = { module = "io.insert-koin:koin-core", version.ref = "koin" }
koin-android = { module = "io.insert-koin:koin-android", version.ref = "koin" }

# DateTime
kotlinx-datetime = { module = "org.jetbrains.kotlinx:kotlinx-datetime", version.ref = "kotlinx-datetime" }

[plugins]
kotlinMultiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
kotlinSerialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
sqldelight = { id = "app.cash.sqldelight", version.ref = "sqldelight" }
```

---

## 共通モジュール (shared)

### Domain Layer

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/User.kt

/**
 * ドメインモデル（ビジネスロジックを含む）
 */
data class User(
    val id: String,
    val name: String,
    val email: String,
    val joinedAt: Instant,
    val status: UserStatus
) {
    // ドメインロジック
    val isActive: Boolean
        get() = status == UserStatus.ACTIVE

    fun canPost(): Boolean {
        return isActive && !isBanned()
    }

    private fun isBanned(): Boolean {
        return status == UserStatus.BANNED
    }
}

enum class UserStatus {
    ACTIVE, INACTIVE, BANNED
}
```

```kotlin
// commonMain/kotlin/com/example/shared/domain/repository/UserRepository.kt

/**
 * ユーザーリポジトリのインターフェース
 *
 * Domain 層はこのインターフェースに依存
 */
interface UserRepository {
    fun getUsers(): Flow<List<User>>
    fun getUser(userId: String): Flow<User>
    suspend fun createUser(user: User): Result<User>
    suspend fun updateUser(user: User): Result<Unit>
    suspend fun deleteUser(userId: String): Result<Unit>
}
```

```kotlin
// commonMain/kotlin/com/example/shared/domain/usecase/GetUsersUseCase.kt

/**
 * ユーザー一覧取得の UseCase
 *
 * 単一のビジネスロジックをカプセル化
 */
class GetUsersUseCase(
    private val userRepository: UserRepository,
    private val analyticsRepository: AnalyticsRepository
) {
    /**
     * ユーザー一覧を取得する
     *
     * @return ユーザー一覧の Flow
     */
    operator fun invoke(): Flow<List<User>> {
        return userRepository.getUsers()
            .onEach { users ->
                // 副作用（アナリティクス送信など）
                analyticsRepository.logUserListViewed(users.size)
            }
    }
}
```

### Data Layer

```kotlin
// commonMain/kotlin/com/example/shared/data/repository/UserRepositoryImpl.kt

/**
 * ユーザーリポジトリの実装
 *
 * オフラインファースト戦略を採用
 */
class UserRepositoryImpl(
    private val localDataSource: UserLocalDataSource,
    private val remoteDataSource: UserRemoteDataSource,
    private val networkMonitor: NetworkMonitor
) : UserRepository {

    /**
     * ユーザー一覧を取得
     *
     * オフラインファースト：
     * 1. まずローカルキャッシュを返す
     * 2. バックグラウンドでリモートから取得
     * 3. 取得したデータでローカルを更新
     */
    override fun getUsers(): Flow<List<User>> {
        return localDataSource.getUsers()
            .onStart {
                // バックグラウンドでリモートから同期
                refreshUsersFromRemote()
            }
            .map { entities ->
                entities.map { it.toDomain() }
            }
    }

    override fun getUser(userId: String): Flow<User> {
        return localDataSource.getUser(userId)
            .onStart {
                refreshUserFromRemote(userId)
            }
            .map { it.toDomain() }
    }

    override suspend fun createUser(user: User): Result<User> {
        return runCatching {
            // リモートに作成
            val response = remoteDataSource.createUser(user.toRequest())
            val createdUser = response.toDomain()

            // ローカルにキャッシュ
            localDataSource.insertUser(createdUser.toEntity())

            createdUser
        }
    }

    override suspend fun updateUser(user: User): Result<Unit> {
        return runCatching {
            remoteDataSource.updateUser(user.id, user.toRequest())
            localDataSource.insertUser(user.toEntity())
        }
    }

    override suspend fun deleteUser(userId: String): Result<Unit> {
        return runCatching {
            remoteDataSource.deleteUser(userId)
            localDataSource.deleteUser(userId)
        }
    }

    /**
     * リモートからユーザー一覧を同期
     */
    private suspend fun refreshUsersFromRemote() {
        if (!networkMonitor.isOnline()) return

        runCatching {
            val remoteUsers = remoteDataSource.getUsers()
            localDataSource.replaceAllUsers(
                remoteUsers.map { it.toEntity() }
            )
        }.onFailure { e ->
            // ログ出力のみ、UI にはローカルデータを表示
            println("Failed to refresh users from remote: $e")
        }
    }

    private suspend fun refreshUserFromRemote(userId: String) {
        if (!networkMonitor.isOnline()) return

        runCatching {
            val remoteUser = remoteDataSource.getUser(userId)
            localDataSource.insertUser(remoteUser.toEntity())
        }.onFailure { e ->
            println("Failed to refresh user from remote: $userId, error: $e")
        }
    }
}
```

### Presentation Layer (ViewModel)

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListViewModel.kt

/**
 * ユーザー一覧画面の ViewModel
 *
 * UI 状態の管理とビジネスロジックの呼び出しを担当
 */
class UserListViewModel(
    private val getUsersUseCase: GetUsersUseCase,
    private val coroutineScope: CoroutineScope
) {
    // UI State（単一の状態オブジェクト）
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    // 一時的なイベント用（Snackbar、ナビゲーション等）
    private val _events = Channel<UserListEvent>(Channel.BUFFERED)
    val events: Flow<UserListEvent> = _events.receiveAsFlow()

    private var loadJob: Job? = null

    init {
        loadUsers()
    }

    /**
     * ユーザー一覧を読み込む
     */
    fun loadUsers() {
        loadJob?.cancel()
        loadJob = coroutineScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            getUsersUseCase()
                .catch { e ->
                    _uiState.update {
                        it.copy(isLoading = false, error = e.toUiError())
                    }
                }
                .collect { users ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            users = users.map { user -> user.toUiModel() },
                            error = null
                        )
                    }
                }
        }
    }

    /**
     * ユーザーを選択する
     */
    fun onUserClick(userId: String) {
        coroutineScope.launch {
            _events.send(UserListEvent.NavigateToDetail(userId))
        }
    }

    /**
     * リトライする
     */
    fun onRetryClick() {
        loadUsers()
    }

    /**
     * ViewModel を破棄
     */
    fun onCleared() {
        loadJob?.cancel()
    }
}
```

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListUiState.kt

/**
 * ユーザー一覧画面の UI 状態
 *
 * Immutable なデータクラスで状態を表現
 */
data class UserListUiState(
    val users: List<UserUiModel> = emptyList(),
    val isLoading: Boolean = false,
    val error: UiError? = null
) {
    // 派生プロパティ
    val isEmpty: Boolean
        get() = users.isEmpty() && !isLoading && error == null

    val showEmptyState: Boolean
        get() = isEmpty

    val showContent: Boolean
        get() = users.isNotEmpty()
}

/**
 * UI 層で使用するユーザーモデル
 */
data class UserUiModel(
    val id: String,
    val displayName: String,
    val avatarUrl: String?,
    val formattedJoinDate: String
)

/**
 * 一時的な UI イベント
 */
sealed interface UserListEvent {
    data class NavigateToDetail(val userId: String) : UserListEvent
    data class ShowSnackbar(val message: String) : UserListEvent
}
```

---

## ディレクトリ構造

### 推奨構造

```
project/
├── shared/                              # 共有モジュール
│   ├── build.gradle.kts
│   │
│   └── src/
│       ├── commonMain/
│       │   └── kotlin/com/example/shared/
│       │       │
│       │       ├── core/                # 共通コンポーネント
│       │       │   ├── di/              # DI モジュール
│       │       │   │   ├── SharedModule.kt
│       │       │   │   └── ViewModelFactory.kt
│       │       │   │
│       │       │   ├── error/           # エラー定義
│       │       │   │   └── AppException.kt
│       │       │   │
│       │       │   ├── network/         # ネットワーク
│       │       │   │   └── NetworkMonitor.kt
│       │       │   │
│       │       │   ├── platform/        # プラットフォーム抽象化
│       │       │   │   └── Platform.kt
│       │       │   │
│       │       │   └── util/            # ユーティリティ
│       │       │       ├── Uuid.kt
│       │       │       └── DateFormatter.kt
│       │       │
│       │       ├── data/                # Data Layer
│       │       │   ├── local/
│       │       │   │   ├── UserLocalDataSource.kt
│       │       │   │   └── model/
│       │       │   │       └── UserEntityData.kt
│       │       │   │
│       │       │   ├── remote/
│       │       │   │   ├── UserRemoteDataSource.kt
│       │       │   │   └── model/
│       │       │   │       ├── UserResponse.kt
│       │       │   │       └── UserRequest.kt
│       │       │   │
│       │       │   ├── repository/
│       │       │   │   └── UserRepositoryImpl.kt
│       │       │   │
│       │       │   └── mapper/
│       │       │       └── UserMapper.kt
│       │       │
│       │       ├── domain/              # Domain Layer
│       │       │   ├── model/
│       │       │   │   └── User.kt
│       │       │   │
│       │       │   ├── repository/
│       │       │   │   └── UserRepository.kt
│       │       │   │
│       │       │   └── usecase/
│       │       │       ├── GetUsersUseCase.kt
│       │       │       └── GetUserDetailUseCase.kt
│       │       │
│       │       ├── presentation/        # Presentation Layer
│       │       │   ├── model/
│       │       │   │   └── UiError.kt
│       │       │   │
│       │       │   ├── userlist/
│       │       │   │   ├── UserListViewModel.kt
│       │       │   │   └── UserListUiState.kt
│       │       │   │
│       │       │   └── userdetail/
│       │       │       ├── UserDetailViewModel.kt
│       │       │       └── UserDetailUiState.kt
│       │       │
│       │       └── ui/                  # Compose Multiplatform UI
│       │           ├── component/
│       │           │   ├── ErrorContent.kt
│       │           │   ├── EmptyContent.kt
│       │           │   └── LoadingContent.kt
│       │           │
│       │           ├── userlist/
│       │           │   └── UserListScreen.kt
│       │           │
│       │           └── theme/
│       │               └── AppTheme.kt
│       │
│       ├── commonTest/
│       │   └── kotlin/com/example/shared/
│       │       ├── domain/
│       │       │   └── usecase/
│       │       │       └── GetUsersUseCaseTest.kt
│       │       │
│       │       ├── presentation/
│       │       │   └── UserListViewModelTest.kt
│       │       │
│       │       └── test/                # テストユーティリティ
│       │           ├── FakeUserRepository.kt
│       │           ├── FakeGetUsersUseCase.kt
│       │           └── TestUtils.kt
│       │
│       ├── androidMain/
│       │   └── kotlin/com/example/shared/
│       │       ├── core/
│       │       │   ├── di/
│       │       │   │   └── PlatformModule.android.kt
│       │       │   ├── network/
│       │       │   │   └── NetworkMonitor.android.kt
│       │       │   └── platform/
│       │       │       └── Platform.android.kt
│       │       │
│       │       └── util/
│       │           └── Uuid.android.kt
│       │
│       └── iosMain/
│           └── kotlin/com/example/shared/
│               ├── core/
│               │   ├── di/
│               │   │   └── PlatformModule.ios.kt
│               │   ├── network/
│               │   │   └── NetworkMonitor.ios.kt
│               │   └── platform/
│               │       └── Platform.ios.kt
│               │
│               └── util/
│                   └── Uuid.ios.kt
│
├── androidApp/                          # Android アプリ
│   ├── build.gradle.kts
│   └── src/main/
│       ├── kotlin/com/example/android/
│       │   ├── MyApplication.kt
│       │   ├── MainActivity.kt
│       │   └── ui/
│       │       └── navigation/
│       │           └── AppNavigation.kt
│       │
│       └── res/
│
├── iosApp/                              # iOS アプリ
│   ├── iosApp.xcodeproj
│   └── Sources/
│       ├── iOSApp.swift
│       ├── ContentView.swift
│       └── View/
│           ├── UserListView.swift
│           └── UserDetailView.swift
│
├── desktopApp/                          # Desktop アプリ（オプション）
│   └── src/jvmMain/
│
└── sqldelight/                          # SQLDelight スキーマ
    └── com/example/shared/
        └── AppDatabase.sq
```

---

## 命名規則

### クラス命名

| 種類 | サフィックス | 例 |
|------|-------------|-----|
| ViewModel | ViewModel | `UserListViewModel` |
| UseCase | UseCase | `GetUsersUseCase` |
| Repository Interface | Repository | `UserRepository` |
| Repository 実装 | RepositoryImpl | `UserRepositoryImpl` |
| DataSource Interface | DataSource | `UserLocalDataSource` |
| DataSource 実装 | DataSourceImpl | `UserLocalDataSourceImpl` |
| SQLDelight Entity | Entity | `UserEntity` |
| API Response | Response | `UserResponse` |
| API Request | Request | `CreateUserRequest` |
| UI State | UiState | `UserListUiState` |
| UI Model | UiModel | `UserUiModel` |
| Event | Event | `UserListEvent` |
| Composable Screen | Screen | `UserListScreen` |
| expect 実装 | .{platform} | `Platform.android.kt`, `Platform.ios.kt` |

### 関数命名

| 種類 | パターン | 例 |
|------|---------|-----|
| データ取得（単一） | `get{Entity}` | `getUser(userId)` |
| データ取得（複数） | `get{Entity}s` / `get{Entity}List` | `getUsers()` |
| データ作成 | `create{Entity}` / `insert{Entity}` | `createUser()` |
| データ更新 | `update{Entity}` | `updateUser()` |
| データ削除 | `delete{Entity}` | `deleteUser()` |
| イベントハンドラ | `on{Event}` / `on{Event}Click` | `onUserClick()` |
| 変換 | `to{Target}` | `toDomain()`, `toEntity()`, `toUiModel()` |
| 検証 | `is{Condition}` / `has{Property}` | `isValid()`, `hasPermission()` |

### Source Set 命名

| Source Set | 用途 |
|------------|------|
| commonMain | 全プラットフォーム共通コード |
| commonTest | 共通テスト |
| androidMain | Android 固有実装 |
| iosMain | iOS 共通（全アーキテクチャ） |
| iosArm64Main | iOS ARM64（実機） |
| iosX64Main | iOS X64（Intel シミュレータ） |
| iosSimulatorArm64Main | iOS Simulator ARM64（M1/M2 Mac） |
| desktopMain | Desktop（JVM） |

---

## ベストプラクティス一覧

### 共通モジュール (shared)

- [ ] ビジネスロジック（Domain Layer）を commonMain に配置
- [ ] データアクセス（Data Layer）を commonMain に配置
- [ ] ViewModel を commonMain に配置
- [ ] プラットフォーム固有コードは expect/actual で抽象化
- [ ] UI は Compose Multiplatform または各プラットフォームネイティブ

### expect/actual

→ 詳細: [kmp-expect-actual.md](./kmp-expect-actual.md)

- [ ] プラットフォーム固有の実装は最小限に
- [ ] 共通インターフェースを先に設計
- [ ] actual 実装はプラットフォームの Best Practice に従う
- [ ] テスト用の Fake 実装を commonTest に用意

### 依存性注入 (Koin)

→ 詳細: [kmp-di-koin.md](./kmp-di-koin.md)

- [ ] 共通モジュールは sharedModule に定義
- [ ] プラットフォーム固有は platformModule に定義
- [ ] ViewModel は Factory 経由で生成
- [ ] テスト時は Fake を注入可能に

### データ永続化 (SQLDelight)

→ 詳細: [kmp-data-sqldelight.md](./kmp-data-sqldelight.md)

- [ ] スキーマは共通で定義
- [ ] Driver は各プラットフォームで実装
- [ ] トランザクションは適切に使用
- [ ] Flow で変更を監視

### ネットワーク (Ktor)

→ 詳細: [kmp-network-ktor.md](./kmp-network-ktor.md)

- [ ] HttpClient は DI で管理
- [ ] エンジンはプラットフォーム別に設定
- [ ] エラーハンドリングを統一
- [ ] Serialization は kotlinx-serialization を使用

### 状態管理

→ 詳細: [kmp-state-udf.md](./kmp-state-udf.md)

- [ ] UI State は単一の data class で管理
- [ ] StateFlow で状態を公開
- [ ] 一時的イベントは Channel を使用
- [ ] UDF（単方向データフロー）を遵守

### テスト

→ 詳細: [kmp-testing.md](./kmp-testing.md)

- [ ] commonTest でユニットテストを実装
- [ ] Fake を優先、Mock は最小限
- [ ] runTest で Coroutine テスト
- [ ] テストユーティリティを共通化

### エラーハンドリング

→ 詳細: [kmp-error-handling.md](./kmp-error-handling.md)

- [ ] AppException の階層を定義
- [ ] プラットフォーム共通のエラーマッピング
- [ ] UI 用エラーモデルに変換
- [ ] リトライ機構の実装

---

## 参考リンク

### 公式ドキュメント

- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html)
- [Kotlin Multiplatform: Project structure](https://kotlinlang.org/docs/multiplatform-discover-project.html)
- [expect/actual declarations](https://kotlinlang.org/docs/multiplatform-expect-actual.html)
- [Compose Multiplatform](https://www.jetbrains.com/lp/compose-multiplatform/)

### 公式サンプル

- [Kotlin Multiplatform Samples](https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-samples.html)
- [KMM Sample (Kotlin Multiplatform Mobile)](https://github.com/Kotlin/kmm-basic-sample)
- [Compose Multiplatform Template](https://github.com/JetBrains/compose-multiplatform-template)

### ライブラリ

- [Ktor](https://ktor.io/docs/getting-started-ktor-client.html)
- [SQLDelight](https://cashapp.github.io/sqldelight/)
- [Koin](https://insert-koin.io/docs/reference/koin-mp/kmp/)
- [kotlinx-datetime](https://github.com/Kotlin/kotlinx-datetime)
- [kotlinx-serialization](https://github.com/Kotlin/kotlinx.serialization)

### Google 公式

- [Android Developers: Kotlin Multiplatform](https://developer.android.com/kotlin/multiplatform)
