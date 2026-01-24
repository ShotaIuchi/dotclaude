# KMP テスト戦略

Kotlin Multiplatform におけるテスト戦略と commonTest 実装パターン。

---

## 概要

KMP プロジェクトでは、`commonTest` でテストを書くことで、すべてのプラットフォームでテストを実行できます。これによりコードカバレッジを最大化し、プラットフォーム固有の問題を早期に発見できます。

---

## 依存関係

`build.gradle.kts` に以下の依存関係を追加：

```kotlin
// shared/build.gradle.kts
kotlin {
    sourceSets {
        val commonTest by getting {
            dependencies {
                implementation(kotlin("test"))
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
            }
        }
    }
}
```

**主な依存関係:**
- `kotlin("test")` - マルチプラットフォームテストアノテーションとアサーション（`@Test`, `assertEquals` など）
- `kotlinx-coroutines-test` - コルーチンテストユーティリティ（`runTest`, `TestScope`, `advanceUntilIdle`）

---

## テストピラミッド

```
         ┌─────────┐
         │   E2E   │  ← プラットフォーム固有 UI テスト
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository, ViewModel テスト
         │  tion   │     (commonTest)
         ├─────────┤
         │  Unit   │  ← UseCase, Domain Model テスト
         │  Tests  │     (commonTest) ここに最も多くのテストを書く
         └─────────┘
```

### E2E テスト

E2E（End-to-End）テストは UI からバックエンドまでの完全なユーザーフローを検証します。KMP ではプラットフォーム固有です：

- **Android**: Compose UI Testing（`androidx.compose.ui:ui-test-junit4`）または Espresso を使用
- **iOS**: XCUITest フレームワークを使用
- **Desktop**: Compose Desktop テストユーティリティを使用

---

## commonTest の Unit Tests

```kotlin
// commonTest/kotlin/com/example/shared/domain/usecase/GetUsersUseCaseTest.kt
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.BeforeTest
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GetUsersUseCaseTest {

    private lateinit var userRepository: FakeUserRepository
    private lateinit var analyticsRepository: FakeAnalyticsRepository
    private lateinit var useCase: GetUsersUseCase

    @BeforeTest
    fun setup() {
        userRepository = FakeUserRepository()
        analyticsRepository = FakeAnalyticsRepository()
        useCase = GetUsersUseCase(userRepository, analyticsRepository)
    }

    @Test
    fun `invoke はリポジトリからユーザーを返す`() = runTest {
        // Given
        val expectedUsers = listOf(
            User(id = "1", name = "Alice", email = "alice@example.com",
                joinedAt = Clock.System.now(), status = UserStatus.ACTIVE),
            User(id = "2", name = "Bob", email = "bob@example.com",
                joinedAt = Clock.System.now(), status = UserStatus.ACTIVE)
        )
        userRepository.setUsers(expectedUsers)

        // When
        val result = useCase().first()

        // Then
        assertEquals(expectedUsers, result)
    }

    @Test
    fun `invoke はリポジトリが空の場合に空リストを返す`() = runTest {
        // Given
        userRepository.setUsers(emptyList())

        // When
        val result = useCase().first()

        // Then
        assertTrue(result.isEmpty())
    }

    @Test
    fun `invoke はアナリティクスをログに記録`() = runTest {
        // Given
        val users = listOf(
            User(id = "1", name = "Alice", email = "alice@example.com",
                joinedAt = Clock.System.now(), status = UserStatus.ACTIVE)
        )
        userRepository.setUsers(users)

        // When
        useCase().first()

        // Then
        assertEquals(1, analyticsRepository.loggedCount)
    }
}
```

---

## ViewModel テスト

### TestScope と runTest の理解

コルーチンを持つ ViewModel をテストする際、コルーチンの実行を制御する必要があります：

- **`runTest`**: 制御されたコルーチン環境を提供するテストコルーチンビルダー。自動的に仮想時間を進め、未処理の例外を処理
- **`TestScope`**: テスト用に設計された CoroutineScope。`advanceUntilIdle()` などの関数でコルーチン実行を手動制御可能
- **関係**: `runTest` は内部的に `TestScope` を作成。ViewModel にスコープを注入する必要がある場合は、`TestScope` を明示的に作成してその `runTest` 拡張を使用

```kotlin
// commonTest/kotlin/com/example/shared/presentation/UserListViewModelTest.kt
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.advanceUntilIdle

class UserListViewModelTest {

    private lateinit var getUsersUseCase: FakeGetUsersUseCase
    private lateinit var viewModel: UserListViewModel
    private lateinit var testScope: TestScope

    @BeforeTest
    fun setup() {
        // ViewModel に注入するための TestScope を作成
        // これによりテストでコルーチン実行を制御可能
        testScope = TestScope()
        getUsersUseCase = FakeGetUsersUseCase()
        viewModel = UserListViewModel(
            getUsersUseCase = getUsersUseCase,
            coroutineScope = testScope  // 制御可能なコルーチンのためにテストスコープを注入
        )
    }

    @AfterTest
    fun tearDown() {
        viewModel.onCleared()
    }

    @Test
    fun `初期状態はローディング後にコンテンツを表示`() = testScope.runTest {
        // Given
        val users = listOf(createTestUser())
        getUsersUseCase.setUsers(users)

        // When（init でローディング開始）
        advanceUntilIdle()

        // Then
        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertEquals(1, state.users.size)
    }

    @Test
    fun `loadUsers 失敗時にエラーを表示`() = testScope.runTest {
        // Given
        getUsersUseCase.setError(AppException.Network.NoConnection())

        // When
        viewModel.loadUsers()
        advanceUntilIdle()

        // Then
        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertNotNull(state.error)
    }

    @Test
    fun `onUserClick はナビゲーションイベントを送信`() = testScope.runTest {
        // Given
        val userId = "test-user-id"

        // When
        val events = mutableListOf<UserListEvent>()
        val job = launch {
            viewModel.events.toList(events)
        }

        viewModel.onUserClick(userId)
        advanceUntilIdle()
        job.cancel()

        // Then
        assertTrue(events.any { it is UserListEvent.NavigateToDetail && it.userId == userId })
    }
}
```

