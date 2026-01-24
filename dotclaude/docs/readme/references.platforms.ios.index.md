# iOS リファレンス

## 概要

Apple 公式ガイドラインに基づいた iOS アプリ開発のリファレンス。
SwiftUI + MVVM、状態管理、async/await パターンを定義。

**対象 iOS バージョン: iOS 17+**

---

## ファイル一覧と優先度

| ファイル | 説明 | 優先度 |
|----------|------|--------|
| [architecture.md](architecture.md) | iOS SwiftUI/MVVM アーキテクチャ詳細 | 公式ガイド準拠 |

---

## 外部リンク

### 公式ドキュメント（最優先）

| リンク | 説明 | 優先度 |
|--------|------|--------|
| [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/) | UI フレームワーク | 必読 |
| [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) | 非同期処理 | 必読 |

### フレームワーク

| リンク | 説明 |
|--------|------|
| [Combine Framework](https://developer.apple.com/documentation/combine) | リアクティブ |
| [SwiftData](https://developer.apple.com/documentation/swiftdata) | データ永続化 (iOS 17+) |
| [Observation Framework](https://developer.apple.com/documentation/observation) | @Observable macro (iOS 17+) |

### テスト

| リンク | 説明 |
|--------|------|
| [XCTest](https://developer.apple.com/documentation/xctest) | テストフレームワーク |

---

## 関連リファレンス

- Clean Architecture - 共通アーキテクチャ原則
- Testing Strategy - テスト戦略

---

## 関連スキル

- **ios-architecture**: iOS機能の実装、SwiftUI View作成、ViewModel設定、async/await・Combine利用、MVVMパターン時に使用
