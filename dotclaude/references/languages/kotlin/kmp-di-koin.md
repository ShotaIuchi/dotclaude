# KMP 依存性注入 (Koin)

Kotlin Multiplatform での Koin を使用した依存性注入パターン。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md) | [Koin 公式](https://insert-koin.io/docs/reference/koin-mp/kmp/)

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
 * プラットフォーム固有の DI モジュール（expect）
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

---

## ViewModel ファクトリ

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

## ベストプラクティス

- 共通モジュールは sharedModule に定義
- プラットフォーム固有は platformModule に定義
- ViewModel は Factory 経由で生成
- テスト時は Fake を注入可能に
