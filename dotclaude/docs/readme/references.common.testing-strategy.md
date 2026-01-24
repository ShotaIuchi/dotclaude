# テスト戦略ガイド

クロスプラットフォームのテスト戦略とベストプラクティス。

---

## 概要

効果的なテスト戦略は、テストピラミッドの原則に従い、各レイヤーに適切なテストを配置することで、高品質なソフトウェアを効率的に開発・維持できるようにします。

---

## テストピラミッド

```
         ┌─────────┐
         │  E2E    │  少数 / 高コスト / 遅い
         │ Tests   │
         ├─────────┤
         │Integration│  中程度
         │  Tests  │
         ├─────────┤
         │  Unit   │  多数 / 低コスト / 速い
         │  Tests  │
         └─────────┘
```

| 種類 | 対象 | 目的 |
|------|------|------|
| Unit Test | 単一クラス/関数 | ロジックの正しさ |
| Integration Test | 複数コンポーネント | コンポーネント間の連携 |
| E2E Test | アプリ全体 | ユーザーフローの検証 |

---

## Unit Tests

### テスト対象

| レイヤー | テスト対象 | モック対象 |
|---------|-----------|-----------|
| ViewModel | 状態遷移 / UI ロジック | UseCase, Repository |
| UseCase | ビジネスロジック | Repository |
| Repository | データ取得ロジック | DataSource, API |
| Mapper | 変換ロジック | なし（純粋関数） |

### 命名規則

```kotlin
// Kotlin: バッククォートで説明的な名前
@Test
fun `ユーザー取得成功時に状態がSuccessになる`() { }

// または英語で
@Test
fun loadUser_success_updatesStateToSuccess() { }
```

### Given-When-Then パターン

```kotlin
@Test
fun `loadUser はリポジトリがユーザーを返すと状態を success に更新する`() {
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
    fun `loadUser はリポジトリ失敗時にエラーを表示`() { }

    @Test
    fun `loadUser は取得中にローディングを表示`() { }

    @Test
    fun `loadUser は空のレスポンスを処理`() { }

    @Test
    fun `loadUser はネットワークタイムアウトを処理`() { }

    @Test
    fun `loadUser は新しい呼び出しで前のリクエストをキャンセル`() { }
}
```

---

## Mock と Stub

### テストライブラリ

**Kotlin/Android:**

| ライブラリ | 目的 | Gradle 依存関係 |
|-----------|------|----------------|
| MockK | Kotlin 用モックフレームワーク | `testImplementation("io.mockk:mockk:1.13.9")` |
| Turbine | Flow テスト | `testImplementation("app.cash.turbine:turbine:1.0.0")` |
| kotlin-test | アサーション | `testImplementation("org.jetbrains.kotlin:kotlin-test")` |
| kotlinx-coroutines-test | コルーチンテスト | `testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")` |

### Fake vs Mock

| 種類 | 説明 | 使用場面 |
|------|------|---------|
| Mock | 呼び出しを記録し検証 | 振る舞いの検証 |
| Stub | 固定値を返す | 入出力の検証 |
| Fake | 簡略化された実装 | 複雑なロジックのテスト |

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

    // テストヘルパー
    fun addUser(user: User) { users.add(user) }
    fun clear() { users.clear() }
}
```

---

## 非同期コードのテスト

### Kotlin Coroutines

```kotlin
@Test
fun `loadUsers はローディングの後に成功を発行`() = runTest {
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

---

## テストデータ

### テストフィクスチャ

```kotlin
// テストデータ定義
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
fun `非アクティブユーザーはフィルタリングされる`() {
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
    fun `getUser は利用可能な場合キャッシュされたユーザーを返す`() = runTest {
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
    fun `状態がローディングの時にローディングインジケーターを表示`() {
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
    fun `状態が成功の時にユーザーリストを表示`() {
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
}
```

---

## テストカバレッジ

### 優先度

1. **高優先度**: ビジネスロジック（UseCase, Domain Model）
2. **中優先度**: データ取得ロジック（Repository, Mapper）
3. **低優先度**: UI ロジック（ViewModel 状態遷移）

### カバレッジ目標

| レイヤー | 目標カバレッジ |
|---------|---------------|
| Domain | 90%+ |
| Data | 80%+ |
| Presentation | 70%+ |

---

## ベストプラクティス

### 推奨事項

- テストは独立して実行可能であるべき
- 各テストでテストデータを明示的にセットアップ
- 1つのテストでは1つのことをテスト
- 意図が明確な命名を使用
- エッジケースをカバー

### 非推奨事項

- テスト間の依存関係
- 実際のネットワーク呼び出し
- 実際のデータベースへの書き込み
- 実装詳細のテスト（例：内部メソッド呼び出し順序）
- Flaky テスト（結果が不安定なテスト）
