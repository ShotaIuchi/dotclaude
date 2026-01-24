# Clean Architecture ガイド

クロスプラットフォームのアーキテクチャ原則とパターン。

---

## 概要

Clean Architecture は、関心の分離と依存性の方向を明確にすることで、テスト可能で保守性の高いコードを実現するアーキテクチャパターンです。

---

## 核となる原則

### 1. 関心の分離

各レイヤーは単一の責任を持ち、他のレイヤーの実装詳細を知りません。

```
┌─────────────────────────────────────────┐
│           Presentation Layer             │  ← UI / ユーザー操作
├─────────────────────────────────────────┤
│             Domain Layer                 │  ← ビジネスロジック
├─────────────────────────────────────────┤
│              Data Layer                  │  ← データ取得 / 永続化
└─────────────────────────────────────────┘
```

### 2. 依存の方向

外側のレイヤーは内側のレイヤーに依存します。逆は許可されません。

```
Presentation → Domain ← Data
              (依存性逆転)
```

### 3. 単一の信頼できるソース（SSOT）

正規化されたデータ状態は一箇所（通常は Repository）で管理されます。

### 4. 単方向データフロー（UDF）

イベントは上流へ、状態は下流へ流れます。

```
UI ──(Event)──→ ViewModel ──(State)──→ UI
         │
         ▼
      UseCase
         │
         ▼
    Repository
```

---

## レイヤーの詳細

### Presentation Layer

**責任**: ユーザーインターフェースの表示とユーザー操作の処理

| コンポーネント | 役割 |
|---------------|------|
| View | UI のレンダリング（状態を反映するのみ） |
| ViewModel | UI 状態の保持 / UI ロジック |
| UI State | UI 状態を表すデータクラス |

**原則**:
- View にはロジックを持たせない（状態を描画するのみ）
- ViewModel はプラットフォーム固有の API に依存しない（できる限り）
- UI State は不変のデータクラス

### Domain Layer

**責任**: ビジネスロジックの実装

| コンポーネント | 役割 |
|---------------|------|
| UseCase | 単一のビジネス操作 |
| Domain Model | ビジネスエンティティ |
| Repository Interface | データ取得の抽象化 |

**原則**:
- UseCase は単一操作を実行
- Domain Model はフレームワークに依存しない
- Repository はインターフェースとして定義

### Data Layer

**責任**: データの取得と永続化

| コンポーネント | 役割 |
|---------------|------|
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

---

## UseCase パターン

### 単一操作 UseCase

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

### 複合操作 UseCase

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

### 実装（Data Layer）

```kotlin
// Kotlin
class UserRepositoryImpl(
    private val remoteDataSource: UserRemoteDataSource,
    private val localDataSource: UserLocalDataSource
) : UserRepository {

    override suspend fun getUser(id: String): Result<User> {
        return runCatching {
            // まずローカルキャッシュを確認
            localDataSource.getUser(id)
                ?: remoteDataSource.getUser(id).also { user ->
                    localDataSource.saveUser(user)
                }
        }
    }

    override fun getUsers(): Flow<List<User>> {
        return localDataSource.observeUsers()
            .onStart {
                // バックグラウンドでリモートから更新
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

### 推奨事項

- ViewModel は UI State を公開し、View は状態を監視
- UseCase は単一操作に集中
- Repository はデータソースを抽象化
- エラーは適切に型付けして処理
- テスト可能な設計（依存性注入）

### 非推奨事項

- View でビジネスロジックを実行
- ViewModel から直接 API を呼び出す
- Domain Layer でフレームワーク固有の型を使用
- エラーを握りつぶす
- God class（一つのクラスに責任が集中しすぎ）
