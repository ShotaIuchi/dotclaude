# テスト戦略ガイド

プラットフォーム共通のテスト戦略とベストプラクティス。

---

## テストピラミッド

```
          /\
         /  \
        / E2E \         ← 少数・高コスト・遅い
       /──────\
      /        \
     / 統合テスト \      ← 中程度
    /────────────\
   /              \
  /  ユニットテスト  \  ← 多数・低コスト・速い
 /──────────────────\
```

| 種類 | 対象 | 目的 |
|------|------|------|
| ユニットテスト | 単一のクラス/関数 | ロジックの正確性 |
| 統合テスト | 複数のコンポーネント | コンポーネント間の連携 |
| E2E テスト | アプリ全体 | ユーザーフローの検証 |

---

## ユニットテスト

### テスト対象

| レイヤー | テスト対象 | モック対象 |
|---------|-----------|-----------|
| ViewModel | 状態遷移・UI ロジック | UseCase, Repository |
| UseCase | ビジネスロジック | Repository |
| Repository | データ取得ロジック | DataSource, API |
| Mapper | 変換ロジック | なし（純粋関数） |

### 命名規則

```kotlin
// Kotlin: バッククォートで日本語も可
@Test
fun `ユーザー取得に成功した場合 Success状態になる`() { }

// または英語で
@Test
fun loadUser_success_updatesStateToSuccess() { }
```

```swift
// Swift
func test_loadUser_success_updatesStateToSuccess() { }
```

### Given-When-Then パターン

```kotlin
@Test
fun `loadUser updates state to success when repository returns user`() {
    // Given - 前提条件
    val mockRepository = mockk<UserRepository>()
    coEvery { mockRepository.getUser("1") } returns Result.success(testUser)
    val viewModel = UserViewModel(mockRepository)

    // When - 実行
    viewModel.loadUser("1")

    // Then - 検証
    assertEquals(UiState.Success(testUser), viewModel.uiState.value)
}
```

### エッジケースのテスト

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

## モックとスタブ

### 依存性の注入

```kotlin
// プロダクションコード
class UserViewModel(
    private val getUserUseCase: GetUserUseCase  // 注入
) : ViewModel() {
    fun loadUser(id: String) {
        viewModelScope.launch {
            val result = getUserUseCase(id)
            // ...
        }
    }
}

// テストコード
@Test
fun `test with mock`() = runTest {
    // モックを作成
    val mockUseCase = mockk<GetUserUseCase>()
    coEvery { mockUseCase(any()) } returns Result.success(testUser)

    // モックを注入
    val viewModel = UserViewModel(mockUseCase)

    viewModel.loadUser("1")

    assertEquals(UiState.Success(testUser), viewModel.uiState.value)
}
```

### Fake vs Mock

| 種類 | 説明 | 使用場面 |
|------|------|---------|
| Mock | 呼び出しを記録・検証 | 振る舞いの検証 |
| Stub | 固定値を返す | 入力に対する出力の検証 |
| Fake | 簡易実装 | 複雑なロジックのテスト |

```kotlin
// Fake の例
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

    // テスト用のヘルパー
    fun addUser(user: User) {
        users.add(user)
    }

    fun clear() {
        users.clear()
    }
}
```

---

## 非同期コードのテスト

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

## テストデータ

### テストフィクスチャ

```kotlin
// テストデータの定義
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

### ファクトリ関数

```kotlin
// 柔軟なテストデータ生成
fun createUser(
    id: String = "1",
    name: String = "Test User",
    email: String = "test@example.com",
    isActive: Boolean = true
) = User(id, name, email, isActive)

// 使用例
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

## 統合テスト

### Repository の統合テスト

```kotlin
@RunWith(AndroidJUnit4::class)
class UserRepositoryIntegrationTest {
    private lateinit var database: AppDatabase
    private lateinit var repository: UserRepository

    @Before
    fun setup() {
        // インメモリデータベースを使用
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

## UI テスト

### Compose UI テスト

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

### SwiftUI テスト

```swift
final class UserListViewTests: XCTestCase {
    func test_showsUserList() throws {
        let users = TestData.testUsers
        let viewModel = UserListViewModel()
        viewModel.state = .success(users)

        let view = UserListView(viewModel: viewModel)

        // ViewInspector などを使用してテスト
        let list = try view.inspect().list()
        XCTAssertEqual(list.count, users.count)
    }
}
```

---

## テストカバレッジ

### 優先順位

1. **高優先度**: ビジネスロジック（UseCase, Domain Model）
2. **中優先度**: データ取得ロジック（Repository, Mapper）
3. **低優先度**: UI ロジック（ViewModel の状態遷移）

### カバレッジ目標

| レイヤー | 目標カバレッジ |
|---------|--------------|
| Domain | 90%+ |
| Data | 80%+ |
| Presentation | 70%+ |

---

## ベストプラクティス

### DO (推奨)

- テストは独立して実行可能に
- テストデータは各テストで明示的に設定
- 一つのテストで一つの事をテスト
- 意図が明確な命名
- エッジケースをカバー

### DON'T (非推奨)

- テスト間の依存関係
- 実際のネットワーク呼び出し
- 実際のデータベースへの書き込み
- 実装詳細のテスト（内部メソッドの呼び出し順など）
- フレーキーテスト（結果が不安定なテスト）
