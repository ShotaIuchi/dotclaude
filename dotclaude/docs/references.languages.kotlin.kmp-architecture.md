# Kotlin Multiplatform アーキテクチャガイド

Kotlin 公式ドキュメントと Google の KMP 推奨事項に基づいたマルチプラットフォーム開発のベストプラクティス集。

---

## 概要

KMP（Kotlin Multiplatform）は、Android、iOS、Desktop などの複数プラットフォーム間でビジネスロジックを共有しながら、プラットフォーム固有の機能も活用できるフレームワークです。

---

## アーキテクチャ概要

### 基本原則

1. **ビジネスロジックを共有**
   - Domain Layer と Data Layer を shared モジュールに配置
   - UI ロジック（ViewModel）もできる限り共有

2. **プラットフォーム固有コードを最小化**
   - expect/actual で抽象化しプラットフォーム依存を限定
   - UI はプラットフォームごとにネイティブ、または Compose Multiplatform

3. **単方向データフロー（UDF）**
   - イベントは上流へ（UI → ViewModel → Repository）
   - 状態は下流へ（Repository → ViewModel → UI）

4. **依存の方向**
   - shared モジュールはプラットフォームモジュールに依存しない
   - プラットフォームモジュールが shared に依存

```
┌─────────────────────────────────────────────────────────────────────┐
│                     プラットフォーム UI Layer                          │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │   Android (Compose)  │        │   iOS (SwiftUI)      │          │
│  │   / Compose MP       │        │   / Compose MP       │          │
│  └──────────────────────┘        └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Shared Module                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                        │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   ViewModel (commonMain)                             │    │   │
│  │  │   - UI State 管理                                    │    │   │
│  │  │   - UseCase 呼び出し                                 │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     Domain Layer                             │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   UseCase / Model (commonMain)                       │    │   │
│  │  │   - ビジネスロジック                                  │    │   │
│  │  │   - ドメインモデル                                    │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      Data Layer                              │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   Repository (commonMain)                            │    │   │
│  │  │   - データアクセスの抽象化                            │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │           │                              │                   │   │
│  │           ▼                              ▼                   │   │
│  │  ┌─────────────────┐          ┌─────────────────┐           │   │
│  │  │ Local DataSource│          │Remote DataSource│           │   │
│  │  │  (SQLDelight)   │          │    (Ktor)       │           │   │
│  │  └─────────────────┘          └─────────────────┘           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## プロジェクト構造

### ソースセット階層

```
shared/
├── commonMain/              # 全プラットフォーム共通
│   └── kotlin/
├── commonTest/              # 共通テスト
│   └── kotlin/
├── androidMain/             # Android 固有
│   └── kotlin/
├── iosMain/                 # iOS 共通（ARM64 + X64）
│   └── kotlin/
└── desktopMain/             # Desktop（JVM）固有
    └── kotlin/
```

---

## Shared Module (shared)

### Domain Layer

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/User.kt

/**
 * ドメインモデル（ビジネスロジックを含む）
 */
data class User(
    val id: String,
    val name: String,
    val email: String,
    val joinedAt: Instant,
    val status: UserStatus
) {
    // ドメインロジック
    val isActive: Boolean
        get() = status == UserStatus.ACTIVE

    fun canPost(): Boolean {
        return isActive && !isBanned()
    }

    private fun isBanned(): Boolean {
        return status == UserStatus.BANNED
    }
}
```

### Data Layer

```kotlin
// commonMain/kotlin/com/example/shared/data/repository/UserRepositoryImpl.kt

/**
 * User リポジトリ実装
 *
 * Offline-first 戦略を採用
 */
class UserRepositoryImpl(
    private val localDataSource: UserLocalDataSource,
    private val remoteDataSource: UserRemoteDataSource,
    private val networkMonitor: NetworkMonitor
) : UserRepository {

    /**
     * ユーザーリスト取得
     *
     * Offline-first:
     * 1. まずローカルキャッシュを返す
     * 2. バックグラウンドでリモートから取得
     * 3. 取得したデータでローカルを更新
     */
    override fun getUsers(): Flow<List<User>> {
        return localDataSource.getUsers()
            .onStart {
                // バックグラウンドでリモートから同期
                refreshUsersFromRemote()
            }
            .map { entities ->
                entities.map { it.toDomain() }
            }
    }
}
```

### Presentation Layer (ViewModel)

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListViewModel.kt

/**
 * ユーザーリスト画面の ViewModel
 *
 * UI 状態を管理し、ビジネスロジックを呼び出す
 */
