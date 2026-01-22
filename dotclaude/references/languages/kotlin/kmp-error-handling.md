# KMP Error Handling

Common error types and UI error display patterns in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md)

---

## Common Error Types

```kotlin
// commonMain/kotlin/com/example/shared/core/error/AppException.kt

/**
 * Application exception hierarchy
 */
sealed class AppException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    // Network errors
    sealed class Network(message: String, cause: Throwable?) : AppException(message, cause) {
        class NoConnection(cause: Throwable? = null) : Network("No internet connection", cause)
        class Timeout(cause: Throwable? = null) : Network("Request timeout", cause)
        class Server(val code: Int, cause: Throwable? = null) : Network("Server error: $code", cause)
    }

    // Data errors
    sealed class Data(message: String, cause: Throwable?) : AppException(message, cause) {
        class NotFound(message: String = "Data not found") : Data(message, null)
        class Validation(message: String) : Data(message, null)
        class Conflict(message: String) : Data(message, null)
    }

    // Authentication errors
    sealed class Auth(message: String, cause: Throwable?) : AppException(message, cause) {
        object Unauthorized : Auth("Unauthorized", null)
        object SessionExpired : Auth("Session expired", null)
    }

    // Unknown error
    class Unknown(cause: Throwable) : AppException("Unknown error", cause)
}
```

---

## UI Error Model

```kotlin
// commonMain/kotlin/com/example/shared/presentation/model/UiError.kt

/**
 * UI error model
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
 * Throwable → UiError conversion
 */
fun Throwable.toUiError(): UiError {
    return when (this) {
        is AppException.Network.NoConnection -> UiError(
            message = "No internet connection",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Timeout -> UiError(
            message = "Request timed out",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Server -> UiError(
            message = "Server error occurred ($code)",
            action = ErrorAction.RETRY
        )
        is AppException.Auth.Unauthorized -> UiError(
            message = "Authentication required",
            action = ErrorAction.LOGIN
        )
        is AppException.Auth.SessionExpired -> UiError(
            message = "Session has expired",
            action = ErrorAction.LOGIN
        )
        is AppException.Data.NotFound -> UiError(
            message = message,
            action = ErrorAction.DISMISS
        )
        else -> UiError(
            message = "An error occurred",
            action = ErrorAction.DISMISS
        )
    }
}
```

---

## Ktor Error Handling

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiErrorMapper.kt

/**
 * Map Ktor response to application exception
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

## Best Practices

- Define AppException hierarchy
- Use common error mapping across platforms
- Convert to UI error model
- Implement retry mechanism
