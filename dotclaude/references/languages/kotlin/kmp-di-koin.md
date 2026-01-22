# KMP Dependency Injection (Koin)

Dependency injection patterns using Koin in Kotlin Multiplatform.

> **Supported Version**: Koin 3.5.x (compatible with Kotlin 1.9+, KMP targets: Android, iOS, Desktop, Web)

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

    // PostRepository (required by GetUserDetailUseCase)
    single<PostRepository> {
        PostRepositoryImpl(
            remoteDataSource = get()
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
// Note: Kotlin/Native exports functions with "do" prefix for Swift compatibility
// initKoinIos() in Kotlin becomes doInitKoinIos() in Swift
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

## Error Handling and Debugging

```kotlin
// Enable Koin logging for debugging
fun initKoin(appDeclaration: KoinAppDeclaration = {}) =
    startKoin {
        // Enable detailed logging in debug builds
        printLogger(Level.DEBUG)
        appDeclaration()
        modules(
            sharedModule,
            platformModule
        )
    }

// Safe dependency resolution with error handling
class SafeKoinComponent : KoinComponent {

    // Nullable injection (returns null if not found)
    inline fun <reified T : Any> getOrNull(): T? = getKoin().getOrNull()

    // Injection with default fallback
    inline fun <reified T : Any> getOrDefault(default: T): T =
        getKoin().getOrNull() ?: default
}

// Verify all dependencies at startup (debug only)
fun verifyKoinConfiguration() {
    if (BuildConfig.DEBUG) {
        try {
            getKoin().checkModules()
        } catch (e: Exception) {
            // Log missing dependencies
            println("Koin configuration error: ${e.message}")
        }
    }
}
```

---

## Testing with Koin

```kotlin
// testMain/kotlin/com/example/shared/di/TestModule.kt

/**
 * Test module with Fake implementations
 */
val testModule = module {
    // Override real repository with Fake
    single<UserRepository> {
        FakeUserRepository()
    }

    single<AnalyticsRepository> {
        FakeAnalyticsRepository()
    }
}

/**
 * Fake implementation for testing
 */
class FakeUserRepository : UserRepository {
    private val users = mutableListOf<User>()

    override suspend fun getUsers(): List<User> = users

    override suspend fun getUserById(id: String): User? =
        users.find { it.id == id }

    // Test helper methods
    fun addUser(user: User) { users.add(user) }
    fun clear() { users.clear() }
}

/**
 * Test setup with Koin
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

## Best Practices

- **Define common modules in sharedModule**: Keep platform-agnostic dependencies (repositories, use cases, utilities) in the shared module to maximize code reuse across platforms.

- **Define platform-specific modules in platformModule**: Use `expect/actual` pattern for dependencies that require platform-specific implementations (HTTP clients, database drivers, file systems).

- **Create ViewModels through Factory**: Centralize ViewModel creation to ensure consistent dependency injection and simplify testing.

- **Enable Fake injection for testing**: Create test modules that override real implementations with Fakes, allowing isolated unit testing without network or database dependencies.

- **Use appropriate scopes**:
  - `single` for singletons (repositories, database)
  - `factory` for new instances each time (use cases, presenters)
  - `scoped` for lifecycle-bound instances

- **Verify configuration early**: Call `checkModules()` during development to catch missing dependencies at startup rather than runtime.
