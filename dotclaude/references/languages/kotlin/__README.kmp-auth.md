# Review: kmp-auth.md

> Reviewed: 2026-01-22
> Original: dotclaude/references/languages/kotlin/kmp-auth.md

## 概要 (Summary)

このドキュメントは、Kotlin Multiplatform (KMP) + Ktor を使用した認証システム実装のベストプラクティスガイドです。複数のログイン方式のサポート、トークン管理、401 -> refresh -> retry パターンの標準実装について包括的に解説しています。対象読者は KMP で認証機能を実装するモバイルアプリケーション開発者であり、Android/iOS の両プラットフォームで一貫した認証ロジックを共有モジュールで実現することを目的としています。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [x] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [x] **情報の正確性 (Correct information)**: 記載内容が正確
- [ ] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | Session.kt (L154) | `Clock.System.now()` を使用しているが、インポート文に `kotlinx.datetime.Clock` が含まれていない | `import kotlinx.datetime.Clock` を追加するか、インポート文一覧に含める | Fixed (2026-01-22) |
| 2 | AuthPlugin.kt (L483-488) | `proceed(retryRequest.build())` において、`HttpRequestBuilder` から `HttpRequest` への変換が Ktor の API と一致しない可能性がある | Ktor のバージョンに応じた正確な API 使用方法を確認し、必要に応じて修正する | Fixed (2026-01-22) |
| 3 | TokenStore.android.kt (L988) | `init` ブロック内で `get()` を呼び出しているが、`get()` は `suspend` 関数であるため直接呼び出せない | `runBlocking` または `CoroutineScope` を使用するか、初期化ロジックを見直す | Fixed (2026-01-22) |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | 全体 | Ktor のバージョン情報が明記されていない | 動作確認済みの Ktor バージョンを明記する（例: Ktor 2.x 以上） | Fixed (2026-01-22) |
| 2 | iOS TokenStore | `runBlocking` の使用は iOS のメインスレッドでデッドロックを引き起こす可能性がある | 初期化を非同期で行うか、`LaunchedEffect` 等での遅延初期化を検討する | Fixed (2026-01-22) |
| 3 | DI Configuration | `HttpClientFactory` の生成時に `authRepository: get()` を渡しているが、循環依存の可能性がある | DI の初期化順序を明確にするか、`Lazy` インジェクションを使用する | Fixed (2026-01-22) |
| 4 | Error Handling | `LoginViewModel` のエラーメッセージが日本語でハードコードされている | 多言語対応を考慮し、リソース参照方式での実装例を追加する | Fixed (2026-01-22) |

### 将来の検討事項 (Future Considerations)

- **テストコード**: FakeTokenStore、FakeAuthRemoteDataSource の具体的な実装例を追加すると、テスト実装の参考になる
- **Biometric認証**: 生体認証（指紋/顔認証）との連携パターンの追加
- **Multi-factor Authentication (MFA)**: 2要素認証のフロー追加
- **Token Rotation**: セキュリティ強化のためのリフレッシュトークンローテーション戦略
- **Offline対応**: オフライン時の認証状態管理とキャッシュ戦略
- **Session Timeout**: 非アクティブ時の自動ログアウト実装パターン

## 総評 (Overall Assessment)

このドキュメントは、KMP での認証実装において非常に高品質なリファレンスガイドです。

**優れている点:**
- アーキテクチャの全体像から詳細な実装コードまで、段階的に説明されており理解しやすい
- 図解（ASCII アート）を用いたレイヤー構造の説明が視覚的に分かりやすい
- 複数のログイン方式を `LoginMethod` sealed class で抽象化し、拡張性を確保している
- 401 -> refresh -> retry パターンの Mutex による排他制御が適切に実装されている
- expect/actual パターンを使用したプラットフォーム固有実装の分離が明確
- タスクブレークダウンが実装手順として活用できるチェックリスト形式で提供されている

**改善が望まれる点:**
- 一部のコード例に軽微な技術的問題（suspend 関数の呼び出し、インポート文の欠落）がある
- 使用ライブラリのバージョン情報が明記されていない
- テストコードの具体的な実装例がない

総合的に、このドキュメントは KMP 認証実装のベストプラクティスとして十分な品質を持っており、軽微な修正を行うことでさらに実用性が向上します。特に、Ktor の認証プラグイン実装と複数ログイン方式の抽象化パターンは、実際のプロジェクトでそのまま参考にできる価値の高い内容です。

**推奨アクション:**
1. 優先度高の技術的問題（suspend関数呼び出し、インポート文）を修正する
2. 使用ライブラリのバージョン情報を追記する
3. 将来的にテストコード例と生体認証連携パターンを追加する
