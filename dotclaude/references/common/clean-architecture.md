# クリーンアーキテクチャガイド

プラットフォーム共通のアーキテクチャ原則とパターン。

---

## 基本原則

### 1. 関心の分離 (Separation of Concerns)

各レイヤーは単一の責務を持ち、他のレイヤーの実装詳細を知らない。

```
┌─────────────────────────────────────────┐
│           Presentation Layer             │  ← UI・ユーザー操作
├─────────────────────────────────────────┤
│             Domain Layer                 │  ← ビジネスロジック
├─────────────────────────────────────────┤
│              Data Layer                  │  ← データ取得・永続化
└─────────────────────────────────────────┘
```

### 2. 依存関係の方向

外側のレイヤーは内側のレイヤーに依存する。逆は許されない。

```
Presentation → Domain ← Data
              (依存の逆転)
```

### 3. 単一の信頼できる情報源 (SSOT: Single Source of Truth)

データの正規化された状態は一箇所（通常 Repository）で管理される。

### 4. 単方向データフロー (UDF: Unidirectional Data Flow)

イベントは上流へ、状態は下流へ流れる。

```
UI ──(イベント)──→ ViewModel ──(状態)──→ UI
         │
         ▼
      UseCase
         │
         ▼
    Repository
```

---

## レイヤー詳細

### Presentation Layer

**責務**: ユーザーインターフェースの表示とユーザー操作のハンドリング

| コンポーネント | 役割 |
|--------------|------|
| View | UI の描画（状態を反映するだけ） |
| ViewModel | UI 状態の保持・UI ロジック |
| UI State | UI の状態を表すデータクラス |

**原則**:
- View はロジックを持たない（状態を描画するだけ）
- ViewModel はプラットフォーム固有の API に依存しない（可能な限り）
- UI State は immutable なデータクラス

### Domain Layer

**責務**: ビジネスロジックの実装

| コンポーネント | 役割 |
|--------------|------|
| UseCase | 単一のビジネス操作 |
| Domain Model | ビジネスエンティティ |
| Repository Interface | データ取得の抽象化 |

**原則**:
- UseCase は単一の操作を実行
- Domain Model はフレームワークに依存しない
- Repository はインターフェースとして定義

### Data Layer

**責務**: データの取得・永続化

| コンポーネント | 役割 |
|--------------|------|
| Repository Impl | Repository インターフェースの実装 |
| DataSource | データソースへのアクセス |
| DTO/Entity | データ転送オブジェクト |

**原則**:
- Repository は複数の DataSource を調整
- DataSource はローカル/リモートで分離
- DTO は Domain Model にマッピング

---

## UI State パターン

### 基本構造

```kotlin
// Kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}
```

```swift
// Swift
enum UiState<T> {
    case loading
    case success(T)
    case error(String)
}
```

### 複合状態

```kotlin
// Kotlin
data class ScreenUiState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val isRefreshing: Boolean = false
)
```

```swift
// Swift
struct ScreenUiState {
    var items: [Item] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isRefreshing: Bool = false
}
```

---

## UseCase パターン

### 単一操作の UseCase

```kotlin
// Kotlin
class GetUserUseCase(
    private val userRepository: UserRepository
) {
    suspend operator fun invoke(userId: String): Result<User> {
        return userRepository.getUser(userId)
    }
}
```

```swift
// Swift
final class GetUserUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute(userId: String) async throws -> User {
        return try await userRepository.getUser(userId)
    }
}
```

### 複合操作の UseCase

```kotlin
// Kotlin
class RefreshDataUseCase(
    private val userRepository: UserRepository,
    private val cacheRepository: CacheRepository
) {
    suspend operator fun invoke(): Result<Unit> {
        return runCatching {
            cacheRepository.clear()
            userRepository.refresh()
        }
    }
}
```

---

## Repository パターン

### インターフェース定義（Domain Layer）

```kotlin
// Kotlin
interface UserRepository {
    suspend fun getUser(id: String): Result<User>
    suspend fun getUsers(): Flow<List<User>>
    suspend fun saveUser(user: User): Result<Unit>
}
```

```swift
// Swift
protocol UserRepository {
    func getUser(id: String) async throws -> User
    func getUsers() -> AsyncStream<[User]>
    func saveUser(_ user: User) async throws
}
```

### 実装（Data Layer）

```kotlin
// Kotlin
class UserRepositoryImpl(
    private val remoteDataSource: UserRemoteDataSource,
    private val localDataSource: UserLocalDataSource
) : UserRepository {

    override suspend fun getUser(id: String): Result<User> {
        return runCatching {
            // ローカルキャッシュを先に確認
            localDataSource.getUser(id)
                ?: remoteDataSource.getUser(id).also { user ->
                    localDataSource.saveUser(user)
                }
        }
    }

    override fun getUsers(): Flow<List<User>> {
        return localDataSource.observeUsers()
            .onStart {
                // バックグラウンドで更新
                refreshUsersFromRemote()
            }
    }
}
```

---

## エラーハンドリング

### Result 型パターン

```kotlin
// Kotlin
sealed class AppResult<out T> {
    data class Success<T>(val data: T) : AppResult<T>()
    data class Error(val exception: AppException) : AppResult<Nothing>()
}

sealed class AppException : Exception() {
    data class Network(override val message: String) : AppException()
    data class NotFound(val id: String) : AppException()
    data class Unauthorized : AppException()
    data class Unknown(override val cause: Throwable?) : AppException()
}
```

```swift
// Swift
enum AppError: Error {
    case network(String)
    case notFound(id: String)
    case unauthorized
    case unknown(Error?)
}
```

### エラーマッピング

```kotlin
// Kotlin - Repository でエラーをマッピング
override suspend fun getUser(id: String): AppResult<User> {
    return try {
        val user = remoteDataSource.getUser(id)
        AppResult.Success(user)
    } catch (e: HttpException) {
        when (e.code) {
            404 -> AppResult.Error(AppException.NotFound(id))
            401 -> AppResult.Error(AppException.Unauthorized)
            else -> AppResult.Error(AppException.Network(e.message ?: "Unknown error"))
        }
    } catch (e: Exception) {
        AppResult.Error(AppException.Unknown(e))
    }
}
```

---

## 命名規則

| 種類 | パターン | 例 |
|------|---------|-----|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository Interface | `{Entity}Repository` | `UserRepository` |
| Repository Impl | `{Entity}RepositoryImpl` | `UserRepositoryImpl` |
| Remote DataSource | `{Entity}RemoteDataSource` | `UserRemoteDataSource` |
| Local DataSource | `{Entity}LocalDataSource` | `UserLocalDataSource` |
| DTO | `{Entity}Dto` / `{Entity}Response` | `UserDto`, `UserResponse` |
| Domain Model | `{Entity}` | `User` |

---

## ベストプラクティス

### DO (推奨)

- ViewModel は UI State を公開し、View は状態を監視
- UseCase は単一の操作に集中
- Repository はデータソースを抽象化
- エラーは適切に型付けしてハンドリング
- テスト可能な設計（依存性注入）

### DON'T (非推奨)

- View でビジネスロジックを実行
- ViewModel で直接 API を呼び出す
- Domain Layer でフレームワーク固有の型を使用
- エラーを握りつぶす
- 神クラス（一つのクラスに多くの責務）
