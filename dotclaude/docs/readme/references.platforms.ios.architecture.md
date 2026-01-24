# iOS アーキテクチャガイド

## 概要

Apple 公式ガイドラインに基づいた SwiftUI + MVVM / 状態管理のベストプラクティス。

---

## 基本原則

1. **関心の分離** - UI ロジックとビジネスロジックを明確に分離
2. **データ駆動 UI** - UI は状態を反映するのみ
3. **Single Source of Truth (SSOT)** - Repository がデータの SSOT
4. **Unidirectional Data Flow (UDF)** - イベントは上流へ、状態は下流へ

```
User Action -> View -> ViewModel -> UseCase -> Repository -> DataSource
                          |
                    State Update
                          |
              View が新しい状態で再描画
```

---

## レイヤー構造

| レイヤー | 責務 | 主要コンポーネント |
|----------|------|-------------------|
| Presentation | 画面表示とユーザーインタラクション | View (SwiftUI), ViewModel |
| Domain | ビジネスロジック | UseCase, Domain Model |
| Data | データ取得と永続化 | Repository, DataSource, API |

### Domain Layer 詳細

Domain Layer はフレームワーク非依存の純粋なビジネスロジックを含む：

- **UseCase**: 単一のビジネス操作をカプセル化（例: `GetUsersUseCase`）
- **Domain Model**: 純粋な Swift 構造体/クラス

---

## ディレクトリ構成

```
App/
├── Presentation/       # Presentation Layer
│   └── Feature/
│       ├── FeatureView.swift
│       ├── FeatureViewModel.swift
│       └── FeatureUiState.swift
├── Domain/             # Domain Layer
│   ├── Model/
│   └── UseCase/
├── Data/               # Data Layer
│   ├── Repository/
│   ├── Local/
│   └── Remote/
└── DI/                 # DI Container
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

## iOS バージョン選択ガイド

| 最小 iOS バージョン | 推奨アプローチ | 理由 |
|---------------------|----------------|------|
| iOS 17+ | `@Observable` | 最高パフォーマンス、ボイラープレート削減 |
| iOS 15-16 | `ObservableObject` | 後方互換性必須 |
| iOS 15+ 条件付き | 両パターン | `#available` チェックで分岐 |

---

## @Observable パターン (iOS 17+)

```swift
@Observable
final class UserListViewModel {
    private(set) var uiState = UserListUiState()

    private let getUsersUseCase: GetUsersUseCaseProtocol

    func loadUsers() {
        Task {
            uiState = uiState.copy(isLoading: true)
            let users = try await getUsersUseCase.execute()
            uiState = uiState.copy(users: users, isLoading: false)
        }
    }
}
```

---

## SwiftUI View

```swift
struct UserListScreen: View {
    @State private var viewModel: UserListViewModel

    var body: some View {
        NavigationStack {
            UserListContent(uiState: viewModel.uiState)
        }
        .task {
            viewModel.loadUsers()
        }
    }
}
```

---

## 非同期処理 (async/await)

```swift
// 並列実行
func fetchUserDetail(userId: String) async throws -> UserDetail {
    async let user = userRepository.getUser(userId: userId)
    async let posts = postRepository.getPostsByUser(userId: userId)

    return try await UserDetail(user: user, posts: posts)
}
```

---

## エラーハンドリング

```swift
enum AppError: Error, Equatable {
    case network(NetworkError)
    case data(DataError)
    case auth(AuthError)

    enum NetworkError: Equatable {
        case noConnection
        case timeout
        case server(code: Int)
    }
}
```

---

## 詳細リファレンス

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
