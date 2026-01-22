# KMP Testing Strategy

Testing strategy and commonTest implementation patterns in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md)

---

## Dependencies

Add the following dependencies to your `build.gradle.kts`:

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

**Key dependencies:**
- `kotlin("test")` - Multiplatform test annotations and assertions (`@Test`, `assertEquals`, etc.)
- `kotlinx-coroutines-test` - Coroutine testing utilities (`runTest`, `TestScope`, `advanceUntilIdle`)

---

## Test Pyramid

```
         ┌─────────┐
         │   E2E   │  ← Platform-specific UI tests
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository, ViewModel tests
         │  tion   │     (commonTest)
         ├─────────┤
         │  Unit   │  ← UseCase, Domain Model tests
         │  Tests  │     (commonTest) Write the most tests here
         └─────────┘
```

### E2E Tests

E2E (End-to-End) tests verify the complete user flow from UI to backend. In KMP, these are platform-specific:

- **Android**: Use Compose UI Testing (`androidx.compose.ui:ui-test-junit4`) or Espresso
- **iOS**: Use XCUITest framework
- **Desktop**: Use Compose Desktop testing utilities

```kotlin
// androidTest/kotlin/.../UserListScreenTest.kt
@get:Rule
val composeTestRule = createComposeRule()

@Test
fun userListScreen_displaysUsers() {
    composeTestRule.setContent {
        UserListScreen(viewModel = fakeViewModel)
    }

    composeTestRule.onNodeWithText("Alice").assertIsDisplayed()
}
```

---

## Unit Tests in commonTest

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

## ViewModel Tests

### Understanding TestScope and runTest

When testing ViewModels with coroutines, you need to control the coroutine execution:

- **`runTest`**: A test coroutine builder that provides a controlled coroutine environment. It automatically advances virtual time and handles unhandled exceptions.
- **`TestScope`**: A CoroutineScope designed for testing. It allows manual control over coroutine execution with functions like `advanceUntilIdle()`.
- **Relationship**: `runTest` creates a `TestScope` internally. When you need to inject a scope into a ViewModel, create a `TestScope` explicitly and use its `runTest` extension.

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
        // Create TestScope to inject into ViewModel
        // This allows us to control coroutine execution in tests
        testScope = TestScope()
        getUsersUseCase = FakeGetUsersUseCase()
        viewModel = UserListViewModel(
            getUsersUseCase = getUsersUseCase,
            coroutineScope = testScope  // Inject test scope for controllable coroutines
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

        // When (loading starts in init)
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

## Fake Implementations

### FakeUserRepository

```kotlin
// commonTest/kotlin/com/example/shared/test/FakeUserRepository.kt

/**
 * Fake Repository (test implementation)
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
 * Fake UseCase (test implementation)
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

## Test Utilities

### UUID Generation in KMP

Since `java.util.UUID` is not available in common code, use the expect/actual pattern:

```kotlin
// commonMain/kotlin/com/example/shared/util/UUID.kt
expect fun randomUUID(): String

// androidMain/kotlin/com/example/shared/util/UUID.kt
actual fun randomUUID(): String = java.util.UUID.randomUUID().toString()

// iosMain/kotlin/com/example/shared/util/UUID.kt
actual fun randomUUID(): String = platform.Foundation.NSUUID().UUIDString()
```

Alternatively, use a library like `com.benasher44:uuid` for multiplatform UUID support.

### Test User Factory

```kotlin
// commonTest/kotlin/com/example/shared/test/TestUtils.kt
import kotlinx.datetime.Clock

/**
 * Create test user with sensible defaults
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

## Best Practices

### Implement unit tests in commonTest

Write tests in `commonTest` to ensure they run on all platforms. This maximizes code coverage and catches platform-specific issues early.

### Prefer Fakes over Mocks

**Why Fakes are preferred:**

1. **Readability**: Fakes have explicit, understandable behavior. Mock setup code (`when().thenReturn()`) can become verbose and hard to follow.

2. **Maintainability**: When an interface changes, you update the Fake once. With Mocks, you update every test that mocks that interface.

3. **Reusability**: A well-designed Fake can be reused across many tests. Mocks are typically configured per-test.

4. **Behavior verification**: Fakes naturally support state-based testing. You can inspect the Fake's internal state rather than verifying method calls.

5. **No external dependencies**: Fakes don't require mocking libraries (which may have limited KMP support).

```kotlin
// Fake (preferred)
val fakeRepo = FakeUserRepository()
fakeRepo.setUsers(listOf(testUser))
val result = useCase()  // Test behavior naturally

// Mock (less preferred)
val mockRepo = mock<UserRepository>()
whenever(mockRepo.getUsers()).thenReturn(flowOf(listOf(testUser)))
val result = useCase()
verify(mockRepo).getUsers()  // Verifying implementation details
```

### Use runTest for Coroutine tests

Always wrap coroutine test code in `runTest` to ensure proper virtual time control and exception handling.

### Centralize test utilities

Keep test helpers (factories, extensions, common setup) in a shared location like `commonTest/kotlin/.../test/` to avoid duplication.
