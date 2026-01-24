# KMP エラーハンドリング

Kotlin Multiplatform における共通エラー型と UI エラー表示パターン。

---

## 概要

効果的なエラーハンドリングは、共通のエラー階層を定義し、ユーザーフレンドリーなメッセージに変換することで、一貫したエラー処理を実現します。

---

## 共通エラー型

```kotlin
// commonMain/kotlin/com/example/shared/core/error/AppException.kt

/**
 * アプリケーション例外階層
 */
sealed class AppException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    // ネットワークエラー
    sealed class Network(message: String, cause: Throwable?) : AppException(message, cause) {
        class NoConnection(cause: Throwable? = null) : Network("インターネット接続がありません", cause)
        class Timeout(cause: Throwable? = null) : Network("リクエストがタイムアウトしました", cause)
        class Server(val code: Int, cause: Throwable? = null) : Network("サーバーエラー: $code", cause)
    }

    // データエラー
    sealed class Data(message: String, cause: Throwable?) : AppException(message, cause) {
        class NotFound(message: String = "データが見つかりません") : Data(message, null)
        class Validation(message: String) : Data(message, null)
        class Conflict(message: String) : Data(message, null)
    }

    // 認証エラー
    sealed class Auth(message: String, cause: Throwable?) : AppException(message, cause) {
        object Unauthorized : Auth("認証が必要です", null)
        object SessionExpired : Auth("セッションが期限切れです", null)
    }

    // 不明なエラー
    class Unknown(cause: Throwable) : AppException("不明なエラー", cause)
}
```

---

## UI エラーモデル

```kotlin
// commonMain/kotlin/com/example/shared/presentation/model/UiError.kt

/**
 * UI エラーモデル
 */
data class UiError(
    val message: String,
    val action: ErrorAction? = null
)

enum class ErrorAction {
    RETRY,
    LOGIN,
    DISMISS
}

/**
 * Throwable → UiError 変換
 */
fun Throwable.toUiError(): UiError {
    return when (this) {
        is AppException.Network.NoConnection -> UiError(
            message = "インターネット接続がありません",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Timeout -> UiError(
            message = "リクエストがタイムアウトしました",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Server -> UiError(
            message = "サーバーエラーが発生しました ($code)",
            action = ErrorAction.RETRY
        )
        is AppException.Auth.Unauthorized -> UiError(
            message = "認証が必要です",
            action = ErrorAction.LOGIN
        )
        is AppException.Auth.SessionExpired -> UiError(
            message = "セッションが期限切れです",
            action = ErrorAction.LOGIN
        )
        is AppException.Data.NotFound -> UiError(
            message = message,
            action = ErrorAction.DISMISS
        )
        else -> UiError(
            message = "エラーが発生しました",
            action = ErrorAction.DISMISS
        )
    }
}

/**
 * ローカライズサポート
 *
 * 多言語アプリケーションでは、ハードコードされた文字列をローカライズされたリソースに置き換えます：
 * - Android: stringResource(R.string.error_no_connection) を使用
 * - iOS: Swift UI レイヤーで NSLocalizedString または String(localized:) を使用
 * - 共通: 共有文字列のために expect/actual を使用した StringResources インターフェースを検討
 */
```

---

## Ktor エラーハンドリング

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiErrorMapper.kt

/**
 * Ktor レスポンスをアプリケーション例外にマッピング
 */
class ApiErrorMapper {

    fun map(response: HttpResponse): AppException {
        return when (response.status.value) {
            401 -> AppException.Auth.Unauthorized
            403 -> AppException.Auth.Unauthorized
            404 -> AppException.Data.NotFound()
            409 -> AppException.Data.Conflict("リソースは既に存在します")
            in 500..599 -> AppException.Network.Server(response.status.value)
            else -> AppException.Unknown(
                Exception("HTTP ${response.status.value}: ${response.status.description}")
            )
        }
    }

    fun map(throwable: Throwable): AppException {
        return when (throwable) {
            is AppException -> throwable
            is kotlinx.io.IOException -> AppException.Network.NoConnection(throwable)
            is io.ktor.client.plugins.HttpRequestTimeoutException -> AppException.Network.Timeout(throwable)
            else -> AppException.Unknown(throwable)
        }
    }
}
```

---

## ベストプラクティス

- **AppException 階層を定義**: アプリケーションで発生し得るすべてのエラー状態を表す sealed class 階層を作成。これにより型安全性と網羅的な when 式処理が提供され、エラーケースの見落としを防止

- **プラットフォーム間で共通のエラーマッピングを使用**: エラーマッピングロジックを commonMain に集中化し、iOS と Android で一貫したエラーハンドリング動作を確保。プラットフォーム固有のバグを減らし、テストを簡素化

- **UI エラーモデルに変換**: 技術的な例外をユーザーフレンドリーなエラーメッセージと適切なアクションに変換。この分離によりプレゼンテーションロジックがクリーンに保たれ、エラーメッセージのローカライズが容易に

- **リトライ機構を実装**: 一時的なエラー（ネットワークタイムアウト、一時的なサーバー問題）には自動またはユーザー起動のリトライ機能を提供。サーバーへの過負荷を避けるため、自動リトライには指数バックオフを検討

---

## プラットフォーム固有のエラーハンドリング

プラットフォーム固有の例外を処理するために expect/actual を使用：

```kotlin
// commonMain/kotlin/com/example/shared/core/error/PlatformErrorMapper.kt

/**
 * プラットフォーム固有のエラーマッパー
 */
expect class PlatformErrorMapper() {
    fun mapPlatformException(throwable: Throwable): AppException?
}
```

```kotlin
// androidMain/kotlin/com/example/shared/core/error/PlatformErrorMapper.kt

actual class PlatformErrorMapper actual constructor() {
    actual fun mapPlatformException(throwable: Throwable): AppException? {
        return when (throwable) {
            is java.net.UnknownHostException -> AppException.Network.NoConnection(throwable)
            is java.net.SocketTimeoutException -> AppException.Network.Timeout(throwable)
            is javax.net.ssl.SSLException -> AppException.Network.NoConnection(throwable)
            else -> null
        }
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/core/error/PlatformErrorMapper.kt

actual class PlatformErrorMapper actual constructor() {
    actual fun mapPlatformException(throwable: Throwable): AppException? {
        // iOS ネットワークエラーは通常 Ktor によってラップされる
        // 必要に応じてプラットフォーム固有のハンドリングを追加
        return when {
            throwable.message?.contains("NSURLErrorDomain") == true ->
                AppException.Network.NoConnection(throwable)
            else -> null
        }
    }
}
```
