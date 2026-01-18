---
name: iOS Architecture
description: This skill should be used when implementing iOS features, creating SwiftUI views, setting up ViewModels, using async/await or Combine, or following MVVM patterns on iOS.
references:
  - path: ../../references/common/clean-architecture.md
  - path: ../../references/common/testing-strategy.md
  - path: ../../references/ios/architecture.md
external:
  - id: swift-concurrency
  - id: swiftui-docs
  - id: combine-docs
---

# iOS Architecture

Apple 公式ガイドラインに基づく SwiftUI + MVVM / State 管理パターン。

## 基本原則

1. **関心の分離** - UI ロジックとビジネスロジックを明確に分離
2. **データ駆動型 UI** - UI は状態（State）を反映するだけ
3. **単一の信頼できる情報源 (SSOT)** - Repository がデータの SSOT
4. **単方向データフロー (UDF)** - イベントは上流へ、状態は下流へ

```
Presentation Layer → Domain Layer → Data Layer
```

## レイヤー構成

| レイヤー | 責務 | 主要コンポーネント |
|---------|------|-------------------|
| Presentation | 画面表示・ユーザー操作 | View (SwiftUI), ViewModel |
| Domain | ビジネスロジック | UseCase, Domain Model |
| Data | データ取得・永続化 | Repository, DataSource, API |

## ディレクトリ構造

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

## 命名規則

| 種類 | 命名パターン | 例 |
|------|-------------|-----|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository | `{Entity}Repository` | `UserRepository` |

## 詳細リファレンス

- [クリーンアーキテクチャガイド](../../references/common/clean-architecture.md)
- [テスト戦略ガイド](../../references/common/testing-strategy.md)
- [iOS アーキテクチャ詳細](../../references/ios/architecture.md)
