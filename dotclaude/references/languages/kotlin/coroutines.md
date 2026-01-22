# Kotlin Coroutines Guide

Best practices for Kotlin Coroutines commonly used in Android/KMP.

---

## Basic Concepts

### Structured Concurrency

Structured Concurrency is a fundamental concept in Kotlin Coroutines that ensures proper lifecycle management and error propagation. Key principles:

1. **Parent-Child Relationship**: Every coroutine has a parent scope, and child coroutines are tied to their parent's lifecycle.
2. **Automatic Cancellation**: When a parent scope is cancelled, all child coroutines are automatically cancelled.
3. **Error Propagation**: Exceptions in child coroutines propagate to the parent (unless using `SupervisorJob`).
4. **Completion Waiting**: A parent coroutine doesn't complete until all its children complete.

```kotlin
// Structured Concurrency example
suspend fun loadUserData(): UserData = coroutineScope {
    // Both child coroutines are tied to this scope
    val profile = async { fetchProfile() }
    val settings = async { fetchSettings() }

    // If either fails, the other is cancelled automatically
    // Parent waits for both to complete
    UserData(profile.await(), settings.await())
}
```

**Why it matters**: Without Structured Concurrency, you risk coroutine leaks, orphaned tasks, and unpredictable error handling.

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

// KMP CoroutineScope creation and lifecycle management
class KmpViewModel {
    // Create scope with SupervisorJob for independent child failure handling
    private val viewModelScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    fun doWork() {
        viewModelScope.launch {
            // Work here
        }
    }

    // Must be called when ViewModel is no longer needed
    fun onCleared() {
        viewModelScope.cancel()
    }
}

// Alternative: Use a scope factory for better testability
interface ScopeProvider {
    val scope: CoroutineScope
}

class DefaultScopeProvider : ScopeProvider {
    override val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
}
```

### CoroutineContext

| Element | Description |
|---------|-------------|
| `Dispatchers.Main` | UI thread |
| `Dispatchers.IO` | For I/O operations (network, DB) |
| `Dispatchers.Default` | CPU-intensive processing |
| `Job` | Coroutine lifecycle management |
| `CoroutineExceptionHandler` | Global exception handler for uncaught exceptions |

```kotlin
// CoroutineExceptionHandler example
val exceptionHandler = CoroutineExceptionHandler { _, exception ->
    Log.e("Coroutine", "Uncaught exception: ${exception.message}")
}

val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main + exceptionHandler)
```

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

### Required Imports

```kotlin
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.MutableSharedFlow
```

### Cold Flow vs Hot Flow

Understanding the difference between Cold and Hot Flows is essential:

| Type | Behavior | Examples |
|------|----------|----------|
| **Cold Flow** | Starts emitting when collected; each collector gets its own emission | `flow {}`, `flowOf()`, database queries |
| **Hot Flow** | Emits regardless of collectors; collectors share emissions | `StateFlow`, `SharedFlow` |

```kotlin
// Cold Flow: Each collector triggers a new database query
val coldFlow: Flow<List<User>> = flow {
    emit(database.getUsers()) // Runs for each collector
}

// Hot Flow: All collectors share the same state
val hotFlow: StateFlow<List<User>> = MutableStateFlow(emptyList())
```

**When to use which:**
- **Cold Flow**: Data fetching, one-time operations, database observations
- **StateFlow**: UI state, always need the latest value
- **SharedFlow**: Events, broadcasts to multiple collectors

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

> **Important**: When catching exceptions in coroutines, you must handle `CancellationException` specially. Swallowing `CancellationException` breaks coroutine cancellation.

```kotlin
class UserViewModel : ViewModel() {
    fun loadUser(id: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            try {
                val user = userRepository.getUser(id)
                _uiState.value = UiState.Success(user)
            } catch (e: CancellationException) {
                // Always rethrow CancellationException to maintain cancellation behavior
                throw e
            } catch (e: Exception) {
                _uiState.value = UiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}

// Alternative: Use when expression for cleaner handling
fun loadUserAlternative(id: String) {
    viewModelScope.launch {
        _uiState.value = UiState.Loading
        try {
            val user = userRepository.getUser(id)
            _uiState.value = UiState.Success(user)
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            _uiState.value = UiState.Error(e.message ?: "Unknown error")
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

Add Turbine to your test dependencies:

```kotlin
// build.gradle.kts
dependencies {
    testImplementation("app.cash.turbine:turbine:1.0.0")
}
```

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
