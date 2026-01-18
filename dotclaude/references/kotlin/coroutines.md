# Kotlin Coroutines ガイド

Android/KMP で共通して使用する Kotlin Coroutines のベストプラクティス。

---

## 基本概念

### CoroutineScope

```kotlin
// ViewModel での使用（Android）
class UserViewModel : ViewModel() {
    // viewModelScope は ViewModel のライフサイクルに紐づく
    fun loadUser(id: String) {
        viewModelScope.launch {
            val user = userRepository.getUser(id)
            _uiState.value = UiState.Success(user)
        }
    }
}

// KMP での使用
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

| 要素 | 説明 |
|------|------|
| `Dispatchers.Main` | UI スレッド |
| `Dispatchers.IO` | I/O 操作用（ネットワーク、DB） |
| `Dispatchers.Default` | CPU 集約的な処理 |
| `Job` | コルーチンのライフサイクル管理 |

---

## Dispatcher の使い分け

### 基本ルール

```kotlin
class UserRepository(
    private val api: UserApi,
    private val dao: UserDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    // I/O 操作は IO Dispatcher で実行
    suspend fun getUser(id: String): User = withContext(ioDispatcher) {
        api.getUser(id)
    }

    // Room/SQLDelight は自動で適切なスレッドで実行するため withContext 不要
    suspend fun getCachedUser(id: String): User? {
        return dao.getUser(id)
    }
}
```

### Dispatcher の注入

```kotlin
// テスト可能にするため Dispatcher を注入
class UserRepository(
    private val api: UserApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    suspend fun getUsers(): List<User> = withContext(ioDispatcher) {
        api.getUsers()
    }
}

// テストでは TestDispatcher を使用
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

### 基本的な Flow の使用

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

### Flow 操作

```kotlin
// map: 各要素を変換
val userNames: Flow<List<String>> = userRepository.observeUsers()
    .map { users -> users.map { it.name } }

// filter: 条件に合う要素のみ
val activeUsers: Flow<List<User>> = userRepository.observeUsers()
    .map { users -> users.filter { it.isActive } }

// combine: 複数の Flow を結合
val uiState: Flow<UiState> = combine(
    userRepository.observeUsers(),
    settingsRepository.observeSettings()
) { users, settings ->
    UiState(users = users, settings = settings)
}

// flatMapLatest: 最新の値のみ処理
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

### StateFlow と SharedFlow

```kotlin
class UserViewModel : ViewModel() {
    // StateFlow: 常に最新の値を保持
    private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    // SharedFlow: イベントの発行（一度きりのイベント）
    private val _events = MutableSharedFlow<Event>()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    fun onButtonClick() {
        viewModelScope.launch {
            _events.emit(Event.NavigateToDetail)
        }
    }
}
```

### SharingStarted 戦略

| 戦略 | 説明 | 使用場面 |
|------|------|---------|
| `Eagerly` | 即座に開始、停止しない | アプリ全体で常に必要なデータ |
| `Lazily` | 最初の購読者で開始、停止しない | 一度取得したら保持したいデータ |
| `WhileSubscribed(timeout)` | 購読者がいる間だけ | 画面表示中のみ必要なデータ |

```kotlin
// 推奨: WhileSubscribed(5000)
// 画面回転時に5秒間はFlowが生き続ける
val users: StateFlow<List<User>> = userRepository.observeUsers()
    .stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
```

---

## エラーハンドリング

### try-catch パターン

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

### Result 型パターン

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

### Flow でのエラーハンドリング

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

## 並行処理

### 並列実行

```kotlin
// 複数の API を並列で呼び出す
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
// 一つの子コルーチンの失敗が他に影響しないようにする
class DashboardViewModel : ViewModel() {
    private val supervisorJob = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.Main + supervisorJob)

    fun loadAll() {
        // 各タスクが独立して失敗を処理
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

## キャンセレーション

### 基本

```kotlin
class SearchViewModel : ViewModel() {
    private var searchJob: Job? = null

    fun search(query: String) {
        // 前の検索をキャンセル
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            delay(300) // デバウンス
            val results = searchRepository.search(query)
            _results.value = results
        }
    }
}
```

### キャンセル対応の suspend 関数

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
                    // キャンセルをチェック
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

## テスト

### runTest の使用

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

### Turbine での Flow テスト

```kotlin
@Test
fun `observeUsers emits updates`() = runTest {
    val repository = UserRepositoryImpl(mockDao)

    repository.observeUsers().test {
        assertEquals(emptyList<User>(), awaitItem())

        // ユーザーを追加
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

    // 300ms 待機前は検索されない
    coVerify(exactly = 0) { mockRepository.search(any()) }

    // 300ms 経過後
    advanceTimeBy(300)
    coVerify(exactly = 1) { mockRepository.search("abc") }
}
```

---

## ベストプラクティス

### DO (推奨)

- `viewModelScope` / 適切な CoroutineScope を使用
- I/O 操作には `Dispatchers.IO` を使用
- テスト用に Dispatcher を注入可能に
- `StateFlow` で UI 状態を管理
- `WhileSubscribed(5000)` で適切なリソース管理

### DON'T (非推奨)

- `GlobalScope` の使用
- `runBlocking` をプロダクションコードで使用
- Dispatcher のハードコード
- Flow の collect を Activity/Fragment で直接実行（ライフサイクルを考慮）
- 例外を握りつぶす
