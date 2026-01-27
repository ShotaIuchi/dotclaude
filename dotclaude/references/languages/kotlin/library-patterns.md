# Kotlin/KMP Library Patterns

各ライブラリのプロジェクト固有実装パターン。公式ドキュメントで網羅されていない差分を記載。

---

## Coroutines

### ViewModel での標準パターン

```kotlin
class UserListViewModel(
    private val getUsersUseCase: GetUsersUseCase,
) : ViewModel() {
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    fun loadUsers() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            getUsersUseCase().fold(
                onSuccess = { users -> _uiState.update { it.copy(users = users, isLoading = false) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.toUiError(), isLoading = false) } }
            )
        }
    }
}
```

### Flow 変換チェーン

```kotlin
repository.observeUsers()
    .map { entities -> entities.map { it.toDomain() } }
    .catch { emit(emptyList()) }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
```

- `WhileSubscribed(5000)`: 画面回転時に5秒間キャッシュ保持

## Koin

### モジュール構成

```kotlin
// commonMain
val commonModule = module {
    // Repository
    single<UserRepository> { UserRepositoryImpl(get(), get()) }
    // UseCase
    factory { GetUsersUseCase(get()) }
    // ViewModel
    viewModelOf(::UserListViewModel)
}

// androidMain
val androidModule = module {
    single<DatabaseDriver> { AndroidSqliteDriver(Database.Schema, get(), "app.db") }
    single<HttpClientEngine> { OkHttp.create() }
}

// iosMain
val iosModule = module {
    single<DatabaseDriver> { NativeSqliteDriver(Database.Schema, "app.db") }
    single<HttpClientEngine> { Darwin.create() }
}
```

### 初期化

```kotlin
// commonMain
fun initKoin(platformModules: List<Module> = emptyList()) {
    startKoin {
        modules(commonModule + platformModules)
    }
}

// Android: initKoin(listOf(androidModule))
// iOS: initKoin(listOf(iosModule))
```

## SQLDelight

### スキーマ定義

```sql
-- src/commonMain/sqldelight/{package}/User.sq
CREATE TABLE UserEntity (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

getAll:
SELECT * FROM UserEntity ORDER BY created_at DESC;

getById:
SELECT * FROM UserEntity WHERE id = ?;

insert:
INSERT OR REPLACE INTO UserEntity(id, name, email, created_at)
VALUES (?, ?, ?, ?);

deleteById:
DELETE FROM UserEntity WHERE id = ?;
```

### DataSource パターン

```kotlin
class UserLocalDataSource(private val db: Database) {
    fun observeAll(): Flow<List<UserEntity>> =
        db.userQueries.getAll().asFlow().mapToList(Dispatchers.IO)

    suspend fun getById(id: String): UserEntity? =
        db.userQueries.getById(id).executeAsOneOrNull()

    suspend fun insert(entity: UserEntity) =
        db.userQueries.insert(entity.id, entity.name, entity.email, entity.createdAt)
}
```

## Ktor

### HttpClient 設定

```kotlin
// commonMain
fun createHttpClient(engine: HttpClientEngine): HttpClient = HttpClient(engine) {
    install(ContentNegotiation) {
        json(Json {
            ignoreUnknownKeys = true
            isLenient = true
        })
    }
    install(Logging) {
        level = LogLevel.BODY
    }
    install(HttpTimeout) {
        requestTimeoutMillis = 30_000
        connectTimeoutMillis = 10_000
    }
    defaultRequest {
        url("https://api.example.com/v1/")
        contentType(ContentType.Application.Json)
    }
}
```

### API クライアントパターン

```kotlin
class UserRemoteDataSource(private val client: HttpClient) {
    suspend fun getUsers(): List<UserResponse> =
        client.get("users").body()

    suspend fun getUser(id: String): UserResponse =
        client.get("users/$id").body()

    suspend fun createUser(request: CreateUserRequest): UserResponse =
        client.post("users") { setBody(request) }.body()
}
```

## Compose Multiplatform

### 共有 UI パターン

```kotlin
// commonMain
@Composable
fun UserListScreen(viewModel: UserListViewModel = koinViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    when {
        uiState.isLoading -> LoadingContent()
        uiState.error != null -> ErrorContent(uiState.error!!, onRetry = viewModel::loadUsers)
        else -> UserListContent(uiState.users, onUserClick = viewModel::onUserClick)
    }
}
```

### リソースアクセス

```kotlin
// commonMain (Compose MP Resources)
@Composable
fun AppIcon() {
    Image(
        painter = painterResource(Res.drawable.app_icon),
        contentDescription = null
    )
}
```

## expect/actual

### 使用ガイドライン

| 用途 | expect/actual | Interface + DI |
|------|--------------|----------------|
| プラットフォームAPI直接アクセス | 推奨 | - |
| テスタビリティが重要 | - | 推奨 |
| 単純な値/定数 | 推奨 | - |
| 複雑なビジネスロジック | - | 推奨 |

### 典型例

```kotlin
// commonMain
expect class PlatformContext
expect fun getPlatformName(): String

// androidMain
actual typealias PlatformContext = android.content.Context
actual fun getPlatformName(): String = "Android ${Build.VERSION.SDK_INT}"

// iosMain
actual class PlatformContext(val nsObject: NSObject? = null)
actual fun getPlatformName(): String = UIDevice.currentDevice.systemName()
```

## Testing

### commonTest セットアップ

```kotlin
class GetUsersUseCaseTest {
    private val fakeRepository = FakeUserRepository()
    private val useCase = GetUsersUseCase(fakeRepository)

    @Test
    fun `returns users from repository`() = runTest {
        fakeRepository.users = listOf(testUser())
        val result = useCase()
        assertEquals(1, result.getOrNull()?.size)
    }
}
```

### Flow テスト（Turbine）

```kotlin
@Test
fun `emits loading then success`() = runTest {
    viewModel.uiState.test {
        assertEquals(UserListUiState(), awaitItem()) // Initial
        viewModel.loadUsers()
        assertEquals(true, awaitItem().isLoading)     // Loading
        assertEquals(users, awaitItem().users)         // Success
    }
}
```

### Fake パターン

```kotlin
class FakeUserRepository : UserRepository {
    var users = mutableListOf<User>()
    var shouldFail = false

    override suspend fun getUsers(): Result<List<User>> =
        if (shouldFail) Result.failure(AppException.Network.NoConnection)
        else Result.success(users)
}
```
