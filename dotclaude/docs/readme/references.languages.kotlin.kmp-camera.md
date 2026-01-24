# KMP カメラ実装ガイド

KMP/CMP でカメラ機能を実装するためのベストプラクティス。OS ネイティブ機能との役割分担を明確にし、共有すべきものと OS に委譲すべきものを整理します。

---

## 概要

カメラ機能では、KMP/CMP と OS ネイティブの間で明確な役割分担を確立します。

```
🧠 KMP / CMP = "どう使うか"（UI、状態、ロジック）
📷 OS Native = "どう撮るか"（デバイス制御）
```

---

## 役割分担の原則

### KMP/CMP の責任

| 項目 | 説明 |
|------|------|
| シャッターボタン UI | ボタン配置、押下状態 |
| 前後カメラ切り替え | カメラ方向の状態管理 |
| フラッシュ ON/OFF 状態 | フラッシュ設定の状態管理 |
| 撮影中/完了の状態管理 | UiState での状態表現 |
| 撮影結果の処理 | アップロード、解析、保存 |

### OS に委譲

| 項目 | Android | iOS |
|------|---------|-----|
| カメラの開始/停止 | CameraX | AVFoundation |
| プレビュー表示 | PreviewView | AVCaptureVideoPreviewLayer |
| フォーカス/露出 | CameraControl | AVCaptureDevice |
| センサー回転 | ImageAnalysis | AVCaptureConnection |
| サーフェス管理 | SurfaceProvider | CALayer |

---

## 依存関係図

```
┌─────────────────────────────────────────────────────────────────────┐
│                      CMP UI Layer                                    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   CameraScreen (Compose Multiplatform)                        │   │
│  │   - シャッターボタン                                           │   │
│  │   - 設定 UI（フラッシュ、カメラ切り替え）                      │   │
│  │   - プレビューエリア（expect/actual）                         │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    KMP ViewModel / UseCase                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   CameraViewModel                                             │   │
│  │   - CameraUiState 管理                                        │   │
│  │   - onShutterClick / onToggleFlash / onSwitchCamera           │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    expect CameraController                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   - startPreview()                                            │   │
│  │   - stopPreview()                                             │   │
│  │   - capture(): CameraResult                                   │   │
│  │   - switchCamera()                                            │   │
│  │   - setFlash(enabled: Boolean)                                │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
┌─────────────────────────────┐  ┌─────────────────────────────┐
│  actual (Android)           │  │  actual (iOS)               │
│  ┌───────────────────────┐  │  │  ┌───────────────────────┐  │
│  │  AndroidCameraController │  │  │  IOSCameraController  │  │
│  │  (CameraX)             │  │  │  (AVFoundation)        │  │
│  └───────────────────────┘  │  │  └───────────────────────┘  │
└─────────────────────────────┘  └─────────────────────────────┘
```

---

## 共有モデル

### CameraResult

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraResult.kt

/**
 * 撮影結果
 */
sealed interface CameraResult {
    /**
     * 撮影成功
     * @param imageData JPEG バイト配列
     * @param width 画像の幅
     * @param height 画像の高さ
     */
    data class Success(
        val imageData: ByteArray,
        val width: Int,
        val height: Int
    ) : CameraResult

    /**
     * 撮影失敗
     */
    data class Error(val message: String) : CameraResult

    /**
     * キャンセル
     */
    object Cancelled : CameraResult
}
```

### CameraConfig

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraConfig.kt

/**
 * カメラ設定
 */
data class CameraConfig(
    val facing: CameraFacing = CameraFacing.BACK,
    val flashMode: FlashMode = FlashMode.OFF,
    val aspectRatio: AspectRatio = AspectRatio.RATIO_4_3
)

enum class CameraFacing { FRONT, BACK }

enum class FlashMode { OFF, ON, AUTO }

enum class AspectRatio { RATIO_4_3, RATIO_16_9 }
```

---

## ViewModel と UiState

### CameraUiState

```kotlin
// commonMain/kotlin/com/example/shared/presentation/camera/CameraUiState.kt

/**
 * カメラ画面の UI 状態
 */
data class CameraUiState(
    val isFlashOn: Boolean = false,
    val isFrontCamera: Boolean = false,
    val isCapturing: Boolean = false,
    val lastCapturedImage: ByteArray? = null,
    val error: CameraError? = null,
    val permissionState: PermissionState = PermissionState.NOT_REQUESTED
) {
    /**
     * 撮影可能かどうか
     */
    val canCapture: Boolean
        get() = !isCapturing && permissionState == PermissionState.GRANTED

    /**
     * プレビュー表示可能かどうか
     */
    val showPreview: Boolean
        get() = permissionState == PermissionState.GRANTED
}

/**
 * カメラエラー
 */
sealed interface CameraError {
    data class CaptureError(val message: String) : CameraError
    object PermissionDenied : CameraError
    object CameraUnavailable : CameraError
}

/**
 * 権限状態
 */
enum class PermissionState {
    NOT_REQUESTED,
    GRANTED,
    DENIED
}
```

### CameraViewModel

