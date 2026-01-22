# Kotlin Coroutines Guide

Best practices for Kotlin Coroutines commonly used in Android/KMP.

---

## Basic Concepts

### CoroutineScope

```kotlin
// Usage in ViewModel (Android)
class UserViewModel : ViewModel() {
    // viewModelScope is tied to the ViewModel lifecycle
    fun loadUser(id: String) {
        viewModelScope.launch {
            val user = userRepository.getUser(id)
            _uiState.value = UiState.Success(user)
        }
    }
}

// Usage in KMP
class UserViewModel(
    private val scope: CoroutineScope
) {
    fun loadUser(id: String) {
        scope.launch {
            val user = userRepository.getUser(id)
            _uiState.value = UiState.Success(user)
        }
    }
}
```

### CoroutineContext

| Element | Description |
|---------|-------------|
| `Dispatchers.Main` | UI thread |
| `Dispatchers.IO` | For I/O operations (network, DB) |
| `Dispatchers.Default` | CPU-intensive processing |
| `Job` | Coroutine lifecycle management |

---

## Dispatcher Selection

### Basic Rules

```kotlin
class UserRepository(
    private val api: UserApi,
    private val dao: UserDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    // I/O operations run on IO Dispatcher
    suspend fun getUser(id: String): User = withContext(ioDispatcher) {
        api.getUser(id)
    }

    // Room/SQLDelight automatically runs on appropriate thread, no withContext needed
    suspend fun getCachedUser(id: String): User? {
        return dao.getUser(id)
    }
}
```

### Dispatcher Injection

```kotlin
// Inject Dispatcher for testability
class UserRepository(
    private val api: UserApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    suspend fun getUsers(): List<User> = withContext(ioDispatcher) {
        api.getUsers()
    }
}

// Use TestDispatcher in tests
@Test
fun `getUsers returns list`() = runTest {
    val repository = UserRepository(
        api = mockApi,
        ioDispatcher = StandardTestDispatcher(testScheduler)
    )
    val users = repository.getUsers()
    assertEquals(expectedUsers, users)
}
```

---

## Flow

### Basic Flow Usage

```kotlin
// Repository
class UserRepository(private val dao: UserDao) {
    fun observeUsers(): Flow<List<User>> = dao.observeAll()
}

// ViewModel
class UserListViewModel(
    private val userRepository: UserRepository
) : ViewModel() {

    val users: StateFlow<List<User>> = userRepository.observeUsers()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )
}
```

### Flow Operations

```kotlin
// map: Transform each element
val userNames: Flow<List<String>> = userRepository.observeUsers()
    .map { users -> users.map { it.name } }

// filter: Keep only elements matching condition
val activeUsers: Flow<List<User>> = userRepository.observeUsers()
    .map { users -> users.filter { it.isActive } }

// combine: Combine multiple Flows
val uiState: Flow<UiState> = combine(
    userRepository.observeUsers(),
    settingsRepository.observeSettings()
) { users, settings ->
    UiState(users = users, settings = settings)
}

// flatMapLatest: Process only the latest value
val searchResults: Flow<List<User>> = searchQuery
    .debounce(300)
    .flatMapLatest { query ->
        if (query.isEmpty()) {
            flowOf(emptyList())
        } else {
            userRepository.searchUsers(query)
        }
    }
```

### StateFlow and SharedFlow

```kotlin
class UserViewModel : ViewModel() {
    // StateFlow: Always holds the latest value
    private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    // SharedFlow: For event emission (one-time events)
    private val _events = MutableSharedFlow<Event>()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    fun onButtonClick() {
        viewModelScope.launch {
            _events.emit(Event.NavigateToDetail)
        }
    }
}
```

### SharingStarted Strategies

| Strategy | Description | Use Case |
|----------|-------------|----------|
| `Eagerly` | Starts immediately, never stops | Data needed app-wide at all times |
| `Lazily` | Starts on first subscriber, never stops | Data to keep once retrieved |
| `WhileSubscribed(timeout)` | Only while there are subscribers | Data needed only while screen is displayed |

```kotlin
// Recommended: WhileSubscribed(5000)
// Flow stays alive for 5 seconds during screen rotation
val users: StateFlow<List<User>> = userRepository.observeUsers()
    .stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
```

---

## Error Handling

### try-catch Pattern

```kotlin
class UserViewModel : ViewModel() {
    fun loadUser(id: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            try {
                val user = userRepository.getUser(id)
                _uiState.value = UiState.Success(user)
            } catch (e: Exception) {
                _uiState.value = UiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
```

### Result Type Pattern

