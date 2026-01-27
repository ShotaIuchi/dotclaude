# Clean Architecture Reference

プロジェクト共通のクリーンアーキテクチャ適用ルール。

---

## 公式リソース

| Resource | URL |
|----------|-----|
| Clean Architecture (Robert C. Martin) | https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html |
| Android Architecture Guide | https://developer.android.com/topic/architecture |
| iOS App Architecture (WWDC) | https://developer.apple.com/documentation/swiftui/model-data |

---

## レイヤー構成

```
UI Layer → Domain Layer → Data Layer
    ↑                         │
    └──────── State ──────────┘
```

| Layer | Responsibility | 依存方向 |
|-------|----------------|---------|
| UI (Presentation) | 画面表示・ユーザー操作 | Domain に依存 |
| Domain | ビジネスロジック | 何にも依存しない |
| Data | データ取得・永続化 | Domain に依存（Interface実装） |

## プロジェクト適用ルール

### 依存方向の厳守

- **外側 → 内側のみ**: UI → Domain → Data（Data は Domain の Interface を実装）
- **逆方向禁止**: Domain が UI や Data の具象に依存してはならない
- **DI で解決**: Interface は Domain に定義、Implementation は Data に配置

### UseCase ルール

| ルール | 説明 |
|--------|------|
| 単一責任 | 1 UseCase = 1 ビジネス操作 |
| 命名 | `{Action}{Entity}UseCase`（例: `GetUsersUseCase`） |
| 省略可 | 単純な CRUD で追加ロジックがない場合、Repository 直接呼び出しも可 |
| テスト必須 | UseCase は必ずユニットテストを書く |

### Repository ルール

| ルール | 説明 |
|--------|------|
| Interface/Impl分離 | Interface は Domain、Implementation は Data |
| SSOT | Repository がデータの Single Source of Truth |
| オフラインファースト | ローカルキャッシュ → API → ローカル保存 の順を推奨 |
| エラーラップ | 外部例外を AppException に変換 |

### Model 変換

```
API Response → Domain Model → UI Model (UiState)
DB Entity   ↗               ↘ UiModel
```

- 各レイヤーで独自のモデルを持つ
- Mapper で変換（`toDomain()`, `toEntity()`, `toUiModel()`）
- Domain Model はフレームワーク非依存の純粋な型

## UDF (Unidirectional Data Flow)

```
User Action → Event → ViewModel → UseCase → Repository
                         ↓
                    State 更新
                         ↓
                      UI 再描画
```

- ViewModel が唯一の状態管理者
- UI は状態を読み取るだけ（書き込みはイベント経由）
- 状態は immutable（copy で更新）
