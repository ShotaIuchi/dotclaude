# Testing Strategy Reference

プロジェクト共通のテスト戦略。

---

## 公式リソース

| Platform | Resource | URL |
|----------|----------|-----|
| Android | Testing Overview | https://developer.android.com/training/testing |
| Android | Testing Compose | https://developer.android.com/jetpack/compose/testing |
| iOS | XCTest | https://developer.apple.com/documentation/xctest |
| iOS | Swift Testing | https://developer.apple.com/documentation/testing |
| Kotlin | kotlin.test | https://kotlinlang.org/api/latest/kotlin.test/ |
| KMP | Turbine (Flow) | https://github.com/cashapp/turbine |

---

## テストピラミッド

```
        ╱ E2E ╲          少数・高コスト
       ╱ Integration ╲    中程度
      ╱   Unit Tests   ╲  多数・低コスト
```

| Level | 対象 | 実行速度 | カバレッジ目標 |
|-------|------|---------|---------------|
| Unit | UseCase, ViewModel, Mapper | 高速 | 80%+ |
| Integration | Repository + DataSource | 中速 | 重要パス |
| E2E / UI | 画面遷移・主要フロー | 低速 | クリティカルパス |

## プロジェクトテストルール

### 必須テスト

| 対象 | テスト必須 | 理由 |
|------|-----------|------|
| UseCase | ✅ | ビジネスロジックの正確性保証 |
| ViewModel | ✅ | 状態管理の正確性保証 |
| Repository | ⚠️ 推奨 | データフローの整合性 |
| Mapper | ⚠️ 推奨 | 変換の正確性 |
| UI Component | オプション | スナップショットテストを推奨 |

### テストダブル方針

| 種類 | 優先度 | 用途 |
|------|--------|------|
| Fake | ✅ 最優先 | 状態を持つテスト実装（FakeRepository） |
| Stub | ✅ 推奨 | 固定値を返すだけの実装 |
| Mock | ⚠️ 最小限 | 呼び出し検証が必要な場合のみ |

### テストの書き方

```
// Given (前提条件)
fakeRepository.users = [testUser()]

// When (操作)
viewModel.loadUsers()

// Then (検証)
assertEquals(expected, viewModel.uiState.value)
```

### 命名規則

| Platform | Pattern | Example |
|----------|---------|---------|
| Kotlin | バッククォート文 | `` `returns users when repository succeeds` `` |
| Swift | test_ プレフィックス | `test_loadUsers_success_returnsUsers()` |

## CI テスト戦略

| トリガー | 実行テスト |
|---------|-----------|
| PR 作成/更新 | Unit + Lint |
| main マージ | Unit + Integration |
| リリース | Unit + Integration + E2E |