```kotlin
// commonMain/kotlin/com/example/shared/presentation/camera/CameraViewModel.kt

/**
 * カメラ画面の ViewModel
 */
class CameraViewModel(
    private val cameraController: CameraController,
    private val coroutineScope: CoroutineScope
) {
    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()

    private val _events = Channel<CameraEvent>(Channel.BUFFERED)
    val events: Flow<CameraEvent> = _events.receiveAsFlow()

    /**
     * シャッターボタン押下
     */
    fun onShutterClick() {
        if (!_uiState.value.canCapture) return

        coroutineScope.launch {
            _uiState.update { it.copy(isCapturing = true) }

            when (val result = cameraController.capture()) {
                is CameraResult.Success -> {
                    _uiState.update {
                        it.copy(
                            isCapturing = false,
                            lastCapturedImage = result.imageData
                        )
                    }
                    _events.send(CameraEvent.CaptureComplete(result.imageData))
                }
                is CameraResult.Error -> {
                    _uiState.update {
                        it.copy(
                            isCapturing = false,
                            error = CameraError.CaptureError(result.message)
                        )
                    }
                }
                is CameraResult.Cancelled -> {
                    _uiState.update { it.copy(isCapturing = false) }
                }
            }
        }
    }

    /**
     * フラッシュ切り替え
     */
    fun onToggleFlash() {
        val newFlashState = !_uiState.value.isFlashOn
        _uiState.update { it.copy(isFlashOn = newFlashState) }
        cameraController.setFlashMode(if (newFlashState) FlashMode.ON else FlashMode.OFF)
    }

    /**
     * カメラ切り替え
     */
    fun onSwitchCamera() {
        coroutineScope.launch {
            cameraController.switchCamera()
            _uiState.update {
                it.copy(isFrontCamera = cameraController.getCurrentFacing() == CameraFacing.FRONT)
            }
        }
    }
}
```

---

## QR / 画像解析

### AnalysisResult

```kotlin
// commonMain/kotlin/com/example/shared/analysis/AnalysisResult.kt

/**
 * 画像解析結果
 */
sealed interface AnalysisResult {
    /** QR コード */
    data class QrCode(val content: String) : AnalysisResult

    /** バーコード */
    data class Barcode(val format: BarcodeFormat, val value: String) : AnalysisResult

    /** テキスト（OCR） */
    data class Text(val blocks: List<String>) : AnalysisResult

    /** 解析失敗 */
    data class Error(val message: String) : AnalysisResult

    /** 検出なし */
    object NotFound : AnalysisResult
}
```

---

## 判断基準表

| 目的 | アプローチ | 備考 |
|------|-----------|------|
| 写真撮影のみ | 最適 - 基本設定で十分 | CameraController + ViewModel |
| QR/バーコード読み取り | 最適 - OS 側で解析 | ImageAnalyzer expect/actual |
| OCR（テキスト認識） | 良好 - OS 側で解析 | ML Kit / Vision Text |
| 動画録画 | 普通 - 共有は最小限 | 複雑、OS 依存度高 |
| 連写 | 普通 - OS 依存度高 | CameraX / AVFoundation 個別実装 |
| リアルタイム解析 | 普通 - パフォーマンス考慮 | カメラプレビュー中の解析 |
| 高度な制御（露出、ISO） | 非推奨 - OS 固有実装 | プラットフォーム固有 API |
| AR 機能 | 非推奨 - OS 固有実装 | ARCore / ARKit |

---

## リアルタイム解析

カメラプレビュー中にフレームを解析する実装パターン。QR スキャナーなどに使用。

### 設計ポイント

1. **解析頻度の制御** - 全フレーム解析は不要（CPU/バッテリー消費大）、100-500ms 間隔で十分
2. **バックグラウンドスレッドで解析** - UI スレッドをブロックしない
3. **共有範囲** - 解析ロジックの呼び出しと結果処理は KMP、フレーム取得は OS ネイティブ

### パフォーマンス注意点

| 項目 | 推奨値 | 理由 |
|------|-------|------|
| 解析間隔 | 100-500ms | CPU/バッテリー節約 |
| バックプレッシャー | KEEP_ONLY_LATEST | メモリ節約 |
| 解析スレッド | 専用スレッド | UI ブロック防止 |
| 解析停止 | 検出成功時 | 二重検出防止 |

---

## 権限管理

### CameraPermission expect/actual

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraPermission.kt

/**
 * カメラ権限管理（expect 宣言）
 */
expect class CameraPermission {
    /**
     * 権限状態を確認
     */
    fun checkPermission(): PermissionState

    /**
     * 権限をリクエスト
     * @param onResult 結果コールバック
     */
    fun requestPermission(onResult: (Boolean) -> Unit)
}
```

---

## ベストプラクティス チェックリスト

### 役割分担

- [ ] UI と状態管理は KMP/CMP で共有
- [ ] カメラデバイス制御は OS ネイティブに委譲
- [ ] 画像解析は OS の ML ライブラリを使用

### expect/actual

- [ ] CameraController を expect 宣言で抽象化
- [ ] Android は CameraX を使用
- [ ] iOS は AVFoundation を使用
- [ ] 共有モデル（CameraResult など）は commonMain に配置

### ViewModel

- [ ] 撮影状態を CameraUiState で管理
- [ ] 権限状態を UiState に含める
- [ ] 一時的な通知は events（CameraEvent）で

### 権限

- [ ] 起動時に権限チェックを実行
- [ ] 拒否時は設定画面へのナビゲーションを提供
- [ ] UiState で状態を管理

### 画像解析

- [ ] AnalysisResult を共有モデルとして定義
- [ ] Android は ML Kit、iOS は Vision を使用
- [ ] リアルタイム解析はパフォーマンスを考慮

---

## 参考リンク

### 公式ドキュメント

- [CameraX (Android)](https://developer.android.com/training/camerax)
- [AVFoundation (iOS)](https://developer.apple.com/av-foundation/)
- [ML Kit Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning)
- [Vision Framework (iOS)](https://developer.apple.com/documentation/vision)

### KMP 関連

- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html)
- [expect/actual 宣言](https://kotlinlang.org/docs/multiplatform-expect-actual.html)
