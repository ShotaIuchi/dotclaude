# Kotlin Coroutines ガイド

Android/KMP で一般的に使用される Kotlin Coroutines のベストプラクティス。

---

## 概要

Kotlin Coroutines は、非同期プログラミングを簡潔に記述するためのフレームワークです。構造化された並行処理（Structured Concurrency）により、リソースリークや予期しないエラーを防止します。

---

## 基本概念

### Structured Concurrency

Structured Concurrency は Kotlin Coroutines の基本概念で、適切なライフサイクル管理とエラー伝播を保証します。主な原則:

1. **親子関係**: すべてのコルーチンには親スコープがあり、子コルーチンは親のライフサイクルに紐づく
2. **自動キャンセル**: 親スコープがキャンセルされると、すべての子コルーチンも自動的にキャンセル
3. **エラー伝播**: 子コルーチンの例外は親に伝播（`SupervisorJob` を使用しない限り）
4. **完了待機**: 親コルーチンはすべての子が完了するまで完了しない

```kotlin
// Structured Concurrency の例
suspend fun loadUserData(): UserData = coroutineScope {
    // 両方の子コルーチンがこのスコープに紐づく
    val profile = async { fetchProfile() }
    val settings = async { fetchSettings() }

    // どちらかが失敗すると、もう一方も自動的にキャンセル
    // 親は両方の完了を待つ
    UserData(profile.await(), settings.await())
}
```

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
| `Dispatchers.Default` | CPU 集約処理 |
| `Job` | コルーチンライフサイクル管理 |
| `CoroutineExceptionHandler` | 未キャッチ例外のグローバルハンドラー |

---

## Dispatcher の選択

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

    // Room/SQLDelight は自動的に適切なスレッドで実行、withContext 不要
    suspend fun getCachedUser(id: String): User? {
        return dao.getUser(id)
    }
}
```

### Dispatcher の注入

```kotlin
// テスト可能性のために Dispatcher を注入
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
fun `getUsers はリストを返す`() = runTest {
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

### Cold Flow vs Hot Flow

Cold と Hot Flow の違いを理解することは重要です:

| 種類 | 動作 | 例 |
|------|------|-----|
| **Cold Flow** | 収集時に発行開始、各コレクターは独自の発行を取得 | `flow {}`, `flowOf()`, データベースクエリ |
| **Hot Flow** | コレクターに関係なく発行、コレクター間で発行を共有 | `StateFlow`, `SharedFlow` |

**使い分け:**
- **Cold Flow**: データ取得、一回限りの操作、データベース監視
- **StateFlow**: UI 状態、常に最新値が必要
- **SharedFlow**: イベント、複数のコレクターへのブロードキャスト

### 基本的な Flow 使用法

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

// filter: 条件に一致する要素のみ保持
val activeUsers: Flow<List<User>> = userRepository.observeUsers()
    .map { users -> users.filter { it.isActive } }

// combine: 複数の Flow を結合
val uiState: Flow<UiState> = combine(
    userRepository.observeUsers(),
    settingsRepository.observeSettings()
) { users, settings ->
    UiState(users = users, settings = settings)
}
```

### SharingStarted 戦略

| 戦略 | 説明 | 使用場面 |
|------|------|---------|
| `Eagerly` | 即座に開始、停止しない | アプリ全体で常に必要なデータ |
| `Lazily` | 最初の購読者で開始、停止しない | 一度取得したら保持するデータ |
| `WhileSubscribed(timeout)` | 購読者がいる間のみ | 画面表示中のみ必要なデータ |

```kotlin
// 推奨: WhileSubscribed(5000)
// 画面回転中は Flow が 5 秒間生存
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

> **重要**: コルーチンで例外をキャッチする際は、`CancellationException` を特別に扱う必要があります。`CancellationException` を握りつぶすとコルーチンのキャンセルが壊れます。

```kotlin
class UserViewModel : ViewModel() {
    fun loadUser(id: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            try {
                val user = userRepository.getUser(id)
                _uiState.value = UiState.Success(user)
            } catch (e: CancellationException) {
                // CancellationException は常に再スローしてキャンセル動作を維持
                throw e
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

---

## 並行処理

### 並列実行

```kotlin
// 複数の API を並列呼び出し
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
            try { loadUsers() }
            catch (e: Exception) { handleUserError(e) }
        }
        scope.launch {
            try { loadNotifications() }
            catch (e: Exception) { handleNotificationError(e) }
        }
    }

    override fun onCleared() {
        supervisorJob.cancel()
    }
}
```

---

## キャンセル

### 基本

```kotlin
class SearchViewModel : ViewModel() {
    private var searchJob: Job? = null

    fun search(query: String) {
        // 前回の検索をキャンセル
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            delay(300) // デバウンス
            val results = searchRepository.search(query)
            _results.value = results
        }
    }
}
```

### キャンセル対応のサスペンド関数

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
fun `loadUser は状態を更新する`() = runTest {
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

### Turbine による Flow テスト

```kotlin
@Test
fun `observeUsers は更新を発行する`() = runTest {
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

---

## ベストプラクティス

### 推奨事項

- `viewModelScope` / 適切な CoroutineScope を使用
- I/O 操作には `Dispatchers.IO` を使用
- テスト可能性のために Dispatcher を注入可能に
- `StateFlow` で UI 状態を管理
- 適切なリソース管理のために `WhileSubscribed(5000)` を使用

### 非推奨事項

- `GlobalScope` の使用
- 本番コードでの `runBlocking` の使用
- Dispatcher のハードコード
- Activity/Fragment で直接 Flow を収集（ライフサイクルを考慮）
- 例外を握りつぶす