```kotlin
// Repository
suspend fun getUser(id: String): Result<User> = runCatching {
    api.getUser(id)
}

// ViewModel
fun loadUser(id: String) {
    viewModelScope.launch {
        _uiState.value = UiState.Loading
        userRepository.getUser(id)
            .onSuccess { user ->
                _uiState.value = UiState.Success(user)
            }
            .onFailure { e ->
                _uiState.value = UiState.Error(e.message ?: "Unknown error")
            }
    }
}
```

### Error Handling in Flow

```kotlin
val users: StateFlow<UiState> = userRepository.observeUsers()
    .map<List<User>, UiState> { UiState.Success(it) }
    .catch { e -> emit(UiState.Error(e.message ?: "Unknown error")) }
    .stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = UiState.Loading
    )
```

---

## Concurrent Processing

### Parallel Execution

```kotlin
// Call multiple APIs in parallel
suspend fun loadDashboard(): Dashboard = coroutineScope {
    val userDeferred = async { userRepository.getCurrentUser() }
    val settingsDeferred = async { settingsRepository.getSettings() }
    val notificationsDeferred = async { notificationRepository.getNotifications() }

    Dashboard(
        user = userDeferred.await(),
        settings = settingsDeferred.await(),
        notifications = notificationsDeferred.await()
    )
}
```

### SupervisorJob

```kotlin
// Prevent one child coroutine's failure from affecting others
class DashboardViewModel : ViewModel() {
    private val supervisorJob = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.Main + supervisorJob)

    fun loadAll() {
        // Each task handles failures independently
        scope.launch {
            try {
                loadUsers()
            } catch (e: Exception) {
                handleUserError(e)
            }
        }
        scope.launch {
            try {
                loadNotifications()
            } catch (e: Exception) {
                handleNotificationError(e)
            }
        }
    }

    override fun onCleared() {
        supervisorJob.cancel()
    }
}
```

---

## Cancellation

### Basics

```kotlin
class SearchViewModel : ViewModel() {
    private var searchJob: Job? = null

    fun search(query: String) {
        // Cancel previous search
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            delay(300) // Debounce
            val results = searchRepository.search(query)
            _results.value = results
        }
    }
}
```

### Cancellation-aware Suspend Functions

```kotlin
suspend fun downloadFile(url: String): File {
    return withContext(Dispatchers.IO) {
        val connection = URL(url).openConnection()
        connection.inputStream.use { input ->
            val file = File.createTempFile("download", ".tmp")
            file.outputStream().use { output ->
                val buffer = ByteArray(8192)
                var bytesRead: Int
                while (input.read(buffer).also { bytesRead = it } != -1) {
                    // Check for cancellation
                    ensureActive()
                    output.write(buffer, 0, bytesRead)
                }
            }
            file
        }
    }
}
```

---

## Testing

### Using runTest

```kotlin
@Test
fun `loadUser updates state`() = runTest {
    // Given
    val mockRepository = mockk<UserRepository>()
    coEvery { mockRepository.getUser("1") } returns User(id = "1", name = "Test")
    val viewModel = UserViewModel(mockRepository)

    // When
    viewModel.loadUser("1")

    // Then
    assertEquals(UiState.Success(User(id = "1", name = "Test")), viewModel.uiState.value)
}
```

### Flow Testing with Turbine

```kotlin
@Test
fun `observeUsers emits updates`() = runTest {
    val repository = UserRepositoryImpl(mockDao)

    repository.observeUsers().test {
        assertEquals(emptyList<User>(), awaitItem())

        // Add user
        mockDao.insert(User(id = "1", name = "Test"))

        assertEquals(listOf(User(id = "1", name = "Test")), awaitItem())

        cancelAndIgnoreRemainingEvents()
    }
}
```

### TestDispatcher

```kotlin
@Test
fun `search debounces input`() = runTest {
    val testDispatcher = StandardTestDispatcher(testScheduler)
    val viewModel = SearchViewModel(
        searchRepository = mockRepository,
        dispatcher = testDispatcher
    )

    viewModel.search("a")
    advanceTimeBy(100)
    viewModel.search("ab")
    advanceTimeBy(100)
    viewModel.search("abc")

    // No search before 300ms wait
    coVerify(exactly = 0) { mockRepository.search(any()) }

    // After 300ms
    advanceTimeBy(300)
    coVerify(exactly = 1) { mockRepository.search("abc") }
}
```

---

## Best Practices

### DO (Recommended)

- Use `viewModelScope` / appropriate CoroutineScope
- Use `Dispatchers.IO` for I/O operations
- Make Dispatcher injectable for testing
- Manage UI state with `StateFlow`
- Use `WhileSubscribed(5000)` for proper resource management

### DON'T (Not Recommended)

- Using `GlobalScope`
- Using `runBlocking` in production code
- Hardcoding Dispatchers
- Collecting Flow directly in Activity/Fragment (consider lifecycle)
- Swallowing exceptions