---

## Fake 実装

### FakeUserRepository

```kotlin
// commonTest/kotlin/com/example/shared/test/FakeUserRepository.kt

/**
 * Fake Repository（テスト実装）
 */
class FakeUserRepository : UserRepository {

    private val users = MutableStateFlow<List<User>>(emptyList())
    private var shouldThrowError: AppException? = null

    fun setUsers(userList: List<User>) {
        users.value = userList
    }

    fun setError(error: AppException) {
        shouldThrowError = error
    }

    fun clearError() {
        shouldThrowError = null
    }

    override fun getUsers(): Flow<List<User>> {
        shouldThrowError?.let { throw it }
        return users
    }

    override fun getUser(userId: String): Flow<User> {
        shouldThrowError?.let { throw it }
        return users.map { list ->
            list.find { it.id == userId }
                ?: throw AppException.Data.NotFound("User not found: $userId")
        }
    }

    override suspend fun createUser(user: User): Result<User> {
        shouldThrowError?.let { return Result.failure(it) }
        users.update { it + user }
        return Result.success(user)
    }

    override suspend fun updateUser(user: User): Result<Unit> {
        shouldThrowError?.let { return Result.failure(it) }
        users.update { list ->
            list.map { if (it.id == user.id) user else it }
        }
        return Result.success(Unit)
    }

    override suspend fun deleteUser(userId: String): Result<Unit> {
        shouldThrowError?.let { return Result.failure(it) }
        users.update { it.filter { user -> user.id != userId } }
        return Result.success(Unit)
    }
}
```

### FakeGetUsersUseCase

```kotlin
// commonTest/kotlin/com/example/shared/test/FakeGetUsersUseCase.kt

/**
 * Fake UseCase（テスト実装）
 */
class FakeGetUsersUseCase : GetUsersUseCaseProtocol {

    private val users = MutableStateFlow<List<User>>(emptyList())
    private var error: AppException? = null

    fun setUsers(userList: List<User>) {
        users.value = userList
    }

    fun setError(e: AppException) {
        error = e
    }

    override operator fun invoke(): Flow<List<User>> {
        error?.let { throw it }
        return users
    }
}
```

---

## テストユーティリティ

### KMP での UUID 生成

`java.util.UUID` は共通コードで利用できないため、expect/actual パターンを使用：

```kotlin
// commonMain/kotlin/com/example/shared/util/UUID.kt
expect fun randomUUID(): String

// androidMain/kotlin/com/example/shared/util/UUID.kt
actual fun randomUUID(): String = java.util.UUID.randomUUID().toString()

// iosMain/kotlin/com/example/shared/util/UUID.kt
actual fun randomUUID(): String = platform.Foundation.NSUUID().UUIDString()
```

または、`com.benasher44:uuid` などのライブラリを使用してマルチプラットフォーム UUID サポートを取得。

### テストユーザーファクトリ

```kotlin
// commonTest/kotlin/com/example/shared/test/TestUtils.kt
import kotlinx.datetime.Clock

/**
 * 適切なデフォルト値でテストユーザーを作成
 */
fun createTestUser(
    id: String = randomUUID(),
    name: String = "Test User",
    email: String = "test@example.com",
    status: UserStatus = UserStatus.ACTIVE
): User {
    return User(
        id = id,
        name = name,
        email = email,
        joinedAt = Clock.System.now(),
        status = status
    )
}
```

---

## ベストプラクティス

### commonTest でユニットテストを実装

すべてのプラットフォームで実行されるよう `commonTest` でテストを書きます。これによりコードカバレッジを最大化し、プラットフォーム固有の問題を早期に発見できます。

### Mock より Fake を優先

**Fake が優先される理由:**

1. **可読性**: Fake は明示的で理解しやすい動作を持つ。Mock のセットアップコード（`when().thenReturn()`）は冗長で追いにくくなりがち

2. **保守性**: インターフェースが変更されても、Fake は一度更新するだけ。Mock では、そのインターフェースをモックするすべてのテストを更新する必要がある

3. **再利用性**: 良く設計された Fake は多くのテストで再利用可能。Mock は通常テストごとに設定

4. **動作検証**: Fake は状態ベースのテストを自然にサポート。メソッド呼び出しの検証ではなく、Fake の内部状態を検査できる

5. **外部依存なし**: Fake はモッキングライブラリを必要としない（KMP サポートが限られている場合がある）

```kotlin
// Fake（優先）
val fakeRepo = FakeUserRepository()
fakeRepo.setUsers(listOf(testUser))
val result = useCase()  // 動作を自然にテスト

// Mock（あまり推奨しない）
val mockRepo = mock<UserRepository>()
whenever(mockRepo.getUsers()).thenReturn(flowOf(listOf(testUser)))
val result = useCase()
verify(mockRepo).getUsers()  // 実装詳細を検証
```

### コルーチンテストには runTest を使用

適切な仮想時間制御と例外処理を確保するため、コルーチンテストコードは常に `runTest` でラップします。

### テストユーティリティを集中化

重複を避けるため、テストヘルパー（ファクトリ、拡張、共通セットアップ）は `commonTest/kotlin/.../test/` などの共有場所に保持します。
