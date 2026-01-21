# KMP エラーハンドリング

Kotlin Multiplatform での共通エラー型と UI エラー表示パターン。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md)

---

## 共通エラー型

```kotlin
// commonMain/kotlin/com/example/shared/core/error/AppException.kt

/**
 * アプリケーション例外の階層
 */
sealed class AppException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    // ネットワークエラー
    sealed class Network(message: String, cause: Throwable?) : AppException(message, cause) {
        class NoConnection(cause: Throwable? = null) : Network("No internet connection", cause)
        class Timeout(cause: Throwable? = null) : Network("Request timeout", cause)
        class Server(val code: Int, cause: Throwable? = null) : Network("Server error: $code", cause)
    }

    // データエラー
    sealed class Data(message: String, cause: Throwable?) : AppException(message, cause) {
        class NotFound(message: String = "Data not found") : Data(message, null)
        class Validation(message: String) : Data(message, null)
        class Conflict(message: String) : Data(message, null)
    }

    // 認証エラー
    sealed class Auth(message: String, cause: Throwable?) : AppException(message, cause) {
        object Unauthorized : Auth("Unauthorized", null)
        object SessionExpired : Auth("Session expired", null)
    }

    // 不明なエラー
    class Unknown(cause: Throwable) : AppException("Unknown error", cause)
}
```

---

## UI エラーモデル

```kotlin
// commonMain/kotlin/com/example/shared/presentation/model/UiError.kt

/**
 * UI 用エラーモデル
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
            message = "サーバーエラーが発生しました（$code）",
            action = ErrorAction.RETRY
        )
        is AppException.Auth.Unauthorized -> UiError(
            message = "認証が必要です",
            action = ErrorAction.LOGIN
        )
        is AppException.Auth.SessionExpired -> UiError(
            message = "セッションの有効期限が切れました",
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
            409 -> AppException.Data.Conflict("Resource already exists")
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

- AppException の階層を定義
- プラットフォーム共通のエラーマッピング
- UI 用エラーモデルに変換
- リトライ機構の実装
