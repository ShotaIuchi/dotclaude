# Android Architecture スキル

## 概要

Google 公式 Android Architecture Guide に基づいた MVVM / UDF / Repository パターンのスキル。

---

## 使用場面

以下の場面で使用：

- Android 機能の実装
- ViewModel の作成
- Repository のセットアップ
- Hilt 依存性注入
- Jetpack Compose の実装
- MVVM/UDF パターンの適用

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

---

## 命名規則

| 種類 | パターン | 例 |
|------|----------|-----|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository | `{Entity}Repository` | `UserRepository` |

---

## 使用例

### Hilt DI

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

### Compose 状態管理

```kotlin
@Composable
fun UserListScreen(viewModel: UserListViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    UserListContent(users = uiState.users, onRefresh = viewModel::refresh)
}
```

---

## 詳細リファレンス

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
- [Kotlin Coroutines Guide](../../references/languages/kotlin/coroutines.md)
- [Android Architecture Details](../../references/platforms/android/architecture.md)
