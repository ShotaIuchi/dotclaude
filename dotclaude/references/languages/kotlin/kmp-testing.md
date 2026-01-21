# KMP テスト戦略

Kotlin Multiplatform でのテスト戦略と commonTest 実装パターン。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md)

---

## テストピラミッド

```
         ┌─────────┐
         │   E2E   │  ← プラットフォーム別 UI テスト
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository、ViewModel のテスト
         │  tion   │     (commonTest)
         ├─────────┤
         │  Unit   │  ← UseCase、Domain Model のテスト
         │  Tests  │     (commonTest) 最も多く書く
         └─────────┘
```

---

## commonTest でのユニットテスト

```kotlin
// commonTest/kotlin/com/example/shared/domain/usecase/GetUsersUseCaseTest.kt

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
    fun `invoke returns users from repository`() = runTest {
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
    fun `invoke returns empty list when repository is empty`() = runTest {
        // Given
        userRepository.setUsers(emptyList())

        // When
        val result = useCase().first()

        // Then
        assertTrue(result.isEmpty())
    }

    @Test
    fun `invoke logs analytics`() = runTest {
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

```kotlin
// commonTest/kotlin/com/example/shared/presentation/UserListViewModelTest.kt

class UserListViewModelTest {

    private lateinit var getUsersUseCase: FakeGetUsersUseCase
    private lateinit var viewModel: UserListViewModel
    private lateinit var testScope: TestScope

    @BeforeTest
    fun setup() {
        testScope = TestScope()
        getUsersUseCase = FakeGetUsersUseCase()
        viewModel = UserListViewModel(
            getUsersUseCase = getUsersUseCase,
            coroutineScope = testScope
        )
    }

    @AfterTest
    fun tearDown() {
        viewModel.onCleared()
    }

    @Test
    fun `initial state shows loading then content`() = testScope.runTest {
        // Given
        val users = listOf(createTestUser())
        getUsersUseCase.setUsers(users)

        // When（init でロードが開始される）
        advanceUntilIdle()

        // Then
        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertEquals(1, state.users.size)
    }

    @Test
    fun `loadUsers failure shows error`() = testScope.runTest {
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
    fun `onUserClick sends navigation event`() = testScope.runTest {
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

## Fake の実装

### FakeUserRepository

```kotlin
// commonTest/kotlin/com/example/shared/test/FakeUserRepository.kt

/**
 * Fake Repository（テスト用実装）
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
 * Fake UseCase（テスト用実装）
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

```kotlin
// commonTest/kotlin/com/example/shared/test/TestUtils.kt

/**
 * テスト用ユーザー作成
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

- commonTest でユニットテストを実装
- Fake を優先、Mock は最小限
- runTest で Coroutine テスト
- テストユーティリティを共通化
