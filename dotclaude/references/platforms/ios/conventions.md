# iOS Project Conventions

公式ドキュメントを補完するプロジェクト固有の規約・パターン。

---

## @Observable vs ObservableObject 判断基準

| 条件 | 選択 |
|------|------|
| iOS 17+ のみサポート | `@Observable` |
| iOS 15-16 サポート必要 | `ObservableObject` |
| 新規プロジェクト | `@Observable` 推奨 |

### @Observable（iOS 17+）

```swift
@MainActor
@Observable
final class UserListViewModel {
    private(set) var uiState = UserListUiState()

    func loadUsers() {
        uiState.isLoading = true
        Task {
            do {
                let users = try await getUsersUseCase.execute()
                uiState.users = users.map { $0.toUiModel() }
            } catch {
                uiState.error = error.toUiError()
            }
            uiState.isLoading = false
        }
    }
}
```

### ObservableObject（iOS 15-16）

```swift
@MainActor
final class UserListViewModel: ObservableObject {
    @Published private(set) var uiState = UserListUiState()
    // ...
}
```

## Store パターン

複数画面で共有するアプリ状態には Store パターンを使用:

```swift
@Observable
final class AuthStore {
    private(set) var currentUser: User?
    private(set) var isAuthenticated = false

    func signIn(credentials: Credentials) async throws { ... }
    func signOut() { ... }
}
```

- Store は `@Environment` 経由で SwiftUI に注入
- ViewModel は Store を依存として受け取る

## ディレクトリ構造

### Feature-based 構造（推奨）

```
App/
├── App/
│   ├── MyApp.swift
│   └── ContentView.swift
├── Core/
│   ├── Data/
│   │   ├── Network/
│   │   │   ├── APIClient.swift
│   │   │   └── APIEndpoint.swift
│   │   └── Database/
│   ├── DI/
│   │   └── DependencyContainer.swift
│   ├── Domain/
│   │   └── Model/
│   │       └── AppError.swift
│   └── UI/
│       ├── Component/
│       └── Theme/
├── Feature/
│   ├── User/
│   │   ├── Data/
│   │   │   ├── Repository/
│   │   │   ├── Local/
│   │   │   ├── Remote/
│   │   │   └── Mapper/
│   │   ├── Domain/
│   │   │   ├── Model/
│   │   │   ├── Repository/ (Protocol)
│   │   │   └── UseCase/
│   │   └── UI/
│   │       ├── List/
│   │       │   ├── UserListScreen.swift
│   │       │   ├── UserListViewModel.swift
│   │       │   └── UserListUiState.swift
│   │       └── Detail/
│   └── Auth/
│       ├── Data/
│       ├── Domain/
│       └── UI/
└── Tests/
    ├── UnitTests/
    └── UITests/
```

### プロジェクト規模別の選択

| 規模 | チーム | 構造 |
|------|--------|------|
| 小（<10画面） | 1-2人 | フラット構造 |
| 中（10-30画面） | 3-5人 | Feature-based |
| 大（30+画面） | 5+人 | Feature-based + モジュール分割 |

## 命名規則

### クラス/ファイル命名

| Type | Suffix | Example |
|------|--------|---------|
| SwiftUI View | `Screen` / `View` | `UserListScreen`, `UserCard` |
| ViewModel | `ViewModel` | `UserListViewModel` |
| UseCase | `UseCase` | `GetUsersUseCase` |
| Repository Protocol | `RepositoryProtocol` | `UserRepositoryProtocol` |
| Repository Impl | `Repository` | `UserRepository` |
| SwiftData Entity | `Entity` | `UserEntity` |
| API Response | `Response` | `UserResponse` |
| UI State | `UiState` | `UserListUiState` |
| UI Model | `UiModel` | `UserUiModel` |

### 関数命名

| Type | Pattern | Example |
|------|---------|---------|
| データ取得（単体） | `get{Entity}` | `getUser(userId:)` |
| データ取得（複数） | `get{Entity}s` | `getUsers()` |
| データ作成 | `create{Entity}` | `createUser(_:)` |
| イベントハンドラ | `on{Event}Tap` | `onUserTap(_:)` |
| 変換 | `to{Target}` | `toDomain()`, `toEntity()` |
| UseCase実行 | `execute` | `execute()` |

## エラーハンドリングパターン

### AppError 階層

```swift
enum AppError: Error {
    // Network
    case network(NetworkError)
    // Data
    case data(DataError)
    // Auth
    case auth(AuthError)

    enum NetworkError {
        case httpError(statusCode: Int)
        case timeout
        case noConnection
    }
    enum DataError {
        case notFound(String)
        case parseError
    }
    enum AuthError {
        case unauthorized
        case sessionExpired
    }
}
```

### UiError 変換

```swift
struct UiError: Identifiable {
    let id = UUID()
    let message: String
    let action: ErrorAction

    enum ErrorAction {
        case retry
        case login
        case dismiss
    }
}

extension AppError {
    func toUiError() -> UiError {
        switch self {
        case .network(.noConnection):
            return UiError(message: "ネットワーク接続を確認してください", action: .retry)
        case .auth(.sessionExpired):
            return UiError(message: "セッションが期限切れです", action: .login)
        default:
            return UiError(message: "エラーが発生しました", action: .retry)
        }
    }
}
```

## ベストプラクティスチェックリスト

### ViewModel
- [ ] UiState を単一の struct で管理
- [ ] `private(set)` で状態を読み取り専用に公開
- [ ] `@MainActor` で UI 更新を保証
- [ ] Task キャンセルを実装

### Repository
- [ ] Protocol と Implementation を分離
- [ ] オフラインファースト戦略を検討
- [ ] async/await でデータ取得
- [ ] DataSource の詳細を隠蔽

### UseCase
- [ ] 単一責任（1 UseCase = 1 操作）
- [ ] Protocol 定義でテスタビリティ確保
- [ ] 単純な場合は Repository 直接呼び出しも可

### SwiftUI
- [ ] View と ViewModel を分離
- [ ] Stateless / Stateful View を明確に区別
- [ ] `.task` で非同期処理を開始
- [ ] `@Observable` を活用して再描画を最適化（iOS 17+）

### DI
- [ ] Protocol 経由で依存を注入
- [ ] テスト用 Fake/Mock を容易に差し替え
- [ ] SwiftUI Environment と統合

### テスト
- [ ] UseCase / ViewModel のユニットテスト必須
- [ ] Mock より Fake を優先
- [ ] `@MainActor` でテスト実行
