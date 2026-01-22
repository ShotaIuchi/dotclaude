# Testing Strategy Guide

Cross-platform testing strategy and best practices.

---

## Test Pyramid

```
          /\
         /  \
        / E2E \         ← Few / High Cost / Slow
       /──────\
      /        \
     / Integration \    ← Medium
    /────────────\
   /              \
  /   Unit Tests   \    ← Many / Low Cost / Fast
 /──────────────────\
```

| Type | Target | Purpose |
|------|--------|---------|
| Unit Test | Single class/function | Logic correctness |
| Integration Test | Multiple components | Component interaction |
| E2E Test | Entire app | User flow verification |

---

## Unit Tests

### Test Targets

| Layer | Test Target | Mock Target |
|-------|-------------|-------------|
| ViewModel | State transitions / UI logic | UseCase, Repository |
| UseCase | Business logic | Repository |
| Repository | Data retrieval logic | DataSource, API |
| Mapper | Transformation logic | None (pure functions) |

### Naming Conventions

```kotlin
// Kotlin: Backticks allow descriptive names
@Test
fun `when user fetch succeeds then state becomes Success`() { }

// Or in English
@Test
fun loadUser_success_updatesStateToSuccess() { }
```

```swift
// Swift
func test_loadUser_success_updatesStateToSuccess() { }
```

### Given-When-Then Pattern

```kotlin
@Test
fun `loadUser updates state to success when repository returns user`() {
    // Given - Preconditions
    val mockRepository = mockk<UserRepository>()
    coEvery { mockRepository.getUser("1") } returns Result.success(testUser)
    val viewModel = UserViewModel(mockRepository)

    // When - Execution
    viewModel.loadUser("1")

    // Then - Verification
    assertEquals(UiState.Success(testUser), viewModel.uiState.value)
}
```

### Testing Edge Cases

```kotlin
class UserViewModelTest {
    @Test
    fun `loadUser shows error when repository fails`() { }

    @Test
    fun `loadUser shows loading while fetching`() { }

    @Test
    fun `loadUser handles empty response`() { }

    @Test
    fun `loadUser handles network timeout`() { }

    @Test
    fun `loadUser cancels previous request on new call`() { }
}
```

---

## Mocks and Stubs

### Dependency Injection

```kotlin
// Production code
class UserViewModel(
    private val getUserUseCase: GetUserUseCase  // Injected
) : ViewModel() {
    fun loadUser(id: String) {
        viewModelScope.launch {
            val result = getUserUseCase(id)
            // ...
        }
    }
}

// Test code
@Test
fun `test with mock`() = runTest {
    // Create mock
    val mockUseCase = mockk<GetUserUseCase>()
    coEvery { mockUseCase(any()) } returns Result.success(testUser)

    // Inject mock
    val viewModel = UserViewModel(mockUseCase)

    viewModel.loadUser("1")

    assertEquals(UiState.Success(testUser), viewModel.uiState.value)
}
```

### Fake vs Mock

| Type | Description | Use Case |
|------|-------------|----------|
| Mock | Records and verifies calls | Behavior verification |
| Stub | Returns fixed values | Input/output verification |
| Fake | Simplified implementation | Testing complex logic |

```kotlin
// Fake example
class FakeUserRepository : UserRepository {
    private val users = mutableListOf<User>()

    override suspend fun getUser(id: String): Result<User> {
        return users.find { it.id == id }
            ?.let { Result.success(it) }
            ?: Result.failure(NotFoundException(id))
    }

    override suspend fun saveUser(user: User): Result<Unit> {
        users.add(user)
        return Result.success(Unit)
    }

    // Test helpers
    fun addUser(user: User) {
        users.add(user)
    }

    fun clear() {
        users.clear()
    }
}
```

---

## Testing Async Code

### Kotlin Coroutines

```kotlin
@Test
fun `loadUsers emits loading then success`() = runTest {
    val viewModel = UserViewModel(fakeRepository)

    viewModel.uiState.test {
        assertEquals(UiState.Initial, awaitItem())

        viewModel.loadUsers()

        assertEquals(UiState.Loading, awaitItem())
        assertEquals(UiState.Success(testUsers), awaitItem())

        cancelAndIgnoreRemainingEvents()
    }
}
```

### Swift async/await

