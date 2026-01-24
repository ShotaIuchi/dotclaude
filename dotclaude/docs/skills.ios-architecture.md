# iOS Architecture スキル

## 概要

Apple 公式ガイドラインに基づいた SwiftUI + MVVM / 状態管理パターンのスキル。

---

## 使用場面

以下の場面で使用：

- iOS 機能の実装
- SwiftUI View の作成
- ViewModel のセットアップ
- async/await または Combine の利用
- MVVM パターンの適用

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

## 使用例

### @Observable (iOS 17+)

```swift
@Observable
final class UserListViewModel {
    private(set) var uiState = UserListUiState()

    func loadUsers() {
        Task {
            uiState = uiState.copy(isLoading: true)
            let users = try await getUsersUseCase.execute()
            uiState = uiState.copy(users: users, isLoading: false)
        }
    }
}
```

### SwiftUI View

```swift
struct UserListScreen: View {
    @State private var viewModel: UserListViewModel

    var body: some View {
        NavigationStack {
            UserListContent(uiState: viewModel.uiState)
        }
        .task { viewModel.loadUsers() }
    }
}
```

---

## 詳細リファレンス

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
- [iOS Architecture Details](../../references/platforms/ios/architecture.md)
