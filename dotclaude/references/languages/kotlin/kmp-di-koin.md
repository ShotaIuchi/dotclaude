# KMP Dependency Injection (Koin)

Dependency injection patterns using Koin in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [Koin Official](https://insert-koin.io/docs/reference/koin-mp/kmp/)

---

## Common Module Definition

```kotlin
// commonMain/kotlin/com/example/shared/di/SharedModule.kt

/**
 * Common DI module
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
 * Platform-specific DI module (expect)
 */
expect val platformModule: Module
```

---

## Platform-Specific Modules

### Android

```kotlin
// androidMain/kotlin/com/example/shared/di/PlatformModule.android.kt

/**
 * Android-specific DI module
 */
actual val platformModule: Module = module {

    // Ktor HttpClient (OkHttp engine)
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
 * iOS-specific DI module
 */
actual val platformModule: Module = module {

    // Ktor HttpClient (Darwin engine)
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

## Koin Initialization

```kotlin
// commonMain/kotlin/com/example/shared/di/KoinInitializer.kt

/**
 * Koin initialization
 */
fun initKoin(appDeclaration: KoinAppDeclaration = {}) =
    startKoin {
        appDeclaration()
        modules(
            sharedModule,
            platformModule
        )
    }

// iOS helper
fun initKoinIos() = initKoin()
```

```kotlin
// Android initialization (Application class)
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
// iOS initialization (AppDelegate or App)
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
 * ViewModel factory
 *
 * Provides unified ViewModel retrieval across platforms
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

## Best Practices

- Define common modules in sharedModule
- Define platform-specific modules in platformModule
- Create ViewModels through Factory
- Enable Fake injection for testing
