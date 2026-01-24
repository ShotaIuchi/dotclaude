# Android アーキテクチャガイド

## 概要

Google 公式 Android Architecture Guide に基づいた MVVM / UDF / Repository パターンのベストプラクティス。

---

## 基本原則

1. **関心の分離** - UI ロジックとビジネスロジックを明確に分離
2. **データ駆動 UI** - UI は状態を反映するのみ
3. **Single Source of Truth (SSOT)** - Repository がデータの SSOT
4. **Unidirectional Data Flow (UDF)** - イベントは上流へ、状態は下流へ

```
UI Layer -> Domain Layer -> Data Layer
    ^                          |
    +-------- State -----------+
```

---

## レイヤー構造

| レイヤー | 責務 | 主要コンポーネント |
|----------|------|-------------------|
| UI | 画面表示とユーザーインタラクション | Activity, Fragment, Compose, ViewModel |
| Domain | ビジネスロジック（オプション） | UseCase, Domain Model |
| Data | データ取得と永続化 | Repository, DataSource, DAO, API |

### Domain Layer 詳細

Domain Layer はオプションだが、複雑なアプリでは推奨：

- **UseCase**: 単一のビジネス操作をカプセル化。UI と Data 層を調整。
- **Domain Model**: フレームワーク依存のない純粋な Kotlin データクラス。

---

## ディレクトリ構成

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

---

## 命名規則

| 種類 | パターン | 例 |
|------|----------|-----|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository | `{Entity}Repository` | `UserRepository` |

---

## Hilt 依存性注入

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DataModule {
    @Provides
    @Singleton
    fun provideUserRepository(api: UserApi, dao: UserDao): UserRepository =
        UserRepositoryImpl(api, dao)
}
```

---

## Jetpack Compose 状態管理

```kotlin
@Composable
fun UserListScreen(viewModel: UserListViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    UserListContent(
        users = uiState.users,
        onRefresh = viewModel::refresh
    )
}
```

---

## エラーハンドリング

Sealed class で Result を表現：

```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val exception: Throwable) : Result<Nothing>()
    object Loading : Result<Nothing>()
}
```

---

## 使用例

```kotlin
// ViewModel での使用
fun loadUsers() {
    viewModelScope.launch {
        getUsersUseCase().collect { result ->
            _uiState.value = when (result) {
                is Result.Success -> UserListUiState.Success(result.data)
                is Result.Error -> UserListUiState.Error(result.exception.message)
                is Result.Loading -> UserListUiState.Loading
            }
        }
    }
}
```

---

## 詳細リファレンス

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
- [Kotlin Coroutines Guide](../../references/languages/kotlin/coroutines.md)
