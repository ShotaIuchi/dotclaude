# KMP expect/actual Pattern

A pattern for abstracting platform-specific implementations behind common interfaces.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [Official Documentation](https://kotlinlang.org/docs/multiplatform-expect-actual.html)

---

## Basic expect/actual

### Platform Information

```kotlin
// commonMain/kotlin/com/example/shared/core/platform/Platform.kt

/**
 * Platform information (expect declaration)
 */
expect class Platform() {
    val name: String
    val version: String
}

/**
 * Platform-specific utility
 */
expect fun getPlatformName(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/platform/Platform.android.kt

/**
 * Android implementation
 */
actual class Platform actual constructor() {
    actual val name: String = "Android"
    actual val version: String = "${android.os.Build.VERSION.SDK_INT}"
}

actual fun getPlatformName(): String = "Android ${android.os.Build.VERSION.SDK_INT}"
```

```kotlin
// iosMain/kotlin/com/example/shared/core/platform/Platform.ios.kt

import platform.UIKit.UIDevice

/**
 * iOS implementation
 */
actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName()
    actual val version: String = UIDevice.currentDevice.systemVersion
}

actual fun getPlatformName(): String =
    "${UIDevice.currentDevice.systemName()} ${UIDevice.currentDevice.systemVersion}"
```

---

## Network Monitoring

```kotlin
// commonMain/kotlin/com/example/shared/core/network/NetworkMonitor.kt

/**
 * Network state monitoring (expect declaration)
 */
expect class NetworkMonitor {
    fun isOnline(): Boolean
    fun observeNetworkState(): Flow<Boolean>
}
```

```kotlin
// androidMain/kotlin/com/example/shared/core/network/NetworkMonitor.android.kt

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest

/**
 * Android implementation
 */
actual class NetworkMonitor(
    private val context: Context
) {
    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    actual fun isOnline(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    actual fun observeNetworkState(): Flow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(true)
            }

            override fun onLost(network: Network) {
                trySend(false)
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(request, callback)

        // Initial state
        trySend(isOnline())

        awaitClose {
            connectivityManager.unregisterNetworkCallback(callback)
        }
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/core/network/NetworkMonitor.ios.kt

import platform.Network.*
import platform.darwin.dispatch_get_main_queue

/**
 * iOS implementation
 */
actual class NetworkMonitor {
    private val monitor = nw_path_monitor_create()
    private var currentPath: nw_path_t? = null

    init {
        nw_path_monitor_set_update_handler(monitor) { path ->
            currentPath = path
        }
        nw_path_monitor_set_queue(monitor, dispatch_get_main_queue())
        nw_path_monitor_start(monitor)
    }

    actual fun isOnline(): Boolean {
        val path = currentPath ?: return false
        return nw_path_get_status(path) == nw_path_status_satisfied
    }

    actual fun observeNetworkState(): Flow<Boolean> = callbackFlow {
        nw_path_monitor_set_update_handler(monitor) { path ->
            val isConnected = nw_path_get_status(path) == nw_path_status_satisfied
            trySend(isConnected)
        }

        awaitClose {
            nw_path_monitor_cancel(monitor)
        }
    }
}
```

---

## UUID Generation

```kotlin
// commonMain/kotlin/com/example/shared/core/util/Uuid.kt

/**
 * UUID generation (expect declaration)
 */
expect fun randomUUID(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/util/Uuid.android.kt

import java.util.UUID

/**
 * Android implementation
 */
actual fun randomUUID(): String = UUID.randomUUID().toString()
```

```kotlin
// iosMain/kotlin/com/example/shared/core/util/Uuid.ios.kt

import platform.Foundation.NSUUID

/**
 * iOS implementation
 */
actual fun randomUUID(): String = NSUUID().UUIDString()
```

---

## Best Practices

- Keep platform-specific implementations to a minimum
- Design common interfaces first
- Follow platform Best Practices for actual implementations
- Prepare Fake implementations for testing in commonTest
