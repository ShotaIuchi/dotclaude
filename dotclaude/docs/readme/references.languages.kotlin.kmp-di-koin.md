# KMP 依存性注入 (Koin)

Kotlin Multiplatform における Koin を使用した依存性注入パターン。

> **対応バージョン**: Koin 3.5.x（Kotlin 1.9+、KMP ターゲット: Android, iOS, Desktop, Web と互換）

---

## 概要

Koin は軽量な依存性注入フレームワークで、Kotlin Multiplatform プロジェクトで共通モジュールとプラットフォーム固有モジュールを分離して管理できます。

---

## 共通モジュール定義

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
 * プラットフォーム固有 DI モジュール（expect）
 */
expect val platformModule: Module
```

---

## プラットフォーム固有モジュール

### Android

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

    // SQLDelight データベースドライバー
    single<SqlDriver> {
        AndroidSqliteDriver(
            schema = AppDatabase.Schema,
            context = get(),
            name = "app.db"
        )
    }

    // SQLDelight データベース
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

### iOS

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

    // SQLDelight データベースドライバー
    single<SqlDriver> {
        NativeSqliteDriver(
            schema = AppDatabase.Schema,
            name = "app.db"
        )
    }

    // SQLDelight データベース
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

---

## Koin 初期化

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
// Android 初期化（Application クラス）
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
// iOS 初期化（AppDelegate または App）
// 注意: Kotlin/Native は Swift 互換性のために関数に "do" プレフィックスを付けてエクスポート
// Kotlin の initKoinIos() は Swift では doInitKoinIos() になる
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

---

## ViewModel Factory

```kotlin
// commonMain/kotlin/com/example/shared/di/ViewModelFactory.kt

/**
 * ViewModel ファクトリ
 *
 * プラットフォーム間で統一された ViewModel 取得を提供
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

## エラーハンドリングとデバッグ

```kotlin
// デバッグ用に Koin ログを有効化
fun initKoin(appDeclaration: KoinAppDeclaration = {}) =
    startKoin {
        // デバッグビルドで詳細ログを有効化
        printLogger(Level.DEBUG)
        appDeclaration()
        modules(
            sharedModule,
            platformModule
        )
    }

// エラーハンドリング付きの安全な依存性解決
class SafeKoinComponent : KoinComponent {

    // null 可能な注入（見つからない場合は null を返す）
    inline fun <reified T : Any> getOrNull(): T? = getKoin().getOrNull()

    // デフォルトフォールバック付き注入
    inline fun <reified T : Any> getOrDefault(default: T): T =
        getKoin().getOrNull() ?: default
}

// 起動時にすべての依存関係を検証（デバッグのみ）
fun verifyKoinConfiguration() {
    if (BuildConfig.DEBUG) {
        try {
            getKoin().checkModules()
        } catch (e: Exception) {
            // 欠落した依存関係をログに記録
            println("Koin configuration error: ${e.message}")
        }
    }
}
```

---

## Koin によるテスト

```kotlin
// testMain/kotlin/com/example/shared/di/TestModule.kt

/**
 * Fake 実装を含むテストモジュール
 */
val testModule = module {
    // 本物の Repository を Fake でオーバーライド
    single<UserRepository> {
        FakeUserRepository()
    }

    single<AnalyticsRepository> {
        FakeAnalyticsRepository()
    }
}

/**
 * テスト用 Fake 実装
 */
class FakeUserRepository : UserRepository {
    private val users = mutableListOf<User>()

    override suspend fun getUsers(): List<User> = users

    override suspend fun getUserById(id: String): User? =
        users.find { it.id == id }

    // テストヘルパーメソッド
    fun addUser(user: User) { users.add(user) }
    fun clear() { users.clear() }
}

/**
 * Koin によるテストセットアップ
 */
class UserListViewModelTest {

    @BeforeTest
    fun setup() {
        startKoin {
            modules(testModule)
        }
    }

    @AfterTest
    fun tearDown() {
        stopKoin()
    }

    @Test
    fun `test get users returns expected list`() = runTest {
        val fakeRepo = get<UserRepository>() as FakeUserRepository
        fakeRepo.addUser(User(id = "1", name = "Test User"))

        val viewModel = UserListViewModel(
            getUsersUseCase = get(),
            coroutineScope = this
        )

        assertEquals(1, viewModel.users.value.size)
    }
}
```

---

## ベストプラクティス

- **共通モジュールを sharedModule で定義**: プラットフォームに依存しない依存関係（repositories, use cases, utilities）を shared モジュールに配置してコード再利用を最大化

- **プラットフォーム固有モジュールを platformModule で定義**: プラットフォーム固有の実装が必要な依存関係（HTTP クライアント、データベースドライバー、ファイルシステム）には `expect/actual` パターンを使用

- **Factory 経由で ViewModel を作成**: ViewModel の作成を集中化して一貫した依存性注入とテストの簡素化を実現

- **テスト用に Fake 注入を有効化**: 実際の実装を Fake でオーバーライドするテストモジュールを作成し、ネットワークやデータベースの依存関係なしで分離されたユニットテストを可能に

- **適切なスコープを使用**:
  - `single` シングルトン用（repositories, database）
  - `factory` 毎回新しいインスタンス用（use cases, presenters）
  - `scoped` ライフサイクルにバインドされたインスタンス用

- **早期に設定を検証**: 開発中に `checkModules()` を呼び出して、実行時ではなく起動時に欠落した依存関係をキャッチ
