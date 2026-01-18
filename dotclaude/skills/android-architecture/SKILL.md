---
name: Android Architecture
description: This skill should be used when implementing Android features, creating ViewModels, setting up Repositories, using Hilt, implementing Jetpack Compose, or following MVVM/UDF patterns on Android.
---

# Android Architecture

Google公式 Android Architecture Guide に基づく MVVM / UDF / Repository パターン。

## 基本原則

1. **関心の分離** - UI ロジックとビジネスロジックを明確に分離
2. **データ駆動型 UI** - UI は状態（State）を反映するだけ
3. **単一の信頼できる情報源 (SSOT)** - Repository がデータの SSOT
4. **単方向データフロー (UDF)** - イベントは上流へ、状態は下流へ

```
UI Layer → Domain Layer → Data Layer
```

## レイヤー構成

| レイヤー | 責務 | 主要コンポーネント |
|---------|------|-------------------|
| UI | 画面表示・ユーザー操作 | Activity, Fragment, Compose, ViewModel |
| Domain | ビジネスロジック | UseCase |
| Data | データ取得・永続化 | Repository, DataSource, DAO, API |

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

| 種類 | 命名パターン | 例 |
|------|-------------|-----|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository | `{Entity}Repository` | `UserRepository` |

## 詳細リファレンス

より詳しい実装例やベストプラクティスは [references/ARCHITECTURE.md](references/ARCHITECTURE.md) を参照。
