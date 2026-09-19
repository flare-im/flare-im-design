package com.flare.im.ui

import androidx.annotation.RequiresApi
import android.content.ActivityNotFoundException
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.LocalOnBackPressedDispatcherOwner
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.window.DialogWindowProvider
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withTimeout
import kotlin.coroutines.cancellation.CancellationException

// Layer 5 — Platform Contract (shared truth: spec/platform-contract.json).
// One capability record, one adapter interface and one error model. The host
// declares what it can do and performs the native work (ActivityResult
// contracts, share intents …); components read capabilities through
// [flarePlatform] and never branch on platform identity.

enum class FlarePlatformKind { Web, Tauri, Ios, Android, Flutter }

enum class FlareCapabilitySupport { Supported, Fallback, Unsupported }

enum class FlarePointerKind { Fine, Coarse, Mixed, Unknown }

enum class FlarePlatformErrorCode { UNSUPPORTED, CANCELLED, PERMISSION_DENIED, TIMEOUT, FAILED }

data class FlarePlatformCapabilities(
    val pointer: FlarePointerKind = FlarePointerKind.Unknown,
    val hover: Boolean = false,
    val contextMenu: Boolean = false,
    val keyboardShortcut: Boolean = false,
    /** Contextual layers present as bottom sheets (phone form factor). */
    val bottomSheet: Boolean = false,
    val nativeBack: Boolean = false,
    val safeArea: Boolean = false,
    val filePicker: FlareCapabilitySupport = FlareCapabilitySupport.Unsupported,
    val imagePicker: FlareCapabilitySupport = FlareCapabilitySupport.Unsupported,
    val share: FlareCapabilitySupport = FlareCapabilitySupport.Unsupported,
) {
    companion object {
        /** What an Android phone / tablet determines on its own; pickers stay unsupported until the host adapter declares them. */
        fun android(widthDp: Int = Int.MAX_VALUE, hasPointer: Boolean = false): FlarePlatformCapabilities = FlarePlatformCapabilities(
            pointer = if (hasPointer) FlarePointerKind.Mixed else FlarePointerKind.Coarse,
            hover = hasPointer,
            contextMenu = hasPointer,
            keyboardShortcut = hasPointer,
            bottomSheet = widthDp < 600,
            nativeBack = true,
            safeArea = true,
        )
    }
}

/** The contract's error model; [cause] keeps the original throwable. */
class FlarePlatformError(
    val code: FlarePlatformErrorCode,
    message: String? = null,
    cause: Throwable? = null,
) : Exception(message, cause) {
    override fun toString(): String = "FlarePlatformError($code${message?.let { ": $it" } ?: ""})"
}

/** `Ok(value)` or `Err(error)` — the only two shapes an adapter operation returns. */
sealed class FlarePlatformResult<out T> {
    data class Ok<T>(val value: T) : FlarePlatformResult<T>()
    data class Err(val error: FlarePlatformError) : FlarePlatformResult<Nothing>()

    val isOk: Boolean get() = this is Ok
    val valueOrNull: T? get() = (this as? Ok<T>)?.value
    val errorOrNull: FlarePlatformError? get() = (this as? Err)?.error
    val code: FlarePlatformErrorCode? get() = errorOrNull?.code

    companion object {
        fun failure(code: FlarePlatformErrorCode, message: String? = null, cause: Throwable? = null): Err =
            Err(FlarePlatformError(code, message, cause))
    }
}

data class FlarePickedFile(
    val name: String,
    val size: Long? = null,
    val mimeType: String? = null,
    /** Native filesystem path when the platform exposes one. */
    val path: String? = null,
    /** Content uri when the platform exposes one instead of a path. */
    val uri: String? = null,
)

data class FlarePickFilesOptions(val multiple: Boolean = false, val accept: List<String> = emptyList())

data class FlarePickImagesOptions(val multiple: Boolean = false, val video: Boolean = false)

data class FlareSharePayload(
    val title: String? = null,
    val text: String? = null,
    val url: String? = null,
    val files: List<FlarePickedFile> = emptyList(),
)

data class FlareSafeAreaInsets(val top: Float = 0f, val right: Float = 0f, val bottom: Float = 0f, val left: Float = 0f)

/**
 * Host-implemented native operations. Every operation defaults to UNSUPPORTED,
 * so a host overrides only what it can do and declares it in [capabilities].
 */
interface FlarePlatformAdapter {
    val kind: FlarePlatformKind get() = FlarePlatformKind.Android
    val capabilities: FlarePlatformCapabilities

    suspend fun pickFiles(options: FlarePickFilesOptions = FlarePickFilesOptions()): FlarePlatformResult<List<FlarePickedFile>> =
        FlarePlatformResult.failure(FlarePlatformErrorCode.UNSUPPORTED, "pickFiles is not provided by this host")

    suspend fun pickImages(options: FlarePickImagesOptions = FlarePickImagesOptions()): FlarePlatformResult<List<FlarePickedFile>> =
        FlarePlatformResult.failure(FlarePlatformErrorCode.UNSUPPORTED, "pickImages is not provided by this host")

    suspend fun share(payload: FlareSharePayload): FlarePlatformResult<Unit> =
        FlarePlatformResult.failure(FlarePlatformErrorCode.UNSUPPORTED, "share is not provided by this host")

    /** Returns the unsubscribe, or null when the host has no native back to intercept. */
    fun onNativeBack(handler: () -> Boolean): (() -> Unit)? = null