class UserListViewModel(
    private val getUsersUseCase: GetUsersUseCase,
    private val coroutineScope: CoroutineScope
) {
    // UI State（単一の状態オブジェクト）
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    // 一時的なイベント用（Snackbar、ナビゲーションなど）
    private val _events = Channel<UserListEvent>(Channel.BUFFERED)
    val events: Flow<UserListEvent> = _events.receiveAsFlow()

    private var loadJob: Job? = null

    init {
        loadUsers()
    }

    /**
     * ユーザーリストを読み込む
     */
    fun loadUsers() {
        loadJob?.cancel()
        loadJob = coroutineScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            getUsersUseCase()
                .catch { e ->
                    _uiState.update {
                        it.copy(isLoading = false, error = e.toUiError())
                    }
                }
                .collect { users ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            users = users.map { user -> user.toUiModel() },
                            error = null
                        )
                    }
                }
        }
    }

    /**
     * ViewModel の破棄
     */
    fun onCleared() {
        loadJob?.cancel()
    }
}
```

---

## 命名規則

### クラス命名

| 種類 | サフィックス | 例 |
|------|------------|-----|
| ViewModel | ViewModel | `UserListViewModel` |
| UseCase | UseCase | `GetUsersUseCase` |
| Repository Interface | Repository | `UserRepository` |
| Repository Implementation | RepositoryImpl | `UserRepositoryImpl` |
| DataSource Interface | DataSource | `UserLocalDataSource` |
| SQLDelight Entity | Entity | `UserEntity` |
| API Response | Response | `UserResponse` |
| API Request | Request | `CreateUserRequest` |
| UI State | UiState | `UserListUiState` |
| UI Model | UiModel | `UserUiModel` |
| Event | Event | `UserListEvent` |
| Composable Screen | Screen | `UserListScreen` |
| expect 実装 | .{platform} | `Platform.android.kt`, `Platform.ios.kt` |

### 関数命名

| 種類 | パターン | 例 |
|------|---------|-----|
| 単一データ取得 | `get{Entity}` | `getUser(userId)` |
| 複数データ取得 | `get{Entity}s` / `get{Entity}List` | `getUsers()` |
| データ作成 | `create{Entity}` / `insert{Entity}` | `createUser()` |
| データ更新 | `update{Entity}` | `updateUser()` |
| データ削除 | `delete{Entity}` | `deleteUser()` |
| イベントハンドラー | `on{Event}` / `on{Event}Click` | `onUserClick()` |
| 変換 | `to{Target}` | `toDomain()`, `toEntity()`, `toUiModel()` |

---

## ベストプラクティス チェックリスト

### Shared Module (shared)

- [ ] ビジネスロジック（Domain Layer）を commonMain に配置
- [ ] データアクセス（Data Layer）を commonMain に配置
- [ ] ViewModel を commonMain に配置
- [ ] プラットフォーム固有コードは expect/actual で抽象化
- [ ] UI は Compose Multiplatform またはプラットフォームごとにネイティブ

### expect/actual

- [ ] プラットフォーム固有の実装を最小限に
- [ ] まず共通インターフェースを設計
- [ ] actual 実装はプラットフォームのベストプラクティスに従う
- [ ] テスト用に commonTest で Fake 実装を準備

### 依存性注入（Koin）

- [ ] 共通モジュールを sharedModule で定義
- [ ] プラットフォーム固有を platformModule で定義
- [ ] ViewModel は Factory 経由で作成
- [ ] テスト用に Fake 注入を有効化

### データ永続化（SQLDelight）

- [ ] スキーマを共通で定義
- [ ] Driver をプラットフォームごとに実装
- [ ] トランザクションを適切に使用
- [ ] Flow で変更を監視

### ネットワーク（Ktor）

- [ ] HttpClient を DI で管理
- [ ] エンジンをプラットフォームごとに設定
- [ ] エラーハンドリングを統一
- [ ] Serialization に kotlinx-serialization を使用

### 状態管理

- [ ] UI State を単一のデータクラスで管理
- [ ] StateFlow で状態を公開
- [ ] 一時的なイベントには Channel を使用
- [ ] UDF（単方向データフロー）に従う

### テスト

- [ ] commonTest でユニットテストを実装
- [ ] Fake を優先、Mock は最小限
- [ ] コルーチンテストには runTest を使用
- [ ] テストユーティリティを集約

### エラーハンドリング

- [ ] AppException 階層を定義
- [ ] 共通のエラーマッピングをプラットフォーム間で使用
- [ ] UI エラーモデルに変換
- [ ] リトライ機構を実装

---

## 参考リンク

### 公式ドキュメント

- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html)
- [Kotlin Multiplatform: プロジェクト構造](https://kotlinlang.org/docs/multiplatform-discover-project.html)
- [expect/actual 宣言](https://kotlinlang.org/docs/multiplatform-expect-actual.html)
- [Compose Multiplatform](https://www.jetbrains.com/lp/compose-multiplatform/)

### ライブラリ

- [Ktor](https://ktor.io/docs/getting-started-ktor-client.html)
- [SQLDelight](https://cashapp.github.io/sqldelight/)
- [Koin](https://insert-koin.io/docs/reference/koin-mp/kmp/)
- [kotlinx-datetime](https://github.com/Kotlin/kotlinx-datetime)
- [kotlinx-serialization](https://github.com/Kotlin/kotlinx.serialization)
