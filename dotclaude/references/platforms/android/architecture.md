# Android Architecture Guide

Best practices for MVVM / UDF / Repository patterns based on Google's official Android Architecture Guide.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Layer Structure](#layer-structure)
3. [UI Layer](#ui-layer)
4. [Domain Layer](#domain-layer)
5. [Data Layer](#data-layer)
6. [Dependency Injection (Hilt)](#dependency-injection-hilt)
7. [State Management and UDF](#state-management-and-udf)
8. [Async Processing (Coroutines / Flow)](#async-processing-coroutines--flow)
9. [Error Handling](#error-handling)
10. [Testing Strategy](#testing-strategy)
11. [Directory Structure](#directory-structure)
12. [Naming Conventions](#naming-conventions)
13. [Best Practices Checklist](#best-practices-checklist)

---

## Architecture Overview

### Core Principles

1. **Separation of Concerns**
   - Clearly separate UI logic from business logic
   - Each layer has a single responsibility

2. **Data-driven UI**
   - UI only reflects state
   - State changes are made through ViewModel

3. **Single Source of Truth (SSOT)**
   - Data is managed in one place, others retrieve from there
   - Repository becomes the SSOT for data

4. **Unidirectional Data Flow (UDF)**
   - Events flow upstream (UI → ViewModel → Repository)
   - State flows downstream (Repository → ViewModel → UI)

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
│  │  - Encapsulate complex business logic                │   │
│  │  - Combine multiple Repositories                     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Repository                         │   │
│  │  - Abstract data access                              │   │
│  │  - Caching strategy                                  │   │
│  │  - Offline support                                   │   │
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

## Layer Structure

### Dependency Direction

```
UI Layer → Domain Layer → Data Layer
```

- Upper layers depend on lower layers
- Lower layers don't know about upper layers
- Invert dependencies through interfaces (DIP)

### Layer Responsibilities

| Layer | Responsibility | Main Components |
|-------|----------------|-----------------|
| UI | Screen display / User interaction | Activity, Fragment, Compose, ViewModel |
| Domain | Business logic | UseCase |
| Data | Data retrieval / Persistence | Repository, DataSource, DAO, API |

---

## UI Layer

### ViewModel

```kotlin
/**
 * ViewModel for User List Screen
 *
 * Responsible for UI state management and business logic calls
 */
@HiltViewModel
class UserListViewModel @Inject constructor(
    private val getUsersUseCase: GetUsersUseCase,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {

    // UI State (single state object)
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    // For temporary events (Snackbar, navigation, etc.)
    private val _events = Channel<UserListEvent>(Channel.BUFFERED)
    val events: Flow<UserListEvent> = _events.receiveAsFlow()

    init {
        loadUsers()
    }

    /**
     * Load user list
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
     * Select a user
     */
    fun onUserClick(userId: String) {
        viewModelScope.launch {
            _events.send(UserListEvent.NavigateToDetail(userId))
        }
    }

    /**
     * Retry
     */
    fun onRetryClick() {
        loadUsers()
    }
}
```

### UI State

```kotlin
/**
 * UI state for User List Screen
 *
 * Represent state with immutable data class
 */
data class UserListUiState(
    val users: List<UserUiModel> = emptyList(),
    val isLoading: Boolean = false,
    val error: UiError? = null
) {
    // Derived properties
    val isEmpty: Boolean
        get() = users.isEmpty() && !isLoading && error == null

    val showEmptyState: Boolean
        get() = isEmpty

    val showContent: Boolean
        get() = users.isNotEmpty()
}

/**
 * User model for UI layer
 */
data class UserUiModel(
    val id: String,
    val displayName: String,
    val avatarUrl: String?,
    val formattedJoinDate: String
)

/**
 * Temporary UI events
 */
sealed interface UserListEvent {
    data class NavigateToDetail(val userId: String) : UserListEvent
    data class ShowSnackbar(val message: UiText) : UserListEvent
}
```

### Jetpack Compose UI

```kotlin
/**
 * User List Screen
 */
@Composable
fun UserListScreen(
    viewModel: UserListViewModel = hiltViewModel(),
    onNavigateToDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    // Event handling
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is UserListEvent.NavigateToDetail -> {
                    onNavigateToDetail(event.userId)
                }
                is UserListEvent.ShowSnackbar -> {
                    // Show Snackbar
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
 * User List Content (previewable)
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
 * UseCase for getting user list
 *
 * Encapsulates single business logic
 * Can be called like a function with operator fun invoke()
 */
class GetUsersUseCase @Inject constructor(
    private val userRepository: UserRepository,
    private val analyticsRepository: AnalyticsRepository
) {
    /**
     * Get user list
     *
     * @return Flow of user list
     */
    operator fun invoke(): Flow<List<User>> {
        return userRepository.getUsers()
            .onEach { users ->
                // Side effects (analytics, etc.)
                analyticsRepository.logUserListViewed(users.size)
            }
    }
}

/**
 * UseCase for getting user detail
 */
class GetUserDetailUseCase @Inject constructor(
    private val userRepository: UserRepository,
    private val postRepository: PostRepository
) {
    /**
     * Get user detail and posts
     *
     * Example of combining multiple Repositories
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
 * Domain model (contains business logic)
 */
data class User(
    val id: String,
    val name: String,
    val email: String,
    val joinedAt: Instant,
    val status: UserStatus
) {
    // Domain logic
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
 * User Repository interface
 *
 * Domain layer depends on this interface
 */
interface UserRepository {
    fun getUsers(): Flow<List<User>>
    fun getUser(userId: String): Flow<User>
    suspend fun createUser(user: User): Result<User>
    suspend fun updateUser(user: User): Result<Unit>
    suspend fun deleteUser(userId: String): Result<Unit>
}

/**
 * User Repository implementation
 *
 * Adopts offline-first strategy
 */
class UserRepositoryImpl @Inject constructor(
    private val localDataSource: UserLocalDataSource,
    private val remoteDataSource: UserRemoteDataSource,
    private val networkMonitor: NetworkMonitor,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : UserRepository {

    /**
     * Get user list
     *
     * Offline-first:
     * 1. First return local cache
     * 2. Fetch from remote in background
     * 3. Update local with fetched data
     */
    override fun getUsers(): Flow<List<User>> {
        return localDataSource.getUsers()
            .onStart {
                // Sync from remote in background
                refreshUsersFromRemote()
            }
            .map { entities ->
                entities.map { it.toDomain() }
            }
            .flowOn(ioDispatcher)
    }

    /**
     * Get single user
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
     * Create user
     */
    override suspend fun createUser(user: User): Result<User> {
        return withContext(ioDispatcher) {
            runCatching {
                // Create on remote
                val response = remoteDataSource.createUser(user.toRequest())
                val createdUser = response.toDomain()

                // Cache locally
                localDataSource.insertUser(createdUser.toEntity())

                createdUser
            }
        }
    }

    /**
     * Sync user list from remote
     */
    private suspend fun refreshUsersFromRemote() {
        if (!networkMonitor.isOnline()) return

        runCatching {
            val remoteUsers = remoteDataSource.getUsers()
            localDataSource.replaceAllUsers(
                remoteUsers.map { it.toEntity() }
            )
        }.onFailure { e ->
            // Log only, show local data to UI
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
 * User Local DataSource
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
 * User Remote DataSource
 */
interface UserRemoteDataSource {
    suspend fun getUsers(): List<UserResponse>
    suspend fun getUser(userId: String): UserResponse
    suspend fun createUser(request: CreateUserRequest): UserResponse
    suspend fun updateUser(userId: String, request: UpdateUserRequest): UserResponse
    suspend fun deleteUser(userId: String)
}

/**
 * Retrofit API interface
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
 * API response model
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

## Dependency Injection (Hilt)

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

## State Management and UDF

### Unidirectional Data Flow (UDF) Principles

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

### State Holder Pattern

```kotlin
/**
 * State Holder for managing screen state
 *
 * Separates complex state management logic from ViewModel
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
 * User input events
 */
sealed interface UserListUserEvent {
    object LoadUsers : UserListUserEvent
    object Refresh : UserListUserEvent
    data class Search(val query: String) : UserListUserEvent
}
```

### State Hoisting in Compose

```kotlin
/**
 * Stateless Composable (holds no state)
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
 * Stateful Composable (manages state)
 */
@Composable
fun SearchBar(
    onSearch: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    // Internal state
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

## Async Processing (Coroutines / Flow)

### Flow Types

| Type | Use Case | Characteristics |
|------|----------|-----------------|
| `Flow` | General data streams | Cold stream |
| `StateFlow` | UI state | Hot stream, always holds latest value |
| `SharedFlow` | Events | Hot stream, supports buffering |
| `Channel` | One-time events | Consumed only once |

### Flow Best Practices

```kotlin
/**
 * Example of using Flow in Repository
 */
class UserRepositoryImpl @Inject constructor(
    private val userDao: UserDao,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : UserRepository {

    // Room's Flow already runs on IO thread,
    // but use flowOn if you want transformations on IO too
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
 * Example of using StateFlow in ViewModel
 */
@HiltViewModel
class UserListViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    // Convert Flow to StateFlow with stateIn
    val users: StateFlow<List<User>> = userRepository.getUsers()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList()
        )
}

/**
 * Collecting Flow in Compose
 */
@Composable
fun UserListScreen(viewModel: UserListViewModel = hiltViewModel()) {
    // Lifecycle-aware collection
    val users by viewModel.users.collectAsStateWithLifecycle()

    // ...
}
```

### Combining Multiple Flows

```kotlin
/**
 * Example of combining multiple Flows
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

## Error Handling

### Using Result Type

```kotlin
/**
 * Custom Result type (with detailed error info)
 */
sealed interface DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>
    data class Error(val exception: AppException) : DataResult<Nothing>
    object Loading : DataResult<Nothing>
}

/**
 * Application exception hierarchy
 */
sealed class AppException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    // Network errors
    sealed class Network(message: String, cause: Throwable?) : AppException(message, cause) {
        class NoConnection(cause: Throwable? = null) : Network("No internet connection", cause)
        class Timeout(cause: Throwable? = null) : Network("Request timeout", cause)
        class Server(val code: Int, cause: Throwable? = null) : Network("Server error: $code", cause)
    }

    // Data errors
    sealed class Data(message: String, cause: Throwable?) : AppException(message, cause) {
        class NotFound(message: String = "Data not found") : Data(message, null)
        class Validation(message: String) : Data(message, null)
        class Conflict(message: String) : Data(message, null)
    }

    // Auth errors
    sealed class Auth(message: String, cause: Throwable?) : AppException(message, cause) {
        object Unauthorized : Auth("Unauthorized", null)
        object SessionExpired : Auth("Session expired", null)
    }

    // Unknown error
    class Unknown(cause: Throwable) : AppException("Unknown error", cause)
}
```

### Error Handling in Repository

```kotlin
/**
 * Error handling example in Repository
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
 * API Error Mapper
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

### Error Display in UI

```kotlin
/**
 * UI error model
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
 * Localized text
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
 * AppException → UiError conversion
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

## Testing Strategy

### Test Pyramid

```
         ┌─────────┐
         │   E2E   │  ← Few critical flows
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository, ViewModel tests
         │  tion   │
         ├─────────┤
         │  Unit   │  ← UseCase, Domain Model tests
         │  Tests  │     Write the most of these
         └─────────┘
```

### Unit Test

```kotlin
/**
 * UseCase unit test
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
 * Rule to replace Main Dispatcher
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
 * ViewModel test
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
        // Initial state is Loading
        assertThat(states[0].isLoading).isTrue()
        // After data fetch is Content
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

### Fake / Mock Usage

```kotlin
/**
 * Fake Repository (test implementation with state)
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
 * Compose UI test
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

## Directory Structure

### Feature-based Structure (Recommended)

```
app/
├── src/
│   ├── main/
│   │   ├── java/com/example/app/
│   │   │   │
│   │   │   ├── core/                     # Common components
│   │   │   │   ├── data/
│   │   │   │   │   ├── database/         # Room Database
│   │   │   │   │   │   ├── AppDatabase.kt
│   │   │   │   │   │   └── Converters.kt
│   │   │   │   │   └── network/          # Retrofit setup
│   │   │   │   │       ├── ApiClient.kt
│   │   │   │   │       └── NetworkMonitor.kt
│   │   │   │   │
│   │   │   │   ├── di/                   # DI modules
│   │   │   │   │   ├── AppModule.kt
│   │   │   │   │   ├── DatabaseModule.kt
│   │   │   │   │   ├── NetworkModule.kt
│   │   │   │   │   └── DispatcherModule.kt
│   │   │   │   │
│   │   │   │   ├── domain/               # Common domain
│   │   │   │   │   └── model/
│   │   │   │   │       └── Result.kt
│   │   │   │   │
│   │   │   │   ├── ui/                   # Common UI
│   │   │   │   │   ├── component/        # Shared components
│   │   │   │   │   │   ├── LoadingIndicator.kt
│   │   │   │   │   │   ├── ErrorContent.kt
│   │   │   │   │   │   └── EmptyContent.kt
│   │   │   │   │   ├── theme/            # Theme
│   │   │   │   │   │   ├── Color.kt
│   │   │   │   │   │   ├── Theme.kt
│   │   │   │   │   │   └── Type.kt
│   │   │   │   │   └── navigation/       # Navigation
│   │   │   │   │       └── AppNavigation.kt
│   │   │   │   │
│   │   │   │   └── util/                 # Utilities
│   │   │   │       ├── DateFormatter.kt
│   │   │   │       └── Extensions.kt
│   │   │   │
│   │   │   ├── feature/                  # Feature modules
│   │   │   │   │
│   │   │   │   ├── user/                 # User feature
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
│   │   │   │   ├── auth/                 # Auth feature
│   │   │   │   │   ├── data/
│   │   │   │   │   ├── domain/
│   │   │   │   │   ├── ui/
│   │   │   │   │   └── di/
│   │   │   │   │
│   │   │   │   └── settings/             # Settings feature
│   │   │   │       ├── data/
│   │   │   │       ├── domain/
│   │   │   │       ├── ui/
│   │   │   │       └── di/
│   │   │   │
│   │   │   └── App.kt                    # Application class
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

## Naming Conventions

### Class Naming

| Type | Suffix | Example |
|------|--------|---------|
| Activity | Activity | `UserListActivity` |
| Fragment | Fragment | `UserListFragment` |
| Composable Screen | Screen | `UserListScreen` |
| ViewModel | ViewModel | `UserListViewModel` |
| UseCase | UseCase | `GetUsersUseCase` |
| Repository Interface | Repository | `UserRepository` |
| Repository Implementation | RepositoryImpl | `UserRepositoryImpl` |
| DataSource | DataSource | `UserLocalDataSource` |
| DAO | Dao | `UserDao` |
| Entity (Room) | Entity | `UserEntity` |
| API Response | Response / Dto | `UserResponse` |
| API Request | Request | `CreateUserRequest` |
| UI State | UiState | `UserListUiState` |
| UI Model | UiModel | `UserUiModel` |
| Event | Event | `UserListEvent` |
| DI Module | Module | `UserModule` |

### Function Naming

| Type | Pattern | Example |
|------|---------|---------|
| Get single data | `get{Entity}` | `getUser(id)` |
| Get multiple data | `get{Entity}s` / `get{Entity}List` | `getUsers()` |
| Create data | `create{Entity}` / `insert{Entity}` | `createUser()` |
| Update data | `update{Entity}` | `updateUser()` |
| Delete data | `delete{Entity}` | `deleteUser()` |
| Event handler | `on{Event}` | `onUserClick()` |
| Conversion | `to{Target}` | `toDomain()`, `toEntity()` |
| Validation | `is{Condition}` / `has{Property}` | `isValid()`, `hasPermission()` |

### Package Naming

```
com.{company}.{app}
    .core                 # Common components
        .data
        .domain
        .ui
        .di
        .util
    .feature              # Feature-based
        .{feature}
            .data
            .domain
            .ui
            .di
```

---

## Best Practices Checklist

### ViewModel

- [ ] Manage UI State with a single data class
- [ ] Expose state with `StateFlow`, keep `MutableStateFlow` private
- [ ] Use `Channel` or `SharedFlow` for temporary events
- [ ] Launch coroutines with `viewModelScope`
- [ ] Support process recreation with SavedStateHandle

### Repository

- [ ] Define interface and separate from implementation
- [ ] Adopt offline-first strategy
- [ ] Return `Flow` for data streams
- [ ] Wrap errors with `Result` type
- [ ] Hide DataSource details

### UseCase

- [ ] Single responsibility (1 UseCase = 1 function)
- [ ] Make callable with `operator fun invoke()`
- [ ] Create only when needed (direct Repository call is fine for simple cases)
- [ ] Business logic only, no UI logic

### Compose

- [ ] Separate Stateless / Stateful Composables
- [ ] Design for Preview capability
- [ ] Collect Flow with `collectAsStateWithLifecycle()`
- [ ] Appropriate use of `remember` / `rememberSaveable`
- [ ] Optimize recomposition

### Dependency Injection

- [ ] Use Hilt
- [ ] Use `@Singleton` only when necessary
- [ ] Distinguish same-type dependencies with Qualifier
- [ ] Design for testable dependency replacement

### Testing

- [ ] Unit tests for UseCase and ViewModel are required
- [ ] Prefer Fakes, minimize Mocks
- [ ] Set up test Dispatcher with `MainDispatcherRule`
- [ ] Use `runTest` for coroutine tests

### Error Handling

- [ ] Define application exception hierarchy
- [ ] Wrap errors in Repository
- [ ] Convert to UI error model
- [ ] Implement retry mechanism

### Performance

- [ ] Use appropriate Dispatchers (IO/Default/Main)
- [ ] Use `WhileSubscribed` when converting Flow to StateFlow with `stateIn`
- [ ] Avoid unnecessary recomposition
- [ ] Leverage Lazy components

---

## References

- [Android Architecture Guide](https://developer.android.com/topic/architecture)
- [Guide to app architecture](https://developer.android.com/topic/architecture/intro)
- [UI Layer](https://developer.android.com/topic/architecture/ui-layer)
- [Domain Layer](https://developer.android.com/topic/architecture/domain-layer)
- [Data Layer](https://developer.android.com/topic/architecture/data-layer)
- [Hilt](https://developer.android.com/training/dependency-injection/hilt-android)
- [Kotlin Coroutines](https://developer.android.com/kotlin/coroutines)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
