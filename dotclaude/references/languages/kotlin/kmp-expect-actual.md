# KMP expect/actual パターン

プラットフォーム固有実装を共通インターフェースで抽象化するパターン。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md) | [公式ドキュメント](https://kotlinlang.org/docs/multiplatform-expect-actual.html)

---

## 基本的な expect/actual

### プラットフォーム情報

```kotlin
// commonMain/kotlin/com/example/shared/core/platform/Platform.kt

/**
 * プラットフォーム情報（expect 宣言）
 */
expect class Platform() {
    val name: String
    val version: String
}

/**
 * プラットフォーム固有のユーティリティ
 */
expect fun getPlatformName(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/platform/Platform.android.kt

/**
 * Android 実装
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
 * iOS 実装
 */
actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName()
    actual val version: String = UIDevice.currentDevice.systemVersion
}

actual fun getPlatformName(): String =
    "${UIDevice.currentDevice.systemName()} ${UIDevice.currentDevice.systemVersion}"
```

---

## ネットワーク監視

```kotlin
// commonMain/kotlin/com/example/shared/core/network/NetworkMonitor.kt

/**
 * ネットワーク状態監視（expect 宣言）
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
 * Android 実装
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

        // 初期状態
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
 * iOS 実装
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

## UUID 生成

```kotlin
// commonMain/kotlin/com/example/shared/core/util/Uuid.kt

/**
 * UUID 生成（expect 宣言）
 */
expect fun randomUUID(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/util/Uuid.android.kt

import java.util.UUID

/**
 * Android 実装
 */
actual fun randomUUID(): String = UUID.randomUUID().toString()
```

```kotlin
// iosMain/kotlin/com/example/shared/core/util/Uuid.ios.kt

import platform.Foundation.NSUUID

/**
 * iOS 実装
 */
actual fun randomUUID(): String = NSUUID().UUIDString()
```

---

## ベストプラクティス

- プラットフォーム固有の実装は最小限に
- 共通インターフェースを先に設計
- actual 実装はプラットフォームの Best Practice に従う
- テスト用の Fake 実装を commonTest に用意
