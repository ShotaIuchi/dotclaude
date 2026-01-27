# Android Project Conventions

公式ドキュメントを補完するプロジェクト固有の規約・パターン。

---

## ディレクトリ構造

```
app/src/main/java/com/example/app/
├── ui/                 # UI Layer
│   └── feature/
│       ├── FeatureScreen.kt
│       ├── FeatureViewModel.kt
│       └── FeatureUiState.kt
├── domain/             # Domain Layer
│   ├── model/
│   └── usecase/
├── data/               # Data Layer
│   ├── repository/
│   ├── local/
│   └── remote/
└── di/                 # DI modules
```

## 命名規則

### クラス/ファイル命名

| Type | Suffix | Example |
|------|--------|---------|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository Interface | `{Entity}Repository` | `UserRepository` |
| Repository Implementation | `{Entity}RepositoryImpl` | `UserRepositoryImpl` |
| DAO | `{Entity}Dao` | `UserDao` |
| API Service | `{Entity}Api` / `{Entity}Service` | `UserApi` |
| Entity (Room) | `{Entity}Entity` | `UserEntity` |
| Response (API) | `{Entity}Response` | `UserResponse` |
| Mapper | `{Entity}Mapper` | `UserMapper` |
| Hilt Module | `{Layer}Module` | `DataModule`, `DomainModule` |

### 関数命名

| Type | Pattern | Example |
|------|---------|---------|
| データ取得（単体） | `get{Entity}` | `getUser(userId)` |
| データ取得（複数） | `get{Entity}s` | `getUsers()` |
| データ作成 | `create{Entity}` | `createUser(user)` |
| データ更新 | `update{Entity}` | `updateUser(user)` |
| データ削除 | `delete{Entity}` | `deleteUser(userId)` |
| Stream取得 | `observe{Entity}s` | `observeUsers()` |
| イベントハンドラ | `on{Event}` | `onRefreshClick()` |

## エラーハンドリング

### AppException 階層

```kotlin
sealed class AppException : Exception() {
    // Network errors
    sealed class Network : AppException() {
        data class HttpError(val code: Int, val body: String?) : Network()
        data object Timeout : Network()
        data object NoConnection : Network()
    }
    // Data errors
    sealed class Data : AppException() {
        data class NotFound(val id: String) : Data()
        data object ParseError : Data()
    }
    // Auth errors
    sealed class Auth : AppException() {
        data object Unauthorized : Auth()
        data object SessionExpired : Auth()
    }
}
```

### DataResult 型

```kotlin
sealed interface DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>
    data class Error(val exception: AppException) : DataResult<Nothing>
    data object Loading : DataResult<Nothing>
}
```

- Repository は `DataResult<T>` を返す
- ViewModel は `DataResult` → `UiState` に変換
- UseCase は Repository の `DataResult` をそのまま伝播、またはビジネスロジックを適用

## Hilt DI 構成

```kotlin
// SingletonComponent: アプリ全体で共有
@Module
@InstallIn(SingletonComponent::class)
object DataModule {
    @Provides @Singleton
    fun provideUserRepository(api: UserApi, dao: UserDao): UserRepository =
        UserRepositoryImpl(api, dao)
}

// ViewModelComponent: ViewModel スコープ
@Module
@InstallIn(ViewModelComponent::class)
object DomainModule {
    @Provides
    fun provideGetUsersUseCase(repo: UserRepository): GetUsersUseCase =
        GetUsersUseCase(repo)
}
```

## リトライ / キャッシュ戦略

### オフラインファースト

```
Request → ローカルキャッシュ(Room)確認 → キャッシュヒット → 返却
                                     → キャッシュミス → API呼び出し → Room保存 → 返却
```

### リトライポリシー

| 条件 | リトライ | 最大回数 | バックオフ |
|------|---------|---------|-----------|
| Timeout | Yes | 3 | Exponential (1s, 2s, 4s) |
| 5xx | Yes | 3 | Exponential |
| 429 | Yes | 3 | Retry-After ヘッダ準拠 |
| 4xx (401除く) | No | - | - |
| 401 | トークンリフレッシュ後1回 | 1 | - |

## ベストプラクティスチェックリスト

### ViewModel
- [ ] UiState を単一の data class で管理
- [ ] StateFlow で状態を公開（LiveData は非推奨）
- [ ] `viewModelScope.launch` でコルーチン起動
- [ ] `collectAsStateWithLifecycle()` で Compose から購読

### Repository
- [ ] Interface と Implementation を分離
- [ ] オフラインファースト戦略を実装
- [ ] Flow で変更通知を提供
- [ ] DataSource の詳細を隠蔽

### Compose
- [ ] State hoisting で状態を引き上げ
- [ ] `remember` / `derivedStateOf` で再計算を最適化
- [ ] Preview を活用した開発
- [ ] `LazyColumn` / `LazyRow` で大量リスト対応
