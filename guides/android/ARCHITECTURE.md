# Android Architecture Guide

Google公式 Android Architecture Guide に基づく、MVVM / UDF / Repository パターンのベストプラクティス集。

---

## 目次

1. [アーキテクチャ概要](#アーキテクチャ概要)
2. [レイヤー構成](#レイヤー構成)
3. [UI Layer](#ui-layer)
4. [Domain Layer](#domain-layer)
5. [Data Layer](#data-layer)
6. [依存性注入 (Hilt)](#依存性注入-hilt)
7. [状態管理と UDF](#状態管理と-udf)
8. [非同期処理 (Coroutines / Flow)](#非同期処理-coroutines--flow)
9. [エラーハンドリング](#エラーハンドリング)
10. [テスト戦略](#テスト戦略)
11. [ディレクトリ構造](#ディレクトリ構造)
12. [命名規則](#命名規則)
13. [ベストプラクティス一覧](#ベストプラクティス一覧)

---

## アーキテクチャ概要

### 基本原則

1. **関心の分離 (Separation of Concerns)**
   - UI ロジックとビジネスロジックを明確に分離
   - 各レイヤーは単一責任を持つ

2. **データ駆動型 UI (Data-driven UI)**
   - UI は状態（State）を反映するだけ
   - 状態変更は ViewModel 経由で行う

3. **単一の信頼できる情報源 (Single Source of Truth: SSOT)**
   - データは一箇所で管理し、他はそこから取得
   - Repository がデータの SSOT となる

4. **単方向データフロー (Unidirectional Data Flow: UDF)**
   - イベントは上流へ（UI → ViewModel → Repository）
   - 状態は下流へ（Repository → ViewModel → UI）

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌─────────────┐    State    ┌─────────────────────────┐   │
│  │   View      │◄────────────│      ViewModel          │   │
│  │ (Compose/   │             │                         │   │
│  │  Fragment)  │────────────►│  - UI State             │   │
│  └─────────────┘   Events    │  - Business Logic Call  │   │
└─────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer (Optional)                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Use Cases                         │   │
│  │  - 複雑なビジネスロジックのカプセル化                    │   │
│  │  - 複数 Repository の組み合わせ                        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Repository                         │   │
│  │  - データアクセスの抽象化                              │   │
│  │  - キャッシュ戦略                                     │   │
│  │  - オフライン対応                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                    │                    │                    │
│                    ▼                    ▼                    │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │   Local DataSource   │  │  Remote DataSource   │        │
│  │   (Room Database)    │  │   (Retrofit API)     │        │
│  └──────────────────────┘  └──────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## レイヤー構成

### 依存関係の方向

```
UI Layer → Domain Layer → Data Layer
```

- 上位レイヤーは下位レイヤーに依存
- 下位レイヤーは上位レイヤーを知らない
- インターフェースを通じて依存性を逆転（DIP）

### 各レイヤーの責務

| レイヤー | 責務 | 主要コンポーネント |
|---------|------|-------------------|
| UI | 画面表示・ユーザー操作 | Activity, Fragment, Compose, ViewModel |
| Domain | ビジネスロジック | UseCase |
| Data | データ取得・永続化 | Repository, DataSource, DAO, API |

---

## UI Layer

### ViewModel

```kotlin
/**
 * ユーザー一覧画面の ViewModel
 *
 * UI 状態の管理とビジネスロジックの呼び出しを担当
 */
@HiltViewModel
class UserListViewModel @Inject constructor(
    private val getUsersUseCase: GetUsersUseCase,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {

    // UI State（単一の状態オブジェクト）
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    // 一時的なイベント用（Snackbar、ナビゲーション等）
    private val _events = Channel<UserListEvent>(Channel.BUFFERED)
    val events: Flow<UserListEvent> = _events.receiveAsFlow()

    init {
        loadUsers()
    }

    /**
     * ユーザー一覧を読み込む
     */
    fun loadUsers() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            getUsersUseCase()
                .catch { e ->
                    _uiState.update {
                        it.copy(isLoading = false, error = e.toUiError())
                    }
                }
                .collect { users ->
                    _uiState.update {
                        it.copy(isLoading = false, users = users, error = null)
                    }
                }
        }
    }

    /**
     * ユーザーを選択する
     */
    fun onUserClick(userId: String) {
        viewModelScope.launch {
            _events.send(UserListEvent.NavigateToDetail(userId))
        }
    }

    /**
     * リトライする
     */
    fun onRetryClick() {
        loadUsers()
    }
}
```

### UI State

```kotlin
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
    data class ShowSnackbar(val message: UiText) : UserListEvent
}
```

### Jetpack Compose UI

```kotlin
/**
 * ユーザー一覧画面
 */
@Composable
fun UserListScreen(
    viewModel: UserListViewModel = hiltViewModel(),
    onNavigateToDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

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
private fun UserListContent(
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
```

---

## Domain Layer

### UseCase

```kotlin
/**
 * ユーザー一覧取得の UseCase
 *
 * 単一のビジネスロジックをカプセル化
 * operator fun invoke() で関数のように呼び出し可能
 */
class GetUsersUseCase @Inject constructor(
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

/**
 * ユーザー詳細取得の UseCase
 */
class GetUserDetailUseCase @Inject constructor(
    private val userRepository: UserRepository,
    private val postRepository: PostRepository
) {
    /**
     * ユーザー詳細と投稿を取得する
     *
     * 複数の Repository を組み合わせる例
     */
    operator fun invoke(userId: String): Flow<UserDetail> {
        return combine(
            userRepository.getUser(userId),
            postRepository.getPostsByUser(userId)
        ) { user, posts ->
            UserDetail(
                user = user,
                posts = posts,
                postCount = posts.size
            )
        }
    }
}
```

### Domain Model

```kotlin
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

---

## Data Layer

### Repository

```kotlin
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

/**
 * ユーザーリポジトリの実装
 *
 * オフラインファースト戦略を採用
 */
class UserRepositoryImpl @Inject constructor(
    private val localDataSource: UserLocalDataSource,
    private val remoteDataSource: UserRemoteDataSource,
    private val networkMonitor: NetworkMonitor,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
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
            .flowOn(ioDispatcher)
    }

    /**
     * 単一ユーザーを取得
     */
    override fun getUser(userId: String): Flow<User> {
        return localDataSource.getUser(userId)
            .onStart {
                refreshUserFromRemote(userId)
            }
            .map { it.toDomain() }
            .flowOn(ioDispatcher)
    }

    /**
     * ユーザーを作成
     */
    override suspend fun createUser(user: User): Result<User> {
        return withContext(ioDispatcher) {
            runCatching {
                // リモートに作成
                val response = remoteDataSource.createUser(user.toRequest())
                val createdUser = response.toDomain()

                // ローカルにキャッシュ
                localDataSource.insertUser(createdUser.toEntity())

                createdUser
            }
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
            Timber.w(e, "Failed to refresh users from remote")
        }
    }

    private suspend fun refreshUserFromRemote(userId: String) {
        if (!networkMonitor.isOnline()) return

        runCatching {
            val remoteUser = remoteDataSource.getUser(userId)
            localDataSource.insertUser(remoteUser.toEntity())
        }.onFailure { e ->
            Timber.w(e, "Failed to refresh user from remote: $userId")
        }
    }
}
```

### Local DataSource (Room)

```kotlin
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
 * Room DAO
 */
@Dao
interface UserDao {

    @Query("SELECT * FROM users ORDER BY name ASC")
    fun getUsers(): Flow<List<UserEntity>>

    @Query("SELECT * FROM users WHERE id = :userId")
    fun getUser(userId: String): Flow<UserEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<UserEntity>)

    @Query("DELETE FROM users")
    suspend fun deleteAllUsers()

    @Query("DELETE FROM users WHERE id = :userId")
    suspend fun deleteUser(userId: String)

    @Transaction
    suspend fun replaceAllUsers(users: List<UserEntity>) {
        deleteAllUsers()
        insertUsers(users)
    }
}

/**
 * Room Entity
 */
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val email: String,
    @ColumnInfo(name = "joined_at")
    val joinedAt: Long,
    val status: String
)
```

### Remote DataSource (Retrofit)

```kotlin
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
 * Retrofit API インターフェース
 */
interface UserApi {

    @GET("users")
    suspend fun getUsers(): List<UserResponse>

    @GET("users/{userId}")
    suspend fun getUser(@Path("userId") userId: String): UserResponse

    @POST("users")
    suspend fun createUser(@Body request: CreateUserRequest): UserResponse

    @PUT("users/{userId}")
    suspend fun updateUser(
        @Path("userId") userId: String,
        @Body request: UpdateUserRequest
    ): UserResponse

    @DELETE("users/{userId}")
    suspend fun deleteUser(@Path("userId") userId: String)
}

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
```

### Model Mapping

```kotlin
/**
 * Entity → Domain
 */
fun UserEntity.toDomain(): User {
    return User(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.fromEpochMilliseconds(joinedAt),
        status = UserStatus.valueOf(status)
    )
}

/**
 * Domain → Entity
 */
fun User.toEntity(): UserEntity {
    return UserEntity(
        id = id,
        name = name,
        email = email,
        joinedAt = joinedAt.toEpochMilliseconds(),
        status = status.name
    )
}

/**
 * Response → Domain
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
 * Response → Entity
 */
fun UserResponse.toEntity(): UserEntity {
    return UserEntity(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.parse(joinedAt).toEpochMilliseconds(),
        status = status.uppercase()
    )
}

/**
 * Domain → UI Model
 */
fun User.toUiModel(dateFormatter: DateFormatter): UserUiModel {
    return UserUiModel(
        id = id,
        displayName = name,
        avatarUrl = null,
        formattedJoinDate = dateFormatter.format(joinedAt)
    )
}
```

---

## 依存性注入 (Hilt)

### Application Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = if (BuildConfig.DEBUG) {
                    HttpLoggingInterceptor.Level.BODY
                } else {
                    HttpLoggingInterceptor.Level.NONE
                }
            })
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
            .build()
    }
}
```

### Database Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "app_database"
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }
}
```

### Repository Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindUserRepository(
        impl: UserRepositoryImpl
    ): UserRepository

    @Binds
    @Singleton
    abstract fun bindPostRepository(
        impl: PostRepositoryImpl
    ): PostRepository
}
```

### DataSource Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DataSourceModule {

    @Provides
    @Singleton
    fun provideUserApi(retrofit: Retrofit): UserApi {
        return retrofit.create(UserApi::class.java)
    }

    @Provides
    @Singleton
    fun provideUserRemoteDataSource(api: UserApi): UserRemoteDataSource {
        return UserRemoteDataSourceImpl(api)
    }

    @Provides
    @Singleton
    fun provideUserLocalDataSource(dao: UserDao): UserLocalDataSource {
        return UserLocalDataSourceImpl(dao)
    }
}
```

### Dispatcher Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DispatcherModule {

    @Provides
    @IoDispatcher
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO

    @Provides
    @DefaultDispatcher
    fun provideDefaultDispatcher(): CoroutineDispatcher = Dispatchers.Default

    @Provides
    @MainDispatcher
    fun provideMainDispatcher(): CoroutineDispatcher = Dispatchers.Main
}

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DefaultDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class MainDispatcher
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
│   │   UI    │─────►│  Event  │─────►│ReduceState│   │
│   └─────────┘      └─────────┘      └─────────┘ │   │
│                                                  │   │
│        ▲                                         │   │
│        │                                         │   │
│   ┌────┴────┐                                    │   │
│   │Side     │◄───────────────────────────────────┘   │
│   │Effects  │                                        │
│   └─────────┘                                        │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### State Holder パターン

```kotlin
/**
 * 画面状態を管理する State Holder
 *
 * 複雑な状態管理ロジックを ViewModel から分離
 */
class UserListStateHolder(
    private val getUsersUseCase: GetUsersUseCase,
    private val coroutineScope: CoroutineScope
) {
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    fun handleEvent(event: UserListUserEvent) {
        when (event) {
            is UserListUserEvent.LoadUsers -> loadUsers()
            is UserListUserEvent.Refresh -> refresh()
            is UserListUserEvent.Search -> search(event.query)
        }
    }

    private fun loadUsers() {
        coroutineScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            // ...
        }
    }

    private fun refresh() {
        // ...
    }

    private fun search(query: String) {
        // ...
    }
}

/**
 * ユーザーからの入力イベント
 */
sealed interface UserListUserEvent {
    object LoadUsers : UserListUserEvent
    object Refresh : UserListUserEvent
    data class Search(val query: String) : UserListUserEvent
}
```

### Compose での状態ホイスティング

```kotlin
/**
 * Stateless な Composable（状態を持たない）
 */
@Composable
fun UserCard(
    user: UserUiModel,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        onClick = onClick,
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = user.displayName, style = MaterialTheme.typography.titleMedium)
            Text(text = user.formattedJoinDate, style = MaterialTheme.typography.bodySmall)
        }
    }
}

/**
 * Stateful な Composable（状態を管理）
 */
@Composable
fun SearchBar(
    onSearch: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    // 内部状態
    var query by rememberSaveable { mutableStateOf("") }

    TextField(
        value = query,
        onValueChange = { query = it },
        modifier = modifier,
        trailingIcon = {
            IconButton(onClick = { onSearch(query) }) {
                Icon(Icons.Default.Search, contentDescription = "Search")
            }
        }
    )
}
```

---

## 非同期処理 (Coroutines / Flow)

### Flow の使い分け

| 種類 | 用途 | 特徴 |
|------|------|------|
| `Flow` | 一般的なデータストリーム | Cold stream |
| `StateFlow` | UI 状態 | Hot stream、常に最新値を保持 |
| `SharedFlow` | イベント | Hot stream、バッファリング可能 |
| `Channel` | 一度きりのイベント | 一度だけ消費 |

### Flow のベストプラクティス

```kotlin
/**
 * Repository での Flow 使用例
 */
class UserRepositoryImpl @Inject constructor(
    private val userDao: UserDao,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : UserRepository {

    // Room の Flow はすでに IO スレッドで実行されるが、
    // 変換処理も IO で行いたい場合は flowOn を使用
    override fun getUsers(): Flow<List<User>> {
        return userDao.getUsers()
            .map { entities -> entities.map { it.toDomain() } }
            .catch { e ->
                Timber.e(e, "Failed to get users")
                emit(emptyList())
            }
            .flowOn(ioDispatcher)
    }
}

/**
 * ViewModel での StateFlow 使用例
 */
@HiltViewModel
class UserListViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    // stateIn で Flow を StateFlow に変換
    val users: StateFlow<List<User>> = userRepository.getUsers()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList()
        )
}

/**
 * Compose での Flow 収集
 */
@Composable
fun UserListScreen(viewModel: UserListViewModel = hiltViewModel()) {
    // Lifecycle-aware な収集
    val users by viewModel.users.collectAsStateWithLifecycle()

    // ...
}
```

### 複数 Flow の結合

```kotlin
/**
 * 複数の Flow を結合する例
 */
class DashboardViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val statsRepository: StatsRepository,
    private val notificationRepository: NotificationRepository
) : ViewModel() {

    val dashboardState: StateFlow<DashboardState> = combine(
        userRepository.getCurrentUser(),
        statsRepository.getStats(),
        notificationRepository.getUnreadCount()
    ) { user, stats, unreadCount ->
        DashboardState(
            user = user,
            stats = stats,
            unreadNotificationCount = unreadCount
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = DashboardState()
    )
}
```

---

## エラーハンドリング

### Result 型の活用

```kotlin
/**
 * カスタム Result 型（詳細なエラー情報を持つ）
 */
sealed interface DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>
    data class Error(val exception: AppException) : DataResult<Nothing>
    object Loading : DataResult<Nothing>
}

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

### Repository でのエラーハンドリング

```kotlin
/**
 * Repository でのエラーハンドリング例
 */
class UserRepositoryImpl @Inject constructor(
    private val api: UserApi,
    private val errorMapper: ApiErrorMapper
) : UserRepository {

    override suspend fun createUser(user: User): DataResult<User> {
        return try {
            val response = api.createUser(user.toRequest())
            DataResult.Success(response.toDomain())
        } catch (e: Exception) {
            DataResult.Error(errorMapper.map(e))
        }
    }
}

/**
 * API エラーマッパー
 */
class ApiErrorMapper @Inject constructor() {

    fun map(throwable: Throwable): AppException {
        return when (throwable) {
            is IOException -> AppException.Network.NoConnection(throwable)
            is SocketTimeoutException -> AppException.Network.Timeout(throwable)
            is HttpException -> mapHttpException(throwable)
            else -> AppException.Unknown(throwable)
        }
    }

    private fun mapHttpException(e: HttpException): AppException {
        return when (e.code()) {
            401 -> AppException.Auth.Unauthorized
            404 -> AppException.Data.NotFound()
            409 -> AppException.Data.Conflict("Resource already exists")
            in 500..599 -> AppException.Network.Server(e.code(), e)
            else -> AppException.Unknown(e)
        }
    }
}
```

### UI でのエラー表示

```kotlin
/**
 * UI 用エラーモデル
 */
data class UiError(
    val message: UiText,
    val action: ErrorAction? = null
)

sealed interface ErrorAction {
    object Retry : ErrorAction
    object Login : ErrorAction
    object Dismiss : ErrorAction
}

/**
 * 多言語対応のテキスト
 */
sealed interface UiText {
    data class DynamicString(val value: String) : UiText
    data class StringResource(@StringRes val resId: Int, val args: List<Any> = emptyList()) : UiText

    @Composable
    fun asString(): String {
        return when (this) {
            is DynamicString -> value
            is StringResource -> stringResource(resId, *args.toTypedArray())
        }
    }
}

/**
 * AppException → UiError 変換
 */
fun AppException.toUiError(): UiError {
    return when (this) {
        is AppException.Network.NoConnection -> UiError(
            message = UiText.StringResource(R.string.error_no_connection),
            action = ErrorAction.Retry
        )
        is AppException.Network.Timeout -> UiError(
            message = UiText.StringResource(R.string.error_timeout),
            action = ErrorAction.Retry
        )
        is AppException.Auth.Unauthorized -> UiError(
            message = UiText.StringResource(R.string.error_unauthorized),
            action = ErrorAction.Login
        )
        is AppException.Auth.SessionExpired -> UiError(
            message = UiText.StringResource(R.string.error_session_expired),
            action = ErrorAction.Login
        )
        else -> UiError(
            message = UiText.StringResource(R.string.error_unknown),
            action = ErrorAction.Dismiss
        )
    }
}
```

---

## テスト戦略

### テストピラミッド

```
         ┌─────────┐
         │   E2E   │  ← 少数の重要フロー
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository、ViewModel のテスト
         │  tion   │
         ├─────────┤
         │  Unit   │  ← UseCase、Domain Model のテスト
         │  Tests  │     最も多く書く
         └─────────┘
```

### Unit Test

```kotlin
/**
 * UseCase のユニットテスト
 */
@OptIn(ExperimentalCoroutinesApi::class)
class GetUsersUseCaseTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var userRepository: FakeUserRepository
    private lateinit var useCase: GetUsersUseCase

    @Before
    fun setup() {
        userRepository = FakeUserRepository()
        useCase = GetUsersUseCase(userRepository)
    }

    @Test
    fun `invoke returns users from repository`() = runTest {
        // Given
        val expectedUsers = listOf(
            User(id = "1", name = "Alice", email = "alice@example.com"),
            User(id = "2", name = "Bob", email = "bob@example.com")
        )
        userRepository.setUsers(expectedUsers)

        // When
        val result = useCase().first()

        // Then
        assertThat(result).isEqualTo(expectedUsers)
    }

    @Test
    fun `invoke returns empty list when repository is empty`() = runTest {
        // Given
        userRepository.setUsers(emptyList())

        // When
        val result = useCase().first()

        // Then
        assertThat(result).isEmpty()
    }
}

/**
 * Main Dispatcher を置き換えるルール
 */
@OptIn(ExperimentalCoroutinesApi::class)
class MainDispatcherRule(
    private val testDispatcher: TestDispatcher = UnconfinedTestDispatcher()
) : TestWatcher() {

    override fun starting(description: Description) {
        Dispatchers.setMain(testDispatcher)
    }

    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}
```

### ViewModel Test

```kotlin
/**
 * ViewModel のテスト
 */
@OptIn(ExperimentalCoroutinesApi::class)
class UserListViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var getUsersUseCase: FakeGetUsersUseCase
    private lateinit var viewModel: UserListViewModel

    @Before
    fun setup() {
        getUsersUseCase = FakeGetUsersUseCase()
        viewModel = UserListViewModel(getUsersUseCase, SavedStateHandle())
    }

    @Test
    fun `initial state shows loading then content`() = runTest {
        // Given
        val users = listOf(createTestUser())
        getUsersUseCase.setUsers(users)

        // When
        val states = mutableListOf<UserListUiState>()
        val job = launch(UnconfinedTestDispatcher()) {
            viewModel.uiState.toList(states)
        }

        // Then
        // 初期状態は Loading
        assertThat(states[0].isLoading).isTrue()
        // データ取得後は Content
        assertThat(states[1].users).hasSize(1)
        assertThat(states[1].isLoading).isFalse()

        job.cancel()
    }

    @Test
    fun `onUserClick sends navigation event`() = runTest {
        // Given
        val userId = "test-user-id"

        // When
        val events = mutableListOf<UserListEvent>()
        val job = launch(UnconfinedTestDispatcher()) {
            viewModel.events.toList(events)
        }

        viewModel.onUserClick(userId)

        // Then
        assertThat(events).contains(UserListEvent.NavigateToDetail(userId))

        job.cancel()
    }
}
```

### Fake / Mock の使い分け

```kotlin
/**
 * Fake Repository（状態を持つテスト用実装）
 */
class FakeUserRepository : UserRepository {

    private val users = MutableStateFlow<List<User>>(emptyList())
    private var shouldThrowError = false

    fun setUsers(userList: List<User>) {
        users.value = userList
    }

    fun setShouldThrowError(shouldThrow: Boolean) {
        shouldThrowError = shouldThrow
    }

    override fun getUsers(): Flow<List<User>> {
        if (shouldThrowError) {
            return flow { throw IOException("Network error") }
        }
        return users
    }

    override fun getUser(userId: String): Flow<User> {
        return users.map { list ->
            list.find { it.id == userId }
                ?: throw AppException.Data.NotFound("User not found")
        }
    }

    override suspend fun createUser(user: User): Result<User> {
        if (shouldThrowError) {
            return Result.failure(IOException("Network error"))
        }
        users.update { it + user }
        return Result.success(user)
    }

    // ...
}
```

### Compose UI Test

```kotlin
/**
 * Compose UI テスト
 */
class UserListScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun `displays loading indicator when loading`() {
        // Given
        val uiState = UserListUiState(isLoading = true)

        // When
        composeTestRule.setContent {
            UserListContent(
                uiState = uiState,
                onUserClick = {},
                onRetryClick = {}
            )
        }

        // Then
        composeTestRule
            .onNodeWithTag("loading_indicator")
            .assertIsDisplayed()
    }

    @Test
    fun `displays user list when loaded`() {
        // Given
        val users = listOf(
            UserUiModel(id = "1", displayName = "Alice", avatarUrl = null, formattedJoinDate = "2024/01/01")
        )
        val uiState = UserListUiState(users = users)

        // When
        composeTestRule.setContent {
            UserListContent(
                uiState = uiState,
                onUserClick = {},
                onRetryClick = {}
            )
        }

        // Then
        composeTestRule
            .onNodeWithText("Alice")
            .assertIsDisplayed()
    }

    @Test
    fun `calls onUserClick when user is clicked`() {
        // Given
        var clickedUserId: String? = null
        val users = listOf(
            UserUiModel(id = "1", displayName = "Alice", avatarUrl = null, formattedJoinDate = "2024/01/01")
        )
        val uiState = UserListUiState(users = users)

        composeTestRule.setContent {
            UserListContent(
                uiState = uiState,
                onUserClick = { clickedUserId = it },
                onRetryClick = {}
            )
        }

        // When
        composeTestRule
            .onNodeWithText("Alice")
            .performClick()

        // Then
        assertThat(clickedUserId).isEqualTo("1")
    }
}
```

---

## ディレクトリ構造

### Feature-based 構造（推奨）

```
app/
├── src/
│   ├── main/
│   │   ├── java/com/example/app/
│   │   │   │
│   │   │   ├── core/                     # 共通コンポーネント
│   │   │   │   ├── data/
│   │   │   │   │   ├── database/         # Room Database
│   │   │   │   │   │   ├── AppDatabase.kt
│   │   │   │   │   │   └── Converters.kt
│   │   │   │   │   └── network/          # Retrofit 設定
│   │   │   │   │       ├── ApiClient.kt
│   │   │   │   │       └── NetworkMonitor.kt
│   │   │   │   │
│   │   │   │   ├── di/                   # DI モジュール
│   │   │   │   │   ├── AppModule.kt
│   │   │   │   │   ├── DatabaseModule.kt
│   │   │   │   │   ├── NetworkModule.kt
│   │   │   │   │   └── DispatcherModule.kt
│   │   │   │   │
│   │   │   │   ├── domain/               # 共通ドメイン
│   │   │   │   │   └── model/
│   │   │   │   │       └── Result.kt
│   │   │   │   │
│   │   │   │   ├── ui/                   # 共通 UI
│   │   │   │   │   ├── component/        # 共通コンポーネント
│   │   │   │   │   │   ├── LoadingIndicator.kt
│   │   │   │   │   │   ├── ErrorContent.kt
│   │   │   │   │   │   └── EmptyContent.kt
│   │   │   │   │   ├── theme/            # テーマ
│   │   │   │   │   │   ├── Color.kt
│   │   │   │   │   │   ├── Theme.kt
│   │   │   │   │   │   └── Type.kt
│   │   │   │   │   └── navigation/       # ナビゲーション
│   │   │   │   │       └── AppNavigation.kt
│   │   │   │   │
│   │   │   │   └── util/                 # ユーティリティ
│   │   │   │       ├── DateFormatter.kt
│   │   │   │       └── Extensions.kt
│   │   │   │
│   │   │   ├── feature/                  # 機能モジュール
│   │   │   │   │
│   │   │   │   ├── user/                 # ユーザー機能
│   │   │   │   │   ├── data/
│   │   │   │   │   │   ├── local/
│   │   │   │   │   │   │   ├── UserDao.kt
│   │   │   │   │   │   │   ├── UserEntity.kt
│   │   │   │   │   │   │   └── UserLocalDataSource.kt
│   │   │   │   │   │   ├── remote/
│   │   │   │   │   │   │   ├── UserApi.kt
│   │   │   │   │   │   │   ├── UserResponse.kt
│   │   │   │   │   │   │   └── UserRemoteDataSource.kt
│   │   │   │   │   │   ├── repository/
│   │   │   │   │   │   │   └── UserRepositoryImpl.kt
│   │   │   │   │   │   └── mapper/
│   │   │   │   │   │       └── UserMapper.kt
│   │   │   │   │   │
│   │   │   │   │   ├── domain/
│   │   │   │   │   │   ├── model/
│   │   │   │   │   │   │   └── User.kt
│   │   │   │   │   │   ├── repository/
│   │   │   │   │   │   │   └── UserRepository.kt
│   │   │   │   │   │   └── usecase/
│   │   │   │   │   │       ├── GetUsersUseCase.kt
│   │   │   │   │   │       └── GetUserDetailUseCase.kt
│   │   │   │   │   │
│   │   │   │   │   ├── ui/
│   │   │   │   │   │   ├── list/
│   │   │   │   │   │   │   ├── UserListScreen.kt
│   │   │   │   │   │   │   ├── UserListViewModel.kt
│   │   │   │   │   │   │   └── UserListUiState.kt
│   │   │   │   │   │   ├── detail/
│   │   │   │   │   │   │   ├── UserDetailScreen.kt
│   │   │   │   │   │   │   ├── UserDetailViewModel.kt
│   │   │   │   │   │   │   └── UserDetailUiState.kt
│   │   │   │   │   │   └── component/
│   │   │   │   │   │       └── UserCard.kt
│   │   │   │   │   │
│   │   │   │   │   └── di/
│   │   │   │   │       └── UserModule.kt
│   │   │   │   │
│   │   │   │   ├── auth/                 # 認証機能
│   │   │   │   │   ├── data/
│   │   │   │   │   ├── domain/
│   │   │   │   │   ├── ui/
│   │   │   │   │   └── di/
│   │   │   │   │
│   │   │   │   └── settings/             # 設定機能
│   │   │   │       ├── data/
│   │   │   │       ├── domain/
│   │   │   │       ├── ui/
│   │   │   │       └── di/
│   │   │   │
│   │   │   └── App.kt                    # Application クラス
│   │   │
│   │   └── res/
│   │
│   └── test/                             # Unit Test
│       └── java/com/example/app/
│           ├── core/
│           └── feature/
│               └── user/
│                   ├── data/
│                   ├── domain/
│                   └── ui/
│
└── build.gradle.kts
```

---

## 命名規則

### クラス命名

| 種類 | サフィックス | 例 |
|------|-------------|-----|
| Activity | Activity | `UserListActivity` |
| Fragment | Fragment | `UserListFragment` |
| Composable Screen | Screen | `UserListScreen` |
| ViewModel | ViewModel | `UserListViewModel` |
| UseCase | UseCase | `GetUsersUseCase` |
| Repository Interface | Repository | `UserRepository` |
| Repository 実装 | RepositoryImpl | `UserRepositoryImpl` |
| DataSource | DataSource | `UserLocalDataSource` |
| DAO | Dao | `UserDao` |
| Entity (Room) | Entity | `UserEntity` |
| API Response | Response / Dto | `UserResponse` |
| API Request | Request | `CreateUserRequest` |
| UI State | UiState | `UserListUiState` |
| UI Model | UiModel | `UserUiModel` |
| Event | Event | `UserListEvent` |
| DI Module | Module | `UserModule` |

### 関数命名

| 種類 | パターン | 例 |
|------|---------|-----|
| データ取得（単一） | `get{Entity}` | `getUser(id)` |
| データ取得（複数） | `get{Entity}s` / `get{Entity}List` | `getUsers()` |
| データ作成 | `create{Entity}` / `insert{Entity}` | `createUser()` |
| データ更新 | `update{Entity}` | `updateUser()` |
| データ削除 | `delete{Entity}` | `deleteUser()` |
| イベントハンドラ | `on{Event}` | `onUserClick()` |
| 変換 | `to{Target}` | `toDomain()`, `toEntity()` |
| 検証 | `is{Condition}` / `has{Property}` | `isValid()`, `hasPermission()` |

### パッケージ命名

```
com.{company}.{app}
    .core                 # 共通コンポーネント
        .data
        .domain
        .ui
        .di
        .util
    .feature              # 機能別
        .{feature}
            .data
            .domain
            .ui
            .di
```

---

## ベストプラクティス一覧

### ViewModel

- [ ] UI State は単一の data class で管理
- [ ] `StateFlow` で状態を公開、`MutableStateFlow` は private
- [ ] 一時的イベントは `Channel` または `SharedFlow` を使用
- [ ] `viewModelScope` でコルーチンを起動
- [ ] SavedStateHandle でプロセス再生成に対応

### Repository

- [ ] インターフェースを定義し、実装と分離
- [ ] オフラインファースト戦略の採用
- [ ] `Flow` でデータストリームを返す
- [ ] エラーは `Result` 型でラップ
- [ ] DataSource の詳細を隠蔽

### UseCase

- [ ] 単一責任（1 UseCase = 1 機能）
- [ ] `operator fun invoke()` で呼び出し可能に
- [ ] 必要な場合のみ作成（シンプルな場合は Repository 直接可）
- [ ] ビジネスロジックのみ、UI ロジックは含めない

### Compose

- [ ] Stateless / Stateful Composable を分離
- [ ] Preview 可能な設計
- [ ] `collectAsStateWithLifecycle()` で Flow を収集
- [ ] `remember` / `rememberSaveable` の適切な使用
- [ ] 再コンポジションの最適化

### 依存性注入

- [ ] Hilt を使用
- [ ] `@Singleton` は必要な場合のみ
- [ ] Qualifier で同一型の依存を区別
- [ ] テスト用の差し替え可能な設計

### テスト

- [ ] UseCase、ViewModel のユニットテスト必須
- [ ] Fake を優先、Mock は最小限
- [ ] `MainDispatcherRule` でテスト用 Dispatcher を設定
- [ ] `runTest` でコルーチンテスト

### エラーハンドリング

- [ ] アプリケーション例外の階層を定義
- [ ] Repository でエラーをラップ
- [ ] UI 用エラーモデルに変換
- [ ] リトライ機構の実装

### パフォーマンス

- [ ] 適切な Dispatcher の使用（IO/Default/Main）
- [ ] `stateIn` で Flow を StateFlow に変換時の `WhileSubscribed` 使用
- [ ] 不要な再コンポジションの回避
- [ ] Lazy 系コンポーネントの活用

---

## 参考リンク

- [Android Architecture Guide](https://developer.android.com/topic/architecture)
- [Guide to app architecture](https://developer.android.com/topic/architecture/intro)
- [UI Layer](https://developer.android.com/topic/architecture/ui-layer)
- [Domain Layer](https://developer.android.com/topic/architecture/domain-layer)
- [Data Layer](https://developer.android.com/topic/architecture/data-layer)
- [Hilt](https://developer.android.com/training/dependency-injection/hilt-android)
- [Kotlin Coroutines](https://developer.android.com/kotlin/coroutines)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