    fun safeAreaInsets(): FlareSafeAreaInsets = FlareSafeAreaInsets()
}

/** The adapter in effect when the host installs none: nothing native is available. */
class FlareUnsupportedPlatformAdapter(
    override val capabilities: FlarePlatformCapabilities = FlarePlatformCapabilities.android(),
) : FlarePlatformAdapter

private val cancelPattern = Regex("cancel(l)?ed|abort", RegexOption.IGNORE_CASE)
private val permissionPattern = Regex("permission|denied|not allowed", RegexOption.IGNORE_CASE)
private val timeoutPattern = Regex("time(d)? ?out", RegexOption.IGNORE_CASE)
private val unsupportedPattern = Regex("unsupported|not supported|not implemented", RegexOption.IGNORE_CASE)

/**
 * Map a thrown value to the contract's error model: [TimeoutCancellationException]
 * → TIMEOUT, [CancellationException] → CANCELLED, [SecurityException] →
 * PERMISSION_DENIED, [ActivityNotFoundException] / [UnsupportedOperationException]
 * → UNSUPPORTED, anything else FAILED (message heuristics as a last resort).
 */
fun normalizeFlarePlatformError(error: Throwable): FlarePlatformError {
    if (error is FlarePlatformError) return error
    // Android framework exceptions built in JVM unit tests may carry no message; the contract always keeps one.
    val message = error.message ?: error::class.simpleName ?: error.javaClass.name
    val text = "${error::class.simpleName} $message"
    fun result(code: FlarePlatformErrorCode) = FlarePlatformError(code, message, error)
    return when {
        error is TimeoutCancellationException || timeoutPattern.containsMatchIn(text) -> result(FlarePlatformErrorCode.TIMEOUT)
        error is CancellationException || cancelPattern.containsMatchIn(text) -> result(FlarePlatformErrorCode.CANCELLED)
        error is SecurityException || permissionPattern.containsMatchIn(text) -> result(FlarePlatformErrorCode.PERMISSION_DENIED)
        error is ActivityNotFoundException || error is UnsupportedOperationException || error is NotImplementedError ||
            unsupportedPattern.containsMatchIn(text) -> result(FlarePlatformErrorCode.UNSUPPORTED)
        else -> result(FlarePlatformErrorCode.FAILED)
    }
}

/** Resolve to TIMEOUT when the native surface does not answer within [timeoutMs]. */
suspend fun <T> withFlarePlatformTimeout(timeoutMs: Long, operation: suspend () -> FlarePlatformResult<T>): FlarePlatformResult<T> =
    try {
        withTimeout(timeoutMs) { operation() }
    } catch (e: TimeoutCancellationException) {
        FlarePlatformResult.failure(FlarePlatformErrorCode.TIMEOUT, "platform operation exceeded ${timeoutMs}ms", e)
    }

/** Run an adapter operation through the contract: a thrown value is normalized and an optional timeout applies. */
suspend fun <T> callFlarePlatform(timeoutMs: Long? = null, operation: suspend () -> FlarePlatformResult<T>): FlarePlatformResult<T> =
    try {
        if (timeoutMs == null) operation() else withFlarePlatformTimeout(timeoutMs, operation)
    } catch (e: Throwable) {
        FlarePlatformResult.Err(normalizeFlarePlatformError(e))
    }

val LocalFlarePlatform = staticCompositionLocalOf<FlarePlatformAdapter> { FlareUnsupportedPlatformAdapter() }

/** Installs the host's [FlarePlatformAdapter] for a subtree; read it with [flarePlatform]. */
@Composable
fun FlarePlatformProvider(adapter: FlarePlatformAdapter, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalFlarePlatform provides adapter, content = content)
}

/** The host adapter in effect (the unsupported fallback when none is installed). */
@Composable
@ReadOnlyComposable
fun flarePlatform(): FlarePlatformAdapter = LocalFlarePlatform.current

/**
 * System back for a surface that shows a back control: while [enabled], the OS back
 * gesture / button runs [onBack] instead of leaving the host. Registered only when the
 * host declares `nativeBack` and provides an OnBackPressedDispatcher (any
 * ComponentActivity does); the innermost enabled surface wins.
 */
@Composable
internal fun FlareNativeBackEffect(enabled: Boolean, onBack: () -> Unit) {
    if (!flarePlatform().capabilities.nativeBack || LocalOnBackPressedDispatcherOwner.current == null) return
    BackHandler(enabled = enabled, onBack = onBack)
}

/**
 * Reduced motion: the user removed animations (animator duration scale 0). Kit motion that
 * moves content — sheet slides, list scrolls — then jumps straight to its end state.
 */
@Composable
internal fun flareReducedMotion(): Boolean {
    val resolver = LocalContext.current.contentResolver
    return remember(resolver) { Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
}

/**
 * Makes the dialog window this is composed in take the whole display. A full-screen dialog window
 * must not be pushed below the status bar (its bottom would fall off screen): it lays out under the
 * bars and the display cutout, and its content applies the insets it needs. Reads the API level, so it
 * lives with the platform module.
 */
@Composable
internal fun FlareEdgeToEdgeDialogWindow() {
    val window = (LocalView.current.parent as? DialogWindowProvider)?.window
    DisposableEffect(window) {
        if (window != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                } else {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) fitInsetsTypes = 0
            }
        }
        onDispose {}
    }
}