```swift
func test_loadUser_success() async throws {
    // Given
    let mockRepository = MockUserRepository()
    mockRepository.stubbedUser = testUser
    let viewModel = UserViewModel(repository: mockRepository)

    // When
    await viewModel.loadUser(id: "1")

    // Then
    XCTAssertEqual(viewModel.state, .success(testUser))
}
```

---

## Test Data

### Test Fixtures

```kotlin
// Test data definition
object TestData {
    val testUser = User(
        id = "1",
        name = "Test User",
        email = "test@example.com"
    )

    val testUsers = listOf(
        User(id = "1", name = "User 1", email = "user1@example.com"),
        User(id = "2", name = "User 2", email = "user2@example.com"),
        User(id = "3", name = "User 3", email = "user3@example.com")
    )
}
```

### Factory Functions

```kotlin
// Flexible test data generation
fun createUser(
    id: String = "1",
    name: String = "Test User",
    email: String = "test@example.com",
    isActive: Boolean = true
) = User(id, name, email, isActive)

// Usage
@Test
fun `inactive user is filtered out`() {
    val users = listOf(
        createUser(id = "1", isActive = true),
        createUser(id = "2", isActive = false),
        createUser(id = "3", isActive = true)
    )

    val result = filterActiveUsers(users)

    assertEquals(2, result.size)
}
```

---

## Integration Tests

### Repository Integration Test

```kotlin
@RunWith(AndroidJUnit4::class)
class UserRepositoryIntegrationTest {
    private lateinit var database: AppDatabase
    private lateinit var repository: UserRepository

    @Before
    fun setup() {
        // Use in-memory database
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).build()

        repository = UserRepositoryImpl(
            localDataSource = database.userDao(),
            remoteDataSource = FakeUserRemoteDataSource()
        )
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun `getUser returns cached user when available`() = runTest {
        // Given
        val user = createUser(id = "1")
        database.userDao().insert(user.toEntity())

        // When
        val result = repository.getUser("1")

        // Then
        assertTrue(result.isSuccess)
        assertEquals(user, result.getOrNull())
    }
}
```

---

## UI Tests

### Compose UI Test

```kotlin
@RunWith(AndroidJUnit4::class)
class UserListScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun `shows loading indicator when state is loading`() {
        composeTestRule.setContent {
            UserListScreen(
                uiState = UiState.Loading,
                onUserClick = {}
            )
        }

        composeTestRule
            .onNodeWithTag("loading_indicator")
            .assertIsDisplayed()
    }

    @Test
    fun `shows user list when state is success`() {
        val users = TestData.testUsers

        composeTestRule.setContent {
            UserListScreen(
                uiState = UiState.Success(users),
                onUserClick = {}
            )
        }

        users.forEach { user ->
            composeTestRule
                .onNodeWithText(user.name)
                .assertIsDisplayed()
        }
    }

    @Test
    fun `calls onUserClick when user item is clicked`() {
        var clickedUserId: String? = null
        val users = TestData.testUsers

        composeTestRule.setContent {
            UserListScreen(
                uiState = UiState.Success(users),
                onUserClick = { clickedUserId = it }
            )
        }

        composeTestRule
            .onNodeWithText(users.first().name)
            .performClick()

        assertEquals(users.first().id, clickedUserId)
    }
}
```

### SwiftUI Test

```swift
final class UserListViewTests: XCTestCase {
    func test_showsUserList() throws {
        let users = TestData.testUsers
        let viewModel = UserListViewModel()
        viewModel.state = .success(users)

        let view = UserListView(viewModel: viewModel)

        // Test using ViewInspector or similar
        let list = try view.inspect().list()
        XCTAssertEqual(list.count, users.count)
    }
}
```

---

## Test Coverage

### Priority

1. **High Priority**: Business logic (UseCase, Domain Model)
2. **Medium Priority**: Data retrieval logic (Repository, Mapper)
3. **Low Priority**: UI logic (ViewModel state transitions)

### Coverage Targets

| Layer | Target Coverage |
|-------|----------------|
| Domain | 90%+ |
| Data | 80%+ |
| Presentation | 70%+ |

---

## Best Practices

### DO (Recommended)

- Tests should be independently executable
- Set up test data explicitly for each test
- Test one thing per test
- Use clear, intention-revealing naming
- Cover edge cases

### DON'T (Not Recommended)

- Dependencies between tests
- Actual network calls
- Writing to actual databases
- Testing implementation details (e.g., internal method call order)
- Flaky tests (tests with unstable results)
