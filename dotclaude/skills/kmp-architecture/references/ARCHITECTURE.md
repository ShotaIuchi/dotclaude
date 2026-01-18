# Kotlin Multiplatform Architecture Guide

Kotlin 公式ドキュメントおよび Google の KMP 推奨に基づく、マルチプラットフォーム開発のベストプラクティス集。

---

## 目次

1. [アーキテクチャ概要](#アーキテクチャ概要)
2. [プロジェクト構成](#プロジェクト構成)
3. [共通モジュール (shared)](#共通モジュール-shared)
4. [expect/actual パターン](#expectactual-パターン)
5. [依存性注入 (Koin)](#依存性注入-koin)
6. [データ永続化 (SQLDelight)](#データ永続化-sqldelight)
7. [ネットワーク (Ktor)](#ネットワーク-ktor)
8. [状態管理と UDF](#状態管理と-udf)
9. [Compose Multiplatform](#compose-multiplatform)
10. [エラーハンドリング](#エラーハンドリング)
11. [テスト戦略](#テスト戦略)
12. [ディレクトリ構造](#ディレクトリ構造)
13. [命名規則](#命名規則)
14. [ベストプラクティス一覧](#ベストプラクティス一覧)

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

### 依存バージョン管理 (libs.versions.toml)

```toml
[versions]
kotlin = "2.0.0"
kotlinx-coroutines = "1.8.1"
kotlinx-datetime = "0.6.0"
kotlinx-serialization = "1.7.0"
ktor = "2.3.11"
sqldelight = "2.0.2"
koin = "3.5.6"

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

## expect/actual パターン

### プラットフォーム固有実装の抽象化

```kotlin
// commonMain/kotlin/com/example/shared/core/platform/Platform.kt

/**
 * プラットフォーム情報（expect 宣言）
 */
expect class Platform() {
    val name: String
    val version: String
}

/**
 * プラットフォーム固有のユーティリティ
 */
expect fun getPlatformName(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/platform/Platform.android.kt

/**
 * Android 実装
 */
actual class Platform actual constructor() {
    actual val name: String = "Android"
    actual val version: String = "${android.os.Build.VERSION.SDK_INT}"
}

actual fun getPlatformName(): String = "Android ${android.os.Build.VERSION.SDK_INT}"
```

```kotlin
// iosMain/kotlin/com/example/shared/core/platform/Platform.ios.kt

import platform.UIKit.UIDevice

/**
 * iOS 実装
 */
actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName()
    actual val version: String = UIDevice.currentDevice.systemVersion
}

actual fun getPlatformName(): String =
    "${UIDevice.currentDevice.systemName()} ${UIDevice.currentDevice.systemVersion}"
```

### ネットワーク監視

```kotlin
// commonMain/kotlin/com/example/shared/core/network/NetworkMonitor.kt

/**
 * ネットワーク状態監視（expect 宣言）
 */
expect class NetworkMonitor {
    fun isOnline(): Boolean
    fun observeNetworkState(): Flow<Boolean>
}
```

```kotlin
// androidMain/kotlin/com/example/shared/core/network/NetworkMonitor.android.kt

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest

/**
 * Android 実装
 */
actual class NetworkMonitor(
    private val context: Context
) {
    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    actual fun isOnline(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    actual fun observeNetworkState(): Flow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(true)
            }

            override fun onLost(network: Network) {
                trySend(false)
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(request, callback)

        // 初期状態
        trySend(isOnline())

        awaitClose {
            connectivityManager.unregisterNetworkCallback(callback)
        }
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/core/network/NetworkMonitor.ios.kt

import platform.Network.*
import platform.darwin.dispatch_get_main_queue

/**
 * iOS 実装
 */
actual class NetworkMonitor {
    private val monitor = nw_path_monitor_create()
    private var currentPath: nw_path_t? = null

    init {
        nw_path_monitor_set_update_handler(monitor) { path ->
            currentPath = path
        }
        nw_path_monitor_set_queue(monitor, dispatch_get_main_queue())
        nw_path_monitor_start(monitor)
    }

    actual fun isOnline(): Boolean {
        val path = currentPath ?: return false
        return nw_path_get_status(path) == nw_path_status_satisfied
    }

    actual fun observeNetworkState(): Flow<Boolean> = callbackFlow {
        nw_path_monitor_set_update_handler(monitor) { path ->
            val isConnected = nw_path_get_status(path) == nw_path_status_satisfied
            trySend(isConnected)
        }

        awaitClose {
            nw_path_monitor_cancel(monitor)
        }
    }
}
```

### UUID 生成

```kotlin
// commonMain/kotlin/com/example/shared/core/util/Uuid.kt

/**
 * UUID 生成（expect 宣言）
 */
expect fun randomUUID(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/util/Uuid.android.kt

import java.util.UUID

/**
 * Android 実装
 */
actual fun randomUUID(): String = UUID.randomUUID().toString()
```

```kotlin
// iosMain/kotlin/com/example/shared/core/util/Uuid.ios.kt

import platform.Foundation.NSUUID

/**
 * iOS 実装
 */
actual fun randomUUID(): String = NSUUID().UUIDString()
```

---

## 依存性注入 (Koin)

### 共通モジュール定義

```kotlin
// commonMain/kotlin/com/example/shared/di/SharedModule.kt

/**
 * 共通 DI モジュール
 */
val sharedModule = module {

    // Repository
    single<UserRepository> {
        UserRepositoryImpl(
            localDataSource = get(),
            remoteDataSource = get(),
            networkMonitor = get()
        )
    }

    single<AnalyticsRepository> {
        AnalyticsRepositoryImpl()
    }

    // UseCase
    factory {
        GetUsersUseCase(
            userRepository = get(),
            analyticsRepository = get()
        )
    }

    factory {
        GetUserDetailUseCase(
            userRepository = get(),
            postRepository = get()
        )
    }

    // DataSource
    single<UserRemoteDataSource> {
        UserRemoteDataSourceImpl(httpClient = get())
    }
}

/**
 * プラットフォーム固有の DI モジュール（expect）
 */
expect val platformModule: Module
```

```kotlin
// androidMain/kotlin/com/example/shared/di/PlatformModule.android.kt

/**
 * Android 固有 DI モジュール
 */
actual val platformModule: Module = module {

    // Ktor HttpClient（OkHttp エンジン）
    single {
        HttpClient(OkHttp) {
            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                    isLenient = true
                })
            }
            install(Logging) {
                level = LogLevel.BODY
            }
        }
    }

    // SQLDelight Database Driver
    single<SqlDriver> {
        AndroidSqliteDriver(
            schema = AppDatabase.Schema,
            context = get(),
            name = "app.db"
        )
    }

    // SQLDelight Database
    single {
        AppDatabase(get())
    }

    // Local DataSource
    single<UserLocalDataSource> {
        UserLocalDataSourceImpl(database = get())
    }

    // Network Monitor
    single {
        NetworkMonitor(context = get())
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/di/PlatformModule.ios.kt

/**
 * iOS 固有 DI モジュール
 */
actual val platformModule: Module = module {

    // Ktor HttpClient（Darwin エンジン）
    single {
        HttpClient(Darwin) {
            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                    isLenient = true
                })
            }
        }
    }

    // SQLDelight Database Driver
    single<SqlDriver> {
        NativeSqliteDriver(
            schema = AppDatabase.Schema,
            name = "app.db"
        )
    }

    // SQLDelight Database
    single {
        AppDatabase(get())
    }

    // Local DataSource
    single<UserLocalDataSource> {
        UserLocalDataSourceImpl(database = get())
    }

    // Network Monitor
    single {
        NetworkMonitor()
    }
}
```

### Koin 初期化

```kotlin
// commonMain/kotlin/com/example/shared/di/KoinInitializer.kt

/**
 * Koin 初期化
 */
fun initKoin(appDeclaration: KoinAppDeclaration = {}) =
    startKoin {
        appDeclaration()
        modules(
            sharedModule,
            platformModule
        )
    }

// iOS 用ヘルパー
fun initKoinIos() = initKoin()
```

```kotlin
// Android での初期化（Application クラス）
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        initKoin {
            androidContext(this@MyApplication)
        }
    }
}
```

```swift
// iOS での初期化（AppDelegate または App）
@main
struct MyApp: App {
    init() {
        KoinInitializerKt.doInitKoinIos()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### ViewModel の取得

```kotlin
// commonMain/kotlin/com/example/shared/di/ViewModelFactory.kt

/**
 * ViewModel ファクトリ
 *
 * プラットフォーム間で統一的に ViewModel を取得
 */
class ViewModelFactory : KoinComponent {

    fun createUserListViewModel(
        coroutineScope: CoroutineScope
    ): UserListViewModel {
        return UserListViewModel(
            getUsersUseCase = get(),
            coroutineScope = coroutineScope
        )
    }

    fun createUserDetailViewModel(
        userId: String,
        coroutineScope: CoroutineScope
    ): UserDetailViewModel {
        return UserDetailViewModel(
            userId = userId,
            getUserDetailUseCase = get(),
            coroutineScope = coroutineScope
        )
    }
}
```

---

## データ永続化 (SQLDelight)

### スキーマ定義

```sql
-- shared/src/commonMain/sqldelight/com/example/shared/AppDatabase.sq

-- ユーザーテーブル
CREATE TABLE UserEntity (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    joined_at INTEGER NOT NULL,
    status TEXT NOT NULL
);

-- ユーザー一覧取得
getUsers:
SELECT * FROM UserEntity
ORDER BY name ASC;

-- 単一ユーザー取得
getUser:
SELECT * FROM UserEntity
WHERE id = ?;

-- ユーザー挿入/更新
insertUser:
INSERT OR REPLACE INTO UserEntity(id, name, email, joined_at, status)
VALUES (?, ?, ?, ?, ?);

-- 全ユーザー削除
deleteAllUsers:
DELETE FROM UserEntity;

-- 単一ユーザー削除
deleteUser:
DELETE FROM UserEntity
WHERE id = ?;
```

### LocalDataSource 実装

```kotlin
// commonMain/kotlin/com/example/shared/data/local/UserLocalDataSource.kt

/**
 * ユーザーローカルデータソース
 */
interface UserLocalDataSource {
    fun getUsers(): Flow<List<UserEntity>>
    fun getUser(userId: String): Flow<UserEntity>
    suspend fun insertUser(user: UserEntity)
    suspend fun insertUsers(users: List<UserEntity>)
    suspend fun replaceAllUsers(users: List<UserEntity>)
    suspend fun deleteUser(userId: String)
}

/**
 * SQLDelight を使用したローカルデータソース実装
 */
class UserLocalDataSourceImpl(
    private val database: AppDatabase
) : UserLocalDataSource {

    private val queries = database.appDatabaseQueries

    override fun getUsers(): Flow<List<UserEntity>> {
        return queries.getUsers()
            .asFlow()
            .mapToList(Dispatchers.IO)
    }

    override fun getUser(userId: String): Flow<UserEntity> {
        return queries.getUser(userId)
            .asFlow()
            .mapToOne(Dispatchers.IO)
    }

    override suspend fun insertUser(user: UserEntity) {
        withContext(Dispatchers.IO) {
            queries.insertUser(
                id = user.id,
                name = user.name,
                email = user.email,
                joined_at = user.joinedAt,
                status = user.status
            )
        }
    }

    override suspend fun insertUsers(users: List<UserEntity>) {
        withContext(Dispatchers.IO) {
            queries.transaction {
                users.forEach { user ->
                    queries.insertUser(
                        id = user.id,
                        name = user.name,
                        email = user.email,
                        joined_at = user.joinedAt,
                        status = user.status
                    )
                }
            }
        }
    }

    override suspend fun replaceAllUsers(users: List<UserEntity>) {
        withContext(Dispatchers.IO) {
            queries.transaction {
                queries.deleteAllUsers()
                users.forEach { user ->
                    queries.insertUser(
                        id = user.id,
                        name = user.name,
                        email = user.email,
                        joined_at = user.joinedAt,
                        status = user.status
                    )
                }
            }
        }
    }

    override suspend fun deleteUser(userId: String) {
        withContext(Dispatchers.IO) {
            queries.deleteUser(userId)
        }
    }
}
```

### Entity マッピング

```kotlin
// commonMain/kotlin/com/example/shared/data/mapper/UserMapper.kt

/**
 * SQLDelight Entity → Domain
 */
fun UserEntity.toDomain(): User {
    return User(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.fromEpochMilliseconds(joined_at),
        status = UserStatus.valueOf(status)
    )
}

/**
 * Domain → SQLDelight Entity
 *
 * SQLDelight の生成する Entity は data class ではないため、
 * 別途 data class を定義することもある
 */
fun User.toEntity(): com.example.shared.data.model.UserEntityData {
    return UserEntityData(
        id = id,
        name = name,
        email = email,
        joinedAt = joinedAt.toEpochMilliseconds(),
        status = status.name
    )
}

/**
 * Entity 用データクラス（挿入時に使用）
 */
data class UserEntityData(
    val id: String,
    val name: String,
    val email: String,
    val joinedAt: Long,
    val status: String
)
```

---

## ネットワーク (Ktor)

### API クライアント

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiClient.kt

/**
 * Ktor を使用した API クライアント
 */
class ApiClient(
    private val httpClient: HttpClient,
    private val baseUrl: String
) {
    /**
     * GET リクエスト
     */
    suspend inline fun <reified T> get(
        endpoint: String,
        params: Map<String, String> = emptyMap()
    ): T {
        return httpClient.get(baseUrl + endpoint) {
            params.forEach { (key, value) ->
                parameter(key, value)
            }
        }.body()
    }

    /**
     * POST リクエスト
     */
    suspend inline fun <reified T, reified R> post(
        endpoint: String,
        body: T
    ): R {
        return httpClient.post(baseUrl + endpoint) {
            contentType(ContentType.Application.Json)
            setBody(body)
        }.body()
    }

    /**
     * PUT リクエスト
     */
    suspend inline fun <reified T, reified R> put(
        endpoint: String,
        body: T
    ): R {
        return httpClient.put(baseUrl + endpoint) {
            contentType(ContentType.Application.Json)
            setBody(body)
        }.body()
    }

    /**
     * DELETE リクエスト
     */
    suspend fun delete(endpoint: String) {
        httpClient.delete(baseUrl + endpoint)
    }
}
```

### RemoteDataSource 実装

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/UserRemoteDataSource.kt

/**
 * ユーザーリモートデータソース
 */
interface UserRemoteDataSource {
    suspend fun getUsers(): List<UserResponse>
    suspend fun getUser(userId: String): UserResponse
    suspend fun createUser(request: CreateUserRequest): UserResponse
    suspend fun updateUser(userId: String, request: UpdateUserRequest): UserResponse
    suspend fun deleteUser(userId: String)
}

/**
 * Ktor を使用したリモートデータソース実装
 */
class UserRemoteDataSourceImpl(
    private val httpClient: HttpClient
) : UserRemoteDataSource {

    private val baseUrl = "https://api.example.com"

    override suspend fun getUsers(): List<UserResponse> {
        return httpClient.get("$baseUrl/users").body()
    }

    override suspend fun getUser(userId: String): UserResponse {
        return httpClient.get("$baseUrl/users/$userId").body()
    }

    override suspend fun createUser(request: CreateUserRequest): UserResponse {
        return httpClient.post("$baseUrl/users") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }.body()
    }

    override suspend fun updateUser(
        userId: String,
        request: UpdateUserRequest
    ): UserResponse {
        return httpClient.put("$baseUrl/users/$userId") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }.body()
    }

    override suspend fun deleteUser(userId: String) {
        httpClient.delete("$baseUrl/users/$userId")
    }
}
```

### API モデル

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/model/UserResponse.kt

/**
 * API レスポンスモデル
 */
@Serializable
data class UserResponse(
    val id: String,
    val name: String,
    val email: String,
    @SerialName("joined_at")
    val joinedAt: String,
    val status: String
)

/**
 * ユーザー作成リクエスト
 */
@Serializable
data class CreateUserRequest(
    val name: String,
    val email: String
)

/**
 * ユーザー更新リクエスト
 */
@Serializable
data class UpdateUserRequest(
    val name: String,
    val email: String
)

/**
 * Response → Domain 変換
 */
fun UserResponse.toDomain(): User {
    return User(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.parse(joinedAt),
        status = UserStatus.valueOf(status.uppercase())
    )
}

/**
 * Response → Entity 変換
 */
fun UserResponse.toEntity(): UserEntityData {
    return UserEntityData(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.parse(joinedAt).toEpochMilliseconds(),
        status = status.uppercase()
    )
}

/**
 * Domain → Request 変換
 */
fun User.toRequest(): CreateUserRequest {
    return CreateUserRequest(
        name = name,
        email = email
    )
}
```

---

## 状態管理と UDF

### 単方向データフロー (UDF) の原則

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│   ┌─────────┐                                         │
│   │  State  │◄───────────────────────────────────┐   │
│   └────┬────┘                                    │   │
│        │                                         │   │
│        ▼                                         │   │
│   ┌─────────┐      ┌─────────┐      ┌─────────┐ │   │
│   │   UI    │─────►│  Intent │─────►│ Reduce  │─┘   │
│   └─────────┘      └─────────┘      └─────────┘     │
│                                                      │
│        ▲                                             │
│        │                                             │
│   ┌────┴────┐                                        │
│   │ Side    │◄───────────────────────────────────────┘
│   │ Effects │
│   └─────────┘
│
└────────────────────────────────────────────────────────┘
```

### MVI パターン実装

```kotlin
// commonMain/kotlin/com/example/shared/presentation/mvi/MviViewModel.kt

/**
 * MVI ベースの ViewModel 基底クラス
 */
abstract class MviViewModel<State, Intent, Effect>(
    initialState: State,
    private val coroutineScope: CoroutineScope
) {
    private val _state = MutableStateFlow(initialState)
    val state: StateFlow<State> = _state.asStateFlow()

    private val _effects = Channel<Effect>(Channel.BUFFERED)
    val effects: Flow<Effect> = _effects.receiveAsFlow()

    /**
     * Intent を処理する
     */
    fun dispatch(intent: Intent) {
        coroutineScope.launch {
            handleIntent(intent)
        }
    }

    /**
     * Intent のハンドリング（サブクラスで実装）
     */
    protected abstract suspend fun handleIntent(intent: Intent)

    /**
     * State を更新する
     */
    protected fun updateState(reducer: (State) -> State) {
        _state.update(reducer)
    }

    /**
     * Side Effect を発行する
     */
    protected suspend fun emitEffect(effect: Effect) {
        _effects.send(effect)
    }
}
```

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListContract.kt

/**
 * ユーザー一覧画面の Contract
 */
object UserListContract {

    /**
     * UI State
     */
    data class State(
        val users: List<UserUiModel> = emptyList(),
        val isLoading: Boolean = false,
        val error: UiError? = null
    ) {
        val isEmpty: Boolean
            get() = users.isEmpty() && !isLoading && error == null
    }

    /**
     * User Intent（ユーザーアクション）
     */
    sealed interface Intent {
        object LoadUsers : Intent
        object Refresh : Intent
        data class UserClicked(val userId: String) : Intent
        object RetryClicked : Intent
    }

    /**
     * Side Effect（一度きりのイベント）
     */
    sealed interface Effect {
        data class NavigateToDetail(val userId: String) : Effect
        data class ShowSnackbar(val message: String) : Effect
    }
}
```

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListMviViewModel.kt

/**
 * MVI パターンの ViewModel 実装
 */
class UserListMviViewModel(
    private val getUsersUseCase: GetUsersUseCase,
    coroutineScope: CoroutineScope
) : MviViewModel<
    UserListContract.State,
    UserListContract.Intent,
    UserListContract.Effect
>(
    initialState = UserListContract.State(),
    coroutineScope = coroutineScope
) {
    private var loadJob: Job? = null

    init {
        dispatch(UserListContract.Intent.LoadUsers)
    }

    override suspend fun handleIntent(intent: UserListContract.Intent) {
        when (intent) {
            is UserListContract.Intent.LoadUsers,
            is UserListContract.Intent.Refresh,
            is UserListContract.Intent.RetryClicked -> loadUsers()

            is UserListContract.Intent.UserClicked -> {
                emitEffect(UserListContract.Effect.NavigateToDetail(intent.userId))
            }
        }
    }

    private suspend fun loadUsers() {
        loadJob?.cancel()
        updateState { it.copy(isLoading = true, error = null) }

        getUsersUseCase()
            .catch { e ->
                updateState { it.copy(isLoading = false, error = e.toUiError()) }
            }
            .collect { users ->
                updateState {
                    it.copy(
                        isLoading = false,
                        users = users.map { user -> user.toUiModel() }
                    )
                }
            }
    }
}
```

---

## Compose Multiplatform

### 共通 UI コンポーネント

```kotlin
// commonMain/kotlin/com/example/shared/ui/userlist/UserListScreen.kt

/**
 * ユーザー一覧画面（Compose Multiplatform）
 */
@Composable
fun UserListScreen(
    viewModel: UserListViewModel,
    onNavigateToDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    // イベントの処理
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is UserListEvent.NavigateToDetail -> {
                    onNavigateToDetail(event.userId)
                }
                is UserListEvent.ShowSnackbar -> {
                    // Snackbar 表示
                }
            }
        }
    }

    UserListContent(
        uiState = uiState,
        onUserClick = viewModel::onUserClick,
        onRetryClick = viewModel::onRetryClick
    )
}

/**
 * ユーザー一覧のコンテンツ（プレビュー可能）
 */
@Composable
fun UserListContent(
    uiState: UserListUiState,
    onUserClick: (String) -> Unit,
    onRetryClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        when {
            uiState.isLoading -> {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            uiState.error != null -> {
                ErrorContent(
                    error = uiState.error,
                    onRetryClick = onRetryClick,
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            uiState.showEmptyState -> {
                EmptyContent(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            uiState.showContent -> {
                UserList(
                    users = uiState.users,
                    onUserClick = onUserClick
                )
            }
        }
    }
}

/**
 * ユーザーリスト
 */
@Composable
fun UserList(
    users: List<UserUiModel>,
    onUserClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(modifier = modifier) {
        items(
            items = users,
            key = { it.id }
        ) { user ->
            UserCard(
                user = user,
                onClick = { onUserClick(user.id) }
            )
        }
    }
}

/**
 * ユーザーカード
 */
@Composable
fun UserCard(
    user: UserUiModel,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = user.displayName,
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = user.formattedJoinDate,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
```

### 共通コンポーネント

```kotlin
// commonMain/kotlin/com/example/shared/ui/component/ErrorContent.kt

/**
 * エラー表示コンポーネント
 */
@Composable
fun ErrorContent(
    error: UiError,
    onRetryClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Warning,
            contentDescription = null,
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.error
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = error.message,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )

        if (error.action == ErrorAction.RETRY) {
            Spacer(modifier = Modifier.height(16.dp))

            Button(onClick = onRetryClick) {
                Text("再試行")
            }
        }
    }
}

/**
 * 空状態表示コンポーネント
 */
@Composable
fun EmptyContent(
    modifier: Modifier = Modifier,
    message: String = "データがありません"
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Inbox,
            contentDescription = null,
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * ローディングコンポーネント
 */
@Composable
fun LoadingContent(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}
```

### プラットフォーム固有 UI（iOS で SwiftUI を使う場合）

```swift
// iOS/Sources/UserListView.swift

import SwiftUI
import Shared

/**
 * SwiftUI での UserListScreen
 */
struct UserListView: View {

    @StateObject private var viewModel: UserListViewModelWrapper

    init() {
        let factory = ViewModelFactory()
        _viewModel = StateObject(wrappedValue: UserListViewModelWrapper(factory: factory))
    }

    var body: some View {
        NavigationStack {
            UserListContent(
                state: viewModel.state,
                onUserTap: viewModel.onUserClick,
                onRetryTap: viewModel.onRetryClick
            )
            .navigationTitle("ユーザー一覧")
            .navigationDestination(for: String.self) { userId in
                UserDetailView(userId: userId)
            }
        }
        .task {
            await viewModel.observeEvents()
        }
    }
}

/**
 * Kotlin ViewModel を SwiftUI でラップ
 */
@MainActor
class UserListViewModelWrapper: ObservableObject {

    @Published private(set) var state = UserListUiState(
        users: [],
        isLoading: false,
        error: nil
    )

    private let viewModel: UserListViewModel
    private var stateJob: Task<Void, Never>?

    init(factory: ViewModelFactory) {
        // MainActor で CoroutineScope を作成
        let scope = MainScope()
        viewModel = factory.createUserListViewModel(coroutineScope: scope)

        // State を監視
        observeState()
    }

    private func observeState() {
        stateJob = Task {
            for await state in viewModel.uiState {
                self.state = state
            }
        }
    }

    func observeEvents() async {
        for await event in viewModel.events {
            switch onEnum(of: event) {
            case .navigateToDetail(let e):
                // ナビゲーション処理
                break
            case .showSnackbar(let e):
                // Snackbar 表示
                break
            }
        }
    }

    func onUserClick(userId: String) {
        viewModel.onUserClick(userId: userId)
    }

    func onRetryClick() {
        viewModel.onRetryClick()
    }

    deinit {
        stateJob?.cancel()
        viewModel.onCleared()
    }
}
```

---

## エラーハンドリング

### 共通エラー型

```kotlin
// commonMain/kotlin/com/example/shared/core/error/AppException.kt

/**
 * アプリケーション例外の階層
 */
sealed class AppException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    // ネットワークエラー
    sealed class Network(message: String, cause: Throwable?) : AppException(message, cause) {
        class NoConnection(cause: Throwable? = null) : Network("No internet connection", cause)
        class Timeout(cause: Throwable? = null) : Network("Request timeout", cause)
        class Server(val code: Int, cause: Throwable? = null) : Network("Server error: $code", cause)
    }

    // データエラー
    sealed class Data(message: String, cause: Throwable?) : AppException(message, cause) {
        class NotFound(message: String = "Data not found") : Data(message, null)
        class Validation(message: String) : Data(message, null)
        class Conflict(message: String) : Data(message, null)
    }

    // 認証エラー
    sealed class Auth(message: String, cause: Throwable?) : AppException(message, cause) {
        object Unauthorized : Auth("Unauthorized", null)
        object SessionExpired : Auth("Session expired", null)
    }

    // 不明なエラー
    class Unknown(cause: Throwable) : AppException("Unknown error", cause)
}
```

### UI エラーモデル

```kotlin
// commonMain/kotlin/com/example/shared/presentation/model/UiError.kt

/**
 * UI 用エラーモデル
 */
data class UiError(
    val message: String,
    val action: ErrorAction? = null
)

enum class ErrorAction {
    RETRY,
    LOGIN,
    DISMISS
}

/**
 * Throwable → UiError 変換
 */
fun Throwable.toUiError(): UiError {
    return when (this) {
        is AppException.Network.NoConnection -> UiError(
            message = "インターネット接続がありません",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Timeout -> UiError(
            message = "リクエストがタイムアウトしました",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Server -> UiError(
            message = "サーバーエラーが発生しました（$code）",
            action = ErrorAction.RETRY
        )
        is AppException.Auth.Unauthorized -> UiError(
            message = "認証が必要です",
            action = ErrorAction.LOGIN
        )
        is AppException.Auth.SessionExpired -> UiError(
            message = "セッションの有効期限が切れました",
            action = ErrorAction.LOGIN
        )
        is AppException.Data.NotFound -> UiError(
            message = message,
            action = ErrorAction.DISMISS
        )
        else -> UiError(
            message = "エラーが発生しました",
            action = ErrorAction.DISMISS
        )
    }
}
```

### Ktor エラーハンドリング

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiErrorMapper.kt

/**
 * Ktor レスポンスをアプリケーション例外にマッピング
 */
class ApiErrorMapper {

    fun map(response: HttpResponse): AppException {
        return when (response.status.value) {
            401 -> AppException.Auth.Unauthorized
            403 -> AppException.Auth.Unauthorized
            404 -> AppException.Data.NotFound()
            409 -> AppException.Data.Conflict("Resource already exists")
            in 500..599 -> AppException.Network.Server(response.status.value)
            else -> AppException.Unknown(
                Exception("HTTP ${response.status.value}: ${response.status.description}")
            )
        }
    }

    fun map(throwable: Throwable): AppException {
        return when (throwable) {
            is AppException -> throwable
            is kotlinx.io.IOException -> AppException.Network.NoConnection(throwable)
            is io.ktor.client.plugins.HttpRequestTimeoutException -> AppException.Network.Timeout(throwable)
            else -> AppException.Unknown(throwable)
        }
    }
}
```

---

## テスト戦略

### テストピラミッド

```
         ┌─────────┐
         │   E2E   │  ← プラットフォーム別 UI テスト
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository、ViewModel のテスト
         │  tion   │     (commonTest)
         ├─────────┤
         │  Unit   │  ← UseCase、Domain Model のテスト
         │  Tests  │     (commonTest) 最も多く書く
         └─────────┘
```

### commonTest でのユニットテスト

```kotlin
// commonTest/kotlin/com/example/shared/domain/usecase/GetUsersUseCaseTest.kt

class GetUsersUseCaseTest {

    private lateinit var userRepository: FakeUserRepository
    private lateinit var analyticsRepository: FakeAnalyticsRepository
    private lateinit var useCase: GetUsersUseCase

    @BeforeTest
    fun setup() {
        userRepository = FakeUserRepository()
        analyticsRepository = FakeAnalyticsRepository()
        useCase = GetUsersUseCase(userRepository, analyticsRepository)
    }

    @Test
    fun `invoke returns users from repository`() = runTest {
        // Given
        val expectedUsers = listOf(
            User(id = "1", name = "Alice", email = "alice@example.com",
                joinedAt = Clock.System.now(), status = UserStatus.ACTIVE),
            User(id = "2", name = "Bob", email = "bob@example.com",
                joinedAt = Clock.System.now(), status = UserStatus.ACTIVE)
        )
        userRepository.setUsers(expectedUsers)

        // When
        val result = useCase().first()

        // Then
        assertEquals(expectedUsers, result)
    }

    @Test
    fun `invoke returns empty list when repository is empty`() = runTest {
        // Given
        userRepository.setUsers(emptyList())

        // When
        val result = useCase().first()

        // Then
        assertTrue(result.isEmpty())
    }

    @Test
    fun `invoke logs analytics`() = runTest {
        // Given
        val users = listOf(
            User(id = "1", name = "Alice", email = "alice@example.com",
                joinedAt = Clock.System.now(), status = UserStatus.ACTIVE)
        )
        userRepository.setUsers(users)

        // When
        useCase().first()

        // Then
        assertEquals(1, analyticsRepository.loggedCount)
    }
}
```

### ViewModel テスト

```kotlin
// commonTest/kotlin/com/example/shared/presentation/UserListViewModelTest.kt

class UserListViewModelTest {

    private lateinit var getUsersUseCase: FakeGetUsersUseCase
    private lateinit var viewModel: UserListViewModel
    private lateinit var testScope: TestScope

    @BeforeTest
    fun setup() {
        testScope = TestScope()
        getUsersUseCase = FakeGetUsersUseCase()
        viewModel = UserListViewModel(
            getUsersUseCase = getUsersUseCase,
            coroutineScope = testScope
        )
    }

    @AfterTest
    fun tearDown() {
        viewModel.onCleared()
    }

    @Test
    fun `initial state shows loading then content`() = testScope.runTest {
        // Given
        val users = listOf(createTestUser())
        getUsersUseCase.setUsers(users)

        // When（init でロードが開始される）
        advanceUntilIdle()

        // Then
        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertEquals(1, state.users.size)
    }

    @Test
    fun `loadUsers failure shows error`() = testScope.runTest {
        // Given
        getUsersUseCase.setError(AppException.Network.NoConnection())

        // When
        viewModel.loadUsers()
        advanceUntilIdle()

        // Then
        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertNotNull(state.error)
    }

    @Test
    fun `onUserClick sends navigation event`() = testScope.runTest {
        // Given
        val userId = "test-user-id"

        // When
        val events = mutableListOf<UserListEvent>()
        val job = launch {
            viewModel.events.toList(events)
        }

        viewModel.onUserClick(userId)
        advanceUntilIdle()
        job.cancel()

        // Then
        assertTrue(events.any { it is UserListEvent.NavigateToDetail && it.userId == userId })
    }
}
```

### Fake の実装

```kotlin
// commonTest/kotlin/com/example/shared/test/FakeUserRepository.kt

/**
 * Fake Repository（テスト用実装）
 */
class FakeUserRepository : UserRepository {

    private val users = MutableStateFlow<List<User>>(emptyList())
    private var shouldThrowError: AppException? = null

    fun setUsers(userList: List<User>) {
        users.value = userList
    }

    fun setError(error: AppException) {
        shouldThrowError = error
    }

    fun clearError() {
        shouldThrowError = null
    }

    override fun getUsers(): Flow<List<User>> {
        shouldThrowError?.let { throw it }
        return users
    }

    override fun getUser(userId: String): Flow<User> {
        shouldThrowError?.let { throw it }
        return users.map { list ->
            list.find { it.id == userId }
                ?: throw AppException.Data.NotFound("User not found: $userId")
        }
    }

    override suspend fun createUser(user: User): Result<User> {
        shouldThrowError?.let { return Result.failure(it) }
        users.update { it + user }
        return Result.success(user)
    }

    override suspend fun updateUser(user: User): Result<Unit> {
        shouldThrowError?.let { return Result.failure(it) }
        users.update { list ->
            list.map { if (it.id == user.id) user else it }
        }
        return Result.success(Unit)
    }

    override suspend fun deleteUser(userId: String): Result<Unit> {
        shouldThrowError?.let { return Result.failure(it) }
        users.update { it.filter { user -> user.id != userId } }
        return Result.success(Unit)
    }
}
```

```kotlin
// commonTest/kotlin/com/example/shared/test/FakeGetUsersUseCase.kt

/**
 * Fake UseCase（テスト用実装）
 */
class FakeGetUsersUseCase : GetUsersUseCaseProtocol {

    private val users = MutableStateFlow<List<User>>(emptyList())
    private var error: AppException? = null

    fun setUsers(userList: List<User>) {
        users.value = userList
    }

    fun setError(e: AppException) {
        error = e
    }

    override operator fun invoke(): Flow<List<User>> {
        error?.let { throw it }
        return users
    }
}
```

### テストユーティリティ

```kotlin
// commonTest/kotlin/com/example/shared/test/TestUtils.kt

/**
 * テスト用ユーザー作成
 */
fun createTestUser(
    id: String = randomUUID(),
    name: String = "Test User",
    email: String = "test@example.com",
    status: UserStatus = UserStatus.ACTIVE
): User {
    return User(
        id = id,
        name = name,
        email = email,
        joinedAt = Clock.System.now(),
        status = status
    )
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

- [ ] プラットフォーム固有の実装は最小限に
- [ ] 共通インターフェースを先に設計
- [ ] actual 実装はプラットフォームの Best Practice に従う
- [ ] テスト用の Fake 実装を commonTest に用意

### 依存性注入 (Koin)

- [ ] 共通モジュールは sharedModule に定義
- [ ] プラットフォーム固有は platformModule に定義
- [ ] ViewModel は Factory 経由で生成
- [ ] テスト時は Fake を注入可能に

### データ永続化 (SQLDelight)

- [ ] スキーマは共通で定義
- [ ] Driver は各プラットフォームで実装
- [ ] トランザクションは適切に使用
- [ ] Flow で変更を監視

### ネットワーク (Ktor)

- [ ] HttpClient は DI で管理
- [ ] エンジンはプラットフォーム別に設定
- [ ] エラーハンドリングを統一
- [ ] Serialization は kotlinx-serialization を使用

### 状態管理

- [ ] UI State は単一の data class で管理
- [ ] StateFlow で状態を公開
- [ ] 一時的イベントは Channel を使用
- [ ] UDF（単方向データフロー）を遵守

### テスト

- [ ] commonTest でユニットテストを実装
- [ ] Fake を優先、Mock は最小限
- [ ] runTest で Coroutine テスト
- [ ] テストユーティリティを共通化

### エラーハンドリング

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
- [SQLDelight](https://cashapp.github.io/sqldelight/2.0.0/)
- [Koin](https://insert-koin.io/docs/reference/koin-mp/kmp/)
- [kotlinx-datetime](https://github.com/Kotlin/kotlinx-datetime)
- [kotlinx-serialization](https://github.com/Kotlin/kotlinx.serialization)

### Google 公式

- [Android Developers: Kotlin Multiplatform](https://developer.android.com/kotlin/multiplatform)
