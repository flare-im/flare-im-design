package com.flare.im.ui

import android.annotation.SuppressLint
import android.content.ComponentCallbacks2
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color as AndroidColor
import android.net.Uri
import android.net.http.SslError
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.MotionEvent
import android.view.ViewGroup
import android.webkit.ConsoleMessage
import android.webkit.CookieManager
import android.webkit.GeolocationPermissions
import android.webkit.HttpAuthHandler
import android.webkit.JsPromptResult
import android.webkit.JsResult
import android.webkit.PermissionRequest
import android.webkit.RenderProcessGoneDetail
import android.webkit.SslErrorHandler
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.webkit.JavaScriptReplyProxy
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import java.io.File
import java.io.FileInputStream
import java.lang.ref.WeakReference
import java.net.URI
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.launch

/*
 * The Android host of plugin web bundles (design 8.4, L3): a WebView on the plugin's own virtual host
 * `https://{pluginKey}.plugin.flare.invalid/`, whose every request is answered from the engine's verified cache
 * (`shouldInterceptRequest`; anything else is 403), with the bridge on `WebViewCompat.addWebMessageListener` for that
 * origin alone. The engine checks every bridge message (`plugin_bundle_bridge`); this host only moves them and draws
 * what the engine hands it (`ui.*`, `clipboard.write`).
 *
 * Two layers, so a Flutter platform view reuses the native host without Compose:
 *
 * - [FlarePluginBundleView]: a plain Android view. It opens the session, serves the files, carries the bridge, follows
 *   the host's lifecycle (paused: `visibility.changed`; 30 s in the background or a memory warning: the page is
 *   destroyed and opened again on return, `ui.saveState` brings it back), and survives a renderer crash (an error
 *   state with reload; the third crash falls back to the declarative variant). Hosts give it a
 *   [FlarePluginBundleChannel] (their SDK's `plugin_bundle_*` routes) and a [FlarePluginBundleHostDelegate] (what to
 *   draw).
 * - [FlarePluginBundleHost]: the Compose host. It draws the page frame, the opening and crash states, and the host
 *   requests with kit components (toast, confirm, the external link confirmation).
 *
 * [FlarePluginBundleRuntime.profile] is the `bundleRuntime` of the host profile: only on Android System WebView 111+
 * with the web message listener (D-17); below that the host reports no runtime and Core never selects a bundle.
 */

/** The bundle runtime this kit hosts, as the host profile reports it (`bundleRuntime`). */
object FlarePluginBundleRuntime {
    /** Bridge protocol version this host speaks. */
    const val BRIDGE_VERSION = 1

    /** Android System WebView floor (D-17). */
    const val MIN_WEBVIEW_MAJOR = 111

    /** Descriptor engine name. */
    const val ENGINE = "webview"

    /** The bridge object the plugin web SDK looks for (`window.flareBridge`). */
    const val BRIDGE_OBJECT = "flareBridge"

    /** The installed WebView's major version, or null when there is none (or it cannot be read). */
    fun webViewMajor(context: Context): Int? =
        runCatching { WebViewCompat.getCurrentWebViewPackage(context)?.versionName }.getOrNull()?.let(::webViewMajorOf)

    /** Whether the WebView offers what the bridge needs: the origin-bound web message listener. */
    fun messageListenerSupported(): Boolean =
        runCatching { WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER) }.getOrDefault(false)

    /** `{bridge, engine, engineMajor}` for this device, or null below the floor (the profile then carries none). */
    fun profile(context: Context): Map<String, Any?>? = profileFor(webViewMajor(context), messageListenerSupported())

    /** [profile] as JSON text, for hosts that build the profile as JSON. */
    fun profileJson(context: Context): String? = profile(context)?.let(::pluginJson)

    /** The profile of a WebView of [major] with or without the listener: the floor and the feature both hold. */
    fun profileFor(major: Int?, messageListener: Boolean): Map<String, Any?>? =
        if (major != null && major >= MIN_WEBVIEW_MAJOR && messageListener) {
            mapOf("bridge" to BRIDGE_VERSION, "engine" to ENGINE, "engineMajor" to major)
        } else {
            null
        }
}

/** `128.0.6613.40` → 128; null for a name that does not start with a positive number. */
internal fun webViewMajorOf(versionName: String): Int? =
    versionName.trim().substringBefore('.').toIntOrNull()?.takeIf { it > 0 }

/** Where a bundle is shown (the bridge's `presentation`, design 8.9). */
enum class FlarePluginBundlePresentation(val wire: String) {
    /** A page of its own. */
    Page("page"),

    /** A card's detail, in a sheet. */
    Detail("detail"),

    /** A composer "+" form: `ui.close` carries the operation result. */
    ComposerForm("composerForm"),
}

/** What a host asks the engine to open (`plugin_bundle_open`), less the theme the view adds. */
@Immutable
data class FlarePluginBundleOpenRequest(
    val pluginId: String,
    /** The contribution whose selected variant is the bundle: a page id, a card's or a composer entry's contribution. */
    val contributionId: String,
    /** A route inside the bundle; null opens the contribution's own route. */
    val route: String? = null,
    /** The page's arguments as JSON object text (an action's payload); null is `{}`. */
    val argumentsJson: String? = null,
    val presentation: FlarePluginBundlePresentation = FlarePluginBundlePresentation.Page,
    val conversationId: String? = null,
    /** The conversation's type as this host names it (`single`, `group`). */
    val conversationType: String? = null,
    val locale: String = "",
) {
    /** The `plugin_bundle_open` input with the theme of [dark] (the web SDK owns the token defaults). */
    fun toJson(dark: Boolean): String {
        val request = linkedMapOf<String, Any?>(
            "pluginId" to pluginId,
            "contributionId" to contributionId,
            "presentation" to presentation.wire,
            "locale" to locale,
            "theme" to pluginBundleTheme(dark),
        )
        route?.takeIf { it.isNotBlank() }?.let { request["route"] = it }
        val arguments = argumentsJson?.let { runCatching { FlareJson.parse(it) }.getOrNull() as? Map<*, *> }
        if (arguments != null) request["arguments"] = arguments
        val conversation = conversationId?.takeIf { it.isNotBlank() }
        if (conversation != null) request["conversation"] = mapOf("id" to conversation, "type" to (conversationType ?: "single"))
        return pluginJson(request)
    }
}

/** The bridge theme: the mode, no token overrides (the web SDK carries the kit's defaults for both modes). */
internal fun pluginBundleTheme(dark: Boolean): Map<String, Any?> =
    mapOf("mode" to if (dark) "dark" else "light", "tokens" to emptyMap<String, String>())

/** One file the interceptor may serve. */
@Immutable
data class FlarePluginBundleFile(val path: String, val contentType: String, val size: Long)

/** An open session as `plugin_bundle_open` answered it. */
@Immutable
data class FlarePluginBundleSession(
    val sessionId: String,
    /** `https://{pluginKey}.plugin.flare.invalid`. */
    val origin: String,
    /** The cache directory of the verified files. */
    val root: String,
    /** The entry document's path (`index.html`). */
    val entry: String,
    /** The design 8.5 policy, written on every response. */
    val csp: String,
    /** The interceptor's allowlist, by path. */
    val files: Map<String, FlarePluginBundleFile>,
) {
    /** The virtual host, lowercase. */
    val host: String get() = runCatching { URI(origin).host }.getOrNull().orEmpty().lowercase()

    /** The address the page loads first. */
    val entryUrl: String get() = "${origin.trimEnd('/')}/$entry"

    companion object {
        /**
         * Reads an answer; null when it is not one this host can serve safely: no session, an origin that is not an
         * `https` host under `.plugin.flare.invalid`, no policy, or an entry outside the files.
         */
        fun fromJson(json: String): FlarePluginBundleSession? {
            val map = runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *> ?: return null
            val sessionId = (map["sessionId"] as? String)?.takeIf { it.isNotBlank() } ?: return null
            val origin = (map["origin"] as? String)?.takeIf(::validBundleOrigin) ?: return null
            val root = (map["root"] as? String)?.takeIf { it.isNotBlank() } ?: return null
            val entry = (map["entry"] as? String)?.takeIf(::validBundlePath) ?: return null
            val csp = (map["csp"] as? String)?.takeIf { it.isNotBlank() && it.none { c -> c == '\n' || c == '\r' } } ?: return null
            val files = (map["files"] as? List<*>).orEmpty().mapNotNull { row ->
                val file = row as? Map<*, *> ?: return@mapNotNull null
                val path = (file["path"] as? String)?.takeIf(::validBundlePath) ?: return@mapNotNull null
                val type = (file["contentType"] as? String)?.takeIf { it.isNotBlank() } ?: return@mapNotNull null
                FlarePluginBundleFile(path, type, (file["size"] as? Number)?.toLong() ?: 0L)
            }.associateBy { it.path }
            if (entry !in files) return null
            return FlarePluginBundleSession(sessionId, origin.trimEnd('/'), root, entry, csp, files)
        }
    }
}

/** The bundle origin shape (D-03): `https://{key}.plugin.flare.invalid`, nothing after the host. */
internal fun validBundleOrigin(origin: String): Boolean {
    val uri = runCatching { URI(origin.trimEnd('/')) }.getOrNull() ?: return false
    val host = uri.host?.lowercase() ?: return false
    return uri.scheme == "https" && uri.port == -1 && uri.rawPath.isNullOrEmpty() && uri.rawQuery == null &&
        uri.rawUserInfo == null && host.endsWith(".plugin.flare.invalid") &&
        host.removeSuffix(".plugin.flare.invalid").let { key -> key.isNotEmpty() && key.all { it in 'a'..'z' || it in '2'..'7' } }
}

/** A bundle path (design 8.2): lowercase `[a-z0-9._/-]`, at most 256 bytes, no empty, dot or hidden segment. */
internal fun validBundlePath(path: String): Boolean =
    path.isNotEmpty() && path.length <= 256 &&
        path.all { it in 'a'..'z' || it in '0'..'9' || it == '.' || it == '_' || it == '/' || it == '-' } &&
        path.split('/').all { segment -> segment.isNotEmpty() && !segment.startsWith('.') }

/** What the interceptor answers one request with. */
internal sealed interface PluginBundleServe {
    /** The verified file at [path]. */
    data class File(val file: FlarePluginBundleFile) : PluginBundleServe

    /** 403: not this bundle's origin, not a GET, or not in the files. */
    data object Forbidden : PluginBundleServe
}

/**
 * The interceptor's rule: only `GET https://{the session's host}/{a listed path}` is served; the root is the entry. The
 * query and fragment are ignored; any other scheme, host, port, method, a path outside the list or one that is not a
 * plain bundle path is forbidden.
 */
internal fun pluginBundleServe(url: String, method: String, session: FlarePluginBundleSession): PluginBundleServe {
    if (!method.equals("GET", ignoreCase = true)) return PluginBundleServe.Forbidden
    val uri = runCatching { URI(url) }.getOrNull() ?: return PluginBundleServe.Forbidden
    if (uri.scheme != "https" || uri.rawUserInfo != null || (uri.port != -1 && uri.port != 443)) return PluginBundleServe.Forbidden
    if (uri.host?.lowercase() != session.host || session.host.isEmpty()) return PluginBundleServe.Forbidden
    val raw = uri.rawPath.orEmpty()
    // No escapes: bundle paths are plain lowercase ASCII, so an encoded byte is never one of them.
    if (raw.contains('%') || raw.contains('\\')) return PluginBundleServe.Forbidden
    val path = raw.removePrefix("/").ifEmpty { session.entry }
    if (!validBundlePath(path)) return PluginBundleServe.Forbidden
    val file = session.files[path] ?: return PluginBundleServe.Forbidden
    return PluginBundleServe.File(file)
}

/** The response headers of every bundle answer, a 403 included. */
internal fun pluginBundleHeaders(csp: String): Map<String, String> = linkedMapOf(
    "Content-Security-Policy" to csp,
    // Vite's module scripts load in CORS mode.
    "Access-Control-Allow-Origin" to "*",
    "X-Content-Type-Options" to "nosniff",
    "Referrer-Policy" to "no-referrer",
    "Cache-Control" to "no-cache",
    "Permissions-Policy" to "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
)

/** `text/html; charset=utf-8` → (`text/html`, `utf-8`); text types without a charset are read as UTF-8. */
internal fun pluginBundleMime(contentType: String): Pair<String, String?> {
    val parts = contentType.split(';').map { it.trim() }
    val mime = parts.first().lowercase()
    val charset = parts.drop(1).firstOrNull { it.lowercase().startsWith("charset=") }?.substringAfter('=')?.trim('"')
    val textual = mime.startsWith("text/") || mime == "application/javascript" || mime == "application/json" || mime == "image/svg+xml"
    return mime to (charset ?: if (textual) "utf-8" else null)
}

/** A top-level navigation the page may make: only within its own origin (a reload, the same bundle). */
internal fun pluginBundleNavigationAllowed(url: String, session: FlarePluginBundleSession?): Boolean {
    session ?: return false
    val uri = runCatching { URI(url) }.getOrNull() ?: return false
    return uri.scheme == "https" && uri.host?.lowercase() == session.host && (uri.port == -1 || uri.port == 443)
}

/** An external link the bridge may open (D-13): an absolute `https` address with a host and no credentials. */
fun flarePluginBundleExternalUrl(url: String): Boolean {
    if (url.length > 2048) return false
    val uri = runCatching { URI(url) }.getOrNull() ?: return false
    return uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.rawUserInfo == null
}

/** One answer of the engine's half of the bridge. */
sealed interface FlarePluginBundleResult {
    /** The route answered: its JSON object text. */
    data class Answer(val json: String) : FlarePluginBundleResult

    /** The route refused: the `sdk.plugin_bundle.*` reason (`not_offered`, `unsupported`, `unavailable`, `rejected`, ...). */
    data class Failure(val reason: String) : FlarePluginBundleResult
}

/**
 * The engine's `plugin_bundle_*` routes as the host's SDK reaches them. JSON text in and out, so a Compose app and a
 * Flutter plugin (whose engine lives on the Dart side) implement the same port. Each call answers exactly once, on any
 * thread; the view moves back to the main thread itself.
 */
interface FlarePluginBundleChannel {
    /** `plugin_bundle_open` with [requestJson]: `{sessionId, origin, root, entry, csp, files, hello}`. */
    fun open(requestJson: String, answer: (FlarePluginBundleResult) -> Unit)

    /** `plugin_bundle_bridge` `{sessionId, envelope, userGesture}`: `{envelope}` or `{host: {id, method, params}}`. */
    fun bridge(sessionId: String, envelope: String, userGesture: Boolean, answer: (FlarePluginBundleResult) -> Unit)

    /** `plugin_bundle_host_result` `{sessionId, id, result? | error?}`: `{envelope}`. [resultJson] is an object's text. */
    fun hostResult(sessionId: String, id: String, resultJson: String?, error: String?, answer: (FlarePluginBundleResult) -> Unit)

    /** `plugin_bundle_host_event` `{event, payload, sessionId}`: `{deliveries: [{sessionId, envelope}]}`. */
    fun hostEvent(sessionId: String, event: String, payloadJson: String, answer: (FlarePluginBundleResult) -> Unit)

    /** `plugin_bundle_close` `{sessionId}`; the answer does not matter. */
    fun close(sessionId: String)
}

/** A request the engine handed the host to draw (`ui.navigate`, `ui.close`, `ui.setTitle`, `ui.toast`, ...). */
@Immutable
data class FlarePluginBundleHostRequest(val id: String, val method: String, val params: Map<String, Any?>) {
    /** `params` as JSON text. */
    val paramsJson: String get() = pluginJson(params)
}

/** How the host answered a [FlarePluginBundleHostRequest]. */
sealed interface FlarePluginBundleHostAnswer {
    /** Done; [resultJson] is the result object (`{confirmed}` for `ui.confirm`, `{}` otherwise). */
    data class Done(val resultJson: String = "{}") : FlarePluginBundleHostAnswer

    /** Not done: `cancelled`, `unavailable`, `gesture_required`, `timeout` or `not_found`. */
    data class Failed(val code: String) : FlarePluginBundleHostAnswer
}

/** Where a bundle page stands, for the host to draw over it. */
sealed interface FlarePluginBundleState {
    /** Opening the session, downloading the bundle the first time, or loading the entry. */
    data object Opening : FlarePluginBundleState

    /** The entry loaded. */
    data object Ready : FlarePluginBundleState

    /** Destroyed in the background (30 s, a memory warning) or evicted; opened again on return or [FlarePluginBundleView.reload]. */
    data object Suspended : FlarePluginBundleState

    /** The renderer went away [count] times this session; the host offers reload. */
    data class Crashed(val count: Int) : FlarePluginBundleState

    /**
     * Show the declarative variant instead: the bundle is not offered or could not be opened (`not_offered`,
     * `unsupported`, `unavailable`, `rejected`, ...), crashed three times (`crashed`), or the engine closed it
     * (`withdrawn`, `suspended`, `disabled`, `replaced`).
     */
    data class Fallback(val reason: String) : FlarePluginBundleState

    /** Signed out: nothing to show. */
    data object Closed : FlarePluginBundleState
}

/** What a [FlarePluginBundleView] asks of its host. */
interface FlarePluginBundleHostDelegate {
    /** Draw [request] and answer it exactly once, on any thread. */
    fun onHostRequest(request: FlarePluginBundleHostRequest, respond: (FlarePluginBundleHostAnswer) -> Unit)

    /** The page moved to [state] (main thread). */
    fun onStateChanged(state: FlarePluginBundleState) {}
}

/** What the engine's close reason means to the host: the declarative variant, a later reopen, or nothing at all. */
internal fun pluginBundleClosedState(reason: String): FlarePluginBundleState = when (reason) {
    "signedOut" -> FlarePluginBundleState.Closed
    "evicted" -> FlarePluginBundleState.Suspended
    else -> FlarePluginBundleState.Fallback(reason)
}

/** Crashes in one opening before the declarative variant takes over (design 8.8). */
internal const val PLUGIN_BUNDLE_CRASH_LIMIT = 3

/** Background time before the page is destroyed (design 8.8). */
internal const val PLUGIN_BUNDLE_BACKGROUND_MS = 30_000L

/** How long a touch counts as the user's gesture for `clipboard.write` and capabilities. */
internal const val PLUGIN_BUNDLE_GESTURE_MS = 5_000L

/** The state after a renderer crash, the [count]th of this opening. */
internal fun pluginBundleCrashState(count: Int): FlarePluginBundleState =
    if (count >= PLUGIN_BUNDLE_CRASH_LIMIT) FlarePluginBundleState.Fallback("crashed") else FlarePluginBundleState.Crashed(count)

/** A `plugin_bundle_bridge` answer: an envelope to post back, or a request to draw. */
internal sealed interface PluginBundleBridgeAnswer {
    data class Envelope(val text: String) : PluginBundleBridgeAnswer
    data class Host(val request: FlarePluginBundleHostRequest) : PluginBundleBridgeAnswer
}

internal fun pluginBundleBridgeAnswer(json: String): PluginBundleBridgeAnswer? {
    val map = runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *> ?: return null
    (map["envelope"] as? String)?.let { return PluginBundleBridgeAnswer.Envelope(it) }
    val host = map["host"] as? Map<*, *> ?: return null
    val id = (host["id"] as? String)?.takeIf { it.isNotEmpty() } ?: return null
    val method = (host["method"] as? String)?.takeIf { it.isNotEmpty() } ?: return null
    @Suppress("UNCHECKED_CAST")
    val params = (host["params"] as? Map<String, Any?>) ?: emptyMap()
    return PluginBundleBridgeAnswer.Host(FlarePluginBundleHostRequest(id, method, params))
}

/** `{deliveries: [{sessionId, envelope}]}` of `plugin_bundle_host_event`: the envelopes for [sessionId]. */
internal fun pluginBundleDeliveries(json: String, sessionId: String): List<String> {
    val map = runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *> ?: return emptyList()
    return (map["deliveries"] as? List<*>).orEmpty().mapNotNull { row ->
        val delivery = row as? Map<*, *> ?: return@mapNotNull null
        (delivery["envelope"] as? String)?.takeIf { delivery["sessionId"] == sessionId }
    }
}

/** A `plugin.bundle_event` payload: `{sessionId, envelope?, close?}`. */
internal data class PluginBundleEvent(val sessionId: String, val envelope: String?, val close: String?)

internal fun pluginBundleEvent(json: String): PluginBundleEvent? {
    val map = runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *> ?: return null
    val sessionId = (map["sessionId"] as? String)?.takeIf { it.isNotBlank() } ?: return null
    return PluginBundleEvent(sessionId, map["envelope"] as? String, (map["close"] as? String)?.takeIf { it.isNotBlank() })
}

/**
 * The engine's own messages for open pages (`plugin.bundle_event`, event 7004): the host's event subscription passes
 * each payload here, and the view of that session posts the envelope or closes. Views register themselves while a
 * session is open.
 */
object FlarePluginBundleEvents {
    private val views = ConcurrentHashMap<String, WeakReference<FlarePluginBundleView>>()
    private val main = Handler(Looper.getMainLooper())

    internal fun register(sessionId: String, view: FlarePluginBundleView) {
        views[sessionId] = WeakReference(view)
    }

    internal fun unregister(sessionId: String) {
        views.remove(sessionId)
    }

    /** Hands one `plugin.bundle_event` payload ([eventJson]) to its page; false when no open page has that session. */
    fun dispatch(eventJson: String): Boolean {
        val event = pluginBundleEvent(eventJson) ?: return false
        val view = views[event.sessionId]?.get() ?: run { views.remove(event.sessionId); return false }
        main.post {
            event.envelope?.let { view.deliver(event.sessionId, it) }
            event.close?.let { view.engineClosed(event.sessionId, it) }
        }
        return true
    }
}

/**
 * The bundle page as a plain Android view: one [WebView] per session, sandboxed as design 8.5 says. Not a Compose
 * component, so a Flutter platform view hosts it as it is. Call [start] once, [onHostPause]/[onHostResume] with the
 * screen's lifecycle, [setDark]/[setLocale] when they change, and [dispose] when the page goes away. Main thread only.
 */
@SuppressLint("ViewConstructor")
class FlarePluginBundleView(context: Context) : FrameLayout(context) {
    private val main = Handler(Looper.getMainLooper())
    private var request: FlarePluginBundleOpenRequest? = null
    private var channel: FlarePluginBundleChannel? = null
    private var delegate: FlarePluginBundleHostDelegate? = null
    private var dark = false

    /** The open session, read by the interceptor off the main thread. */
    @Volatile
    private var session: FlarePluginBundleSession? = null

    /** The canonical cache root of [session], for the interceptor's containment check. */
    @Volatile
    private var rootDir: File? = null

    private var webView: WebView? = null

    /** What [webView]'s storage is held under, released when it is destroyed. */
    private var storageLease: PluginBundleStorageLease? = null

    /** The reply channel of the page's current document; envelopes wait while the page has not spoken yet. */
    private val reply = PluginBundleReply<JavaScriptReplyProxy> { proxy, envelope -> proxy.postMessage(envelope) }

    /** Each open, reopen and dispose starts a new generation; answers for an older one are dropped. */
    private var generation = 0
    private var crashes = 0
    private var paused = false
    private var disposed = false

    @Volatile
    private var lastGestureAt = 0L

    var state: FlarePluginBundleState = FlarePluginBundleState.Opening
        private set

    /** The open session's id, or null between sessions. */
    val sessionId: String? get() = session?.sessionId

    private val suspendInBackground = Runnable { if (paused) suspendPage() }

    private val memory = object : ComponentCallbacks2 {
        override fun onTrimMemory(level: Int) {
            // A memory warning while hidden: give the memory back now rather than in 30 s.
            if (paused && level >= ComponentCallbacks2.TRIM_MEMORY_BACKGROUND) main.post { if (paused) suspendPage() }
        }

        override fun onConfigurationChanged(newConfig: Configuration) {}

        @Deprecated("Deprecated in Java")
        override fun onLowMemory() {
            main.post { if (paused) suspendPage() }
        }
    }

    /** Opens [request] through [channel]; [delegate] draws what the page asks for. */
    fun start(
        request: FlarePluginBundleOpenRequest,
        channel: FlarePluginBundleChannel,
        delegate: FlarePluginBundleHostDelegate,
        dark: Boolean,
    ) {
        check(this.request == null) { "a bundle view is started once" }
        this.request = request
        this.channel = channel
        this.delegate = delegate
        this.dark = dark
        context.applicationContext.registerComponentCallbacks(memory)
        open()
    }

    /** Opens the page again: after a crash, or once it was suspended. */
    fun reload() {
        if (disposed) return
        if (state is FlarePluginBundleState.Fallback || state == FlarePluginBundleState.Closed) return
        teardown(closeSession = true)
        open()
    }

    /** The screen went to the background: timers and animations pause, the page hears it, and 30 s later it goes. */
    fun onHostPause() {
        if (disposed || paused) return
        paused = true
        webView?.onPause()
        sendHostEvent("visibility.changed", mapOf("visible" to false))
        main.postDelayed(suspendInBackground, PLUGIN_BUNDLE_BACKGROUND_MS)
    }

    /** The screen came back: a suspended page opens again (with what it saved), a live one resumes. */
    fun onHostResume() {
        if (disposed || !paused) return
        paused = false
        main.removeCallbacks(suspendInBackground)
        if (state == FlarePluginBundleState.Suspended) {
            open()
            return
        }
        webView?.onResume()
        sendHostEvent("visibility.changed", mapOf("visible" to true))
    }

    /** The host's theme changed. */
    fun setDark(dark: Boolean) {
        if (this.dark == dark) return
        this.dark = dark
        sendHostEvent("theme.changed", pluginBundleTheme(dark))
    }

    /** The host's language changed. */
    fun setLocale(locale: String) {
        val current = request ?: return
        if (current.locale == locale) return
        request = current.copy(locale = locale)
        sendHostEvent("locale.changed", mapOf("locale" to locale))
    }

    /** Ends the session and frees the WebView; the view is not used again. */
    fun dispose() {
        if (disposed) return
        disposed = true
        main.removeCallbacks(suspendInBackground)
        runCatching { context.applicationContext.unregisterComponentCallbacks(memory) }
        teardown(closeSession = true)
        generation++
        channel = null
        delegate = null
    }

    /** An engine envelope for [forSession] (`catalog.changed`, `entity.state`, `lifecycle.revoked`). */
    internal fun deliver(forSession: String, envelope: String) {
        if (disposed || session?.sessionId != forSession) return
        post(envelope)
    }

    /** The engine closed [forSession] ([reason]: withdrawn, suspended, disabled, replaced, evicted, signedOut). */
    internal fun engineClosed(forSession: String, reason: String) {
        if (disposed || session?.sessionId != forSession) return
        // The engine already ended the session: nothing to close there.
        teardown(closeSession = false)
        moveTo(pluginBundleClosedState(reason))
    }

    private fun moveTo(next: FlarePluginBundleState) {
        state = next
        delegate?.onStateChanged(next)
    }

    private fun open() {
        val request = request ?: return
        val channel = channel ?: return
        val mine = ++generation
        moveTo(FlarePluginBundleState.Opening)
        if (!FlarePluginBundleRuntime.messageListenerSupported()) {
            moveTo(FlarePluginBundleState.Fallback("unsupported"))
            return
        }
        channel.open(request.toJson(dark)) { result ->
            main.post {
                if (mine != generation || disposed) {
                    // Opened for a page that is gone: end the session it made.
                    (result as? FlarePluginBundleResult.Answer)?.let { answer ->
                        FlarePluginBundleSession.fromJson(answer.json)?.let { channel.close(it.sessionId) }
                    }
                    return@post
                }
                when (result) {
                    is FlarePluginBundleResult.Failure -> moveTo(FlarePluginBundleState.Fallback(result.reason))
                    is FlarePluginBundleResult.Answer -> {
                        val opened = FlarePluginBundleSession.fromJson(result.json)
                        if (opened == null) {
                            pluginBundleSessionIdOf(result.json)?.let(channel::close)
                            moveTo(FlarePluginBundleState.Fallback("rejected"))
                        } else {
                            load(opened)
                        }
                    }
                }
            }
        }
    }

    private fun load(opened: FlarePluginBundleSession) {
        val root = runCatching { File(opened.root).canonicalFile }.getOrNull()
        if (root == null || !root.isDirectory) {
            channel?.close(opened.sessionId)
            moveTo(FlarePluginBundleState.Fallback("unavailable"))
            return
        }
        session = opened
        rootDir = root
        FlarePluginBundleEvents.register(opened.sessionId, this)
        val view = createWebView(opened)
        if (view == null) {
            teardown(closeSession = true)
            moveTo(FlarePluginBundleState.Fallback("unsupported"))
            return
        }
        webView = view
        addView(view, LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        if (paused) view.onPause()
        view.loadUrl(opened.entryUrl)
    }

    @SuppressLint("SetJavaScriptEnabled", "ClickableViewAccessibility", "RequiresFeature")
    private fun createWebView(opened: FlarePluginBundleSession): WebView? {
        val view = runCatching { WebView(context) }.getOrNull() ?: return null
        // First, before anything else touches the view: the signed-in user's profile and the storage hold (design 8.5).
        val lease = runCatching { FlarePluginBundleStorage.attach(view, opened.origin, opened.files.keys) }.getOrNull()
        if (lease == null) {
            runCatching { view.destroy() }
            return null
        }
        storageLease = lease
        view.setBackgroundColor(AndroidColor.TRANSPARENT)
        view.settings.apply {
            javaScriptEnabled = true
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(false)
            allowFileAccess = false
            allowContentAccess = false
            @Suppress("DEPRECATION")
            allowFileAccessFromFileURLs = false
            @Suppress("DEPRECATION")
            allowUniversalAccessFromFileURLs = false
            // No web storage or databases: the bridge's `storage` is the plugin's store (design 8.5).
            domStorageEnabled = false
            @Suppress("DEPRECATION")
            databaseEnabled = false
            setGeolocationEnabled(false)
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            mediaPlaybackRequiresUserGesture = true
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            cacheMode = WebSettings.LOAD_NO_CACHE
            @Suppress("DEPRECATION")
            saveFormData = false
        }
        CookieManager.getInstance().setAcceptThirdPartyCookies(view, false)
        view.setDownloadListener { _, _, _, _, _ -> } // Downloads go nowhere.
        // The host's own record of a touch: the engine trusts this, never the page's claim.
        view.setOnTouchListener { _, event ->
            if (event.actionMasked == MotionEvent.ACTION_DOWN || event.actionMasked == MotionEvent.ACTION_UP) {
                lastGestureAt = SystemClock.uptimeMillis()
            }
            false
        }
        view.webViewClient = BundleClient()
        view.webChromeClient = BundleChrome()
        val mine = generation
        try {
            WebViewCompat.addWebMessageListener(
                view,
                FlarePluginBundleRuntime.BRIDGE_OBJECT,
                setOf(opened.origin),
            ) { _: WebView, message: WebMessageCompat, sourceOrigin: Uri, isMainFrame: Boolean, replyProxy: JavaScriptReplyProxy ->
                onPageMessage(mine, message, sourceOrigin, isMainFrame, replyProxy)
            }
        } catch (_: Throwable) {
            view.destroy()
            releaseStorage()
            return null
        }
        return view
    }

    private fun onPageMessage(mine: Int, message: WebMessageCompat, source: Uri, mainFrame: Boolean, proxy: JavaScriptReplyProxy) {
        val current = session ?: return
        if (mine != generation || disposed || !mainFrame) return
        // The listener is bound to the origin already; check it once more, exactly.
        if ("${source.scheme}://${source.host}".lowercase() != current.origin.lowercase() || source.port != -1) return
        val text = message.data ?: return
        // Always the proxy of the document that spoke last: a reload makes a new one.
        reply.speaking(proxy)
        val gesture = SystemClock.uptimeMillis() - lastGestureAt <= PLUGIN_BUNDLE_GESTURE_MS
        val channel = channel ?: return
        channel.bridge(current.sessionId, text, gesture) { result ->
            main.post {
                if (mine != generation || disposed) return@post
                val answer = (result as? FlarePluginBundleResult.Answer)?.let { pluginBundleBridgeAnswer(it.json) } ?: return@post
                when (answer) {
                    is PluginBundleBridgeAnswer.Envelope -> post(answer.text)
                    is PluginBundleBridgeAnswer.Host -> hostRequest(mine, current.sessionId, answer.request)
                }
            }
        }
    }

    private fun hostRequest(mine: Int, sessionId: String, request: FlarePluginBundleHostRequest) {
        val delegate = delegate
        if (delegate == null) {
            answerHost(mine, sessionId, request.id, FlarePluginBundleHostAnswer.Failed("unavailable"))
            return
        }
        var answered = false
        delegate.onHostRequest(request) { answer ->
            main.post {
                if (answered) return@post
                answered = true
                answerHost(mine, sessionId, request.id, answer)
            }
        }
    }

    private fun answerHost(mine: Int, sessionId: String, id: String, answer: FlarePluginBundleHostAnswer) {
        if (mine != generation || disposed) return
        val channel = channel ?: return
        val (result, error) = when (answer) {
            is FlarePluginBundleHostAnswer.Done -> answer.resultJson to null
            is FlarePluginBundleHostAnswer.Failed -> null to answer.code
        }
        channel.hostResult(sessionId, id, result, error) { reply ->
            main.post {
                if (mine != generation || disposed) return@post
                val envelope = (reply as? FlarePluginBundleResult.Answer)?.let { pluginBundleBridgeAnswer(it.json) }
                (envelope as? PluginBundleBridgeAnswer.Envelope)?.let { post(it.text) }
            }
        }
    }

    /** Posts [envelope] to the page (the web SDK reads `message` events on `flareBridge`). */
    private fun post(envelope: String) {
        reply.post(envelope)
    }

    private fun releaseStorage() {
        val lease = storageLease ?: return
        storageLease = null
        runCatching { FlarePluginBundleStorage.release(context, lease) }
    }

    private fun sendHostEvent(event: String, payload: Map<String, Any?>) {
        val current = session ?: return
        val channel = channel ?: return
        val mine = generation
        channel.hostEvent(current.sessionId, event, pluginJson(payload)) { result ->
            main.post {
                if (mine != generation || disposed) return@post
                val json = (result as? FlarePluginBundleResult.Answer)?.json ?: return@post
                pluginBundleDeliveries(json, current.sessionId).forEach(::post)
            }
        }
    }

    /** Background or memory: the page goes now and opens again on return. */
    private fun suspendPage() {
        if (disposed || session == null) return
        teardown(closeSession = true)
        moveTo(FlarePluginBundleState.Suspended)
    }

    /** Frees the WebView; [closeSession] also ends the engine session (the engine keeps what the page saved). */
    @SuppressLint("RequiresFeature")
    private fun teardown(closeSession: Boolean) {
        generation++
        val ended = session
        session = null
        rootDir = null
        reply.reset()
        webView?.let { view ->
            removeView(view)
            runCatching {
                view.stopLoading()
                if (WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)) {
                    WebViewCompat.removeWebMessageListener(view, FlarePluginBundleRuntime.BRIDGE_OBJECT)
                }
                view.destroy()
            }
        }
        webView = null
        releaseStorage()
        if (ended != null) {
            FlarePluginBundleEvents.unregister(ended.sessionId)
            if (closeSession) channel?.close(ended.sessionId)
        }
    }

    private fun forbidden(csp: String?): WebResourceResponse =
        WebResourceResponse("text/plain", "utf-8", 403, "Forbidden", csp?.let(::pluginBundleHeaders) ?: emptyMap(), null)

    /** Serves the verified files and nothing else; blocks every navigation away from the bundle. */
    private inner class BundleClient : WebViewClient() {
        override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse {
            val current = session ?: return forbidden(null)
            val root = rootDir ?: return forbidden(current.csp)
            val served = pluginBundleServe(request.url.toString(), request.method ?: "GET", current)
            val file = (served as? PluginBundleServe.File)?.file ?: return forbidden(current.csp)
            val target = runCatching { File(root, file.path).canonicalFile }.getOrNull() ?: return forbidden(current.csp)
            // The engine checked every path before writing it; check containment again before reading.
            if (!target.path.startsWith(root.path + File.separator) || !target.isFile) return forbidden(current.csp)
            val stream = runCatching { FileInputStream(target) }.getOrNull() ?: return forbidden(current.csp)
            val (mime, charset) = pluginBundleMime(file.contentType)
            return WebResourceResponse(mime, charset, 200, "OK", pluginBundleHeaders(current.csp), stream)
        }

        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean =
            !(request.isForMainFrame && pluginBundleNavigationAllowed(request.url.toString(), session))

        override fun onPageStarted(view: WebView, url: String?, favicon: android.graphics.Bitmap?) {
            // A new document (a reload, a same-origin navigation): the old reply proxy answers nobody now, so
            // envelopes wait until the new document speaks.
            if (view === webView) reply.documentStarted()
        }

        override fun onPageFinished(view: WebView, url: String?) {
            if (view === webView && state == FlarePluginBundleState.Opening) moveTo(FlarePluginBundleState.Ready)
        }

        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail?): Boolean {
            if (view !== webView) {
                runCatching { (view.parent as? ViewGroup)?.removeView(view); view.destroy() }
                return true
            }
            teardown(closeSession = true)
            crashes++
            moveTo(pluginBundleCrashState(crashes))
            return true
        }

        override fun onReceivedSslError(view: WebView, handler: SslErrorHandler, error: SslError?) {
            handler.cancel()
        }

        override fun onReceivedHttpAuthRequest(view: WebView, handler: HttpAuthHandler, host: String?, realm: String?) {
            handler.cancel()
        }
    }

    /** No windows, permissions, file choosers, geolocation or JS dialogs; console output stays in the page. */
    private class BundleChrome : WebChromeClient() {
        override fun onCreateWindow(view: WebView?, isDialog: Boolean, isUserGesture: Boolean, resultMsg: android.os.Message?) = false

        override fun onPermissionRequest(request: PermissionRequest) = request.deny()

        override fun onGeolocationPermissionsShowPrompt(origin: String?, callback: GeolocationPermissions.Callback) =
            callback.invoke(origin, false, false)

        override fun onShowFileChooser(
            webView: WebView?,
            filePathCallback: ValueCallback<Array<Uri>>?,
            fileChooserParams: FileChooserParams?,
        ): Boolean {
            filePathCallback?.onReceiveValue(null)
            return true
        }

        override fun onJsAlert(view: WebView?, url: String?, message: String?, result: JsResult): Boolean {
            result.cancel()
            return true
        }

        override fun onJsConfirm(view: WebView?, url: String?, message: String?, result: JsResult): Boolean {
            result.cancel()
            return true
        }

        override fun onJsPrompt(view: WebView?, url: String?, message: String?, defaultValue: String?, result: JsPromptResult): Boolean {
            result.cancel()
            return true
        }

        override fun onJsBeforeUnload(view: WebView?, url: String?, message: String?, result: JsResult): Boolean {
            result.confirm()
            return true
        }

        // Bundle console output is not reported (privacy, design 8.12); `diag.log` is the bridge's.
        override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean = true
    }
}

/**
 * The page's reply channel: the proxy of the document that spoke last. Before it speaks (or after a new document
 * started) envelopes wait, at most [PLUGIN_BUNDLE_PENDING_LIMIT]. Main thread only.
 */
internal class PluginBundleReply<P : Any>(private val send: (P, String) -> Unit) {
    private var proxy: P? = null
    private val pending = ArrayList<String>()

    /** The document behind [current] sent a message: answer it there from now on, with what waited. */
    fun speaking(current: P) {
        if (proxy === current) return
        proxy = current
        val waiting = pending.toList()
        pending.clear()
        waiting.forEach { runCatching { send(current, it) } }
    }

    fun post(envelope: String) {
        val current = proxy
        if (current == null) {
            if (pending.size < PLUGIN_BUNDLE_PENDING_LIMIT) pending.add(envelope)
            return
        }
        runCatching { send(current, envelope) }
    }

    /** A new document started: nobody to answer until it speaks; what waits, waits for it. */
    fun documentStarted() {
        proxy = null
    }

    /** The page went: nothing waits. */
    fun reset() {
        proxy = null
        pending.clear()
    }
}

internal const val PLUGIN_BUNDLE_PENDING_LIMIT = 64

/** The `sessionId` of an open answer this host could not use, so it can still be closed. */
internal fun pluginBundleSessionIdOf(json: String): String? =
    ((runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *>)?.get("sessionId") as? String)?.takeIf { it.isNotBlank() }

/** Where `ui.navigate` asks to go: a declarative page of the plugin, or a route of the same bundle. */
@Immutable
sealed interface FlarePluginBundleNavigation {
    data class Page(val page: String, val argumentsJson: String?) : FlarePluginBundleNavigation
    data class BundleRoute(val route: String) : FlarePluginBundleNavigation
}

/** `ui.navigate` params as a [FlarePluginBundleNavigation]; null when neither or both are given. */
internal fun pluginBundleNavigation(params: Map<String, Any?>): FlarePluginBundleNavigation? {
    val page = (params["page"] as? String)?.takeIf { it.isNotBlank() }
    val route = (params["bundleRoute"] as? String)?.takeIf { it.isNotBlank() }
    return when {
        page != null && route == null ->
            FlarePluginBundleNavigation.Page(page, (params["arguments"] as? Map<*, *>)?.let(::pluginJson))
        route != null && page == null -> FlarePluginBundleNavigation.BundleRoute(route)
        else -> null
    }
}

/** `ui.confirm` copy, bounded (design 8.6): title ≤ 64 characters, message ≤ 512, label ≤ 16. */
internal data class PluginBundleConfirm(val title: String, val message: String?, val confirmLabel: String?, val destructive: Boolean)

internal fun pluginBundleConfirm(params: Map<String, Any?>): PluginBundleConfirm? {
    val title = (params["title"] as? String)?.trim()?.takeIf { it.isNotEmpty() }?.take(64) ?: return null
    return PluginBundleConfirm(
        title = title,
        message = (params["message"] as? String)?.trim()?.takeIf { it.isNotEmpty() }?.take(512),
        confirmLabel = (params["confirmLabel"] as? String)?.trim()?.takeIf { it.isNotEmpty() }?.take(16),
        destructive = params["destructive"] == true,
    )
}

/** `ui.toast` kind to the kit's toast. */
internal fun pluginBundleToastVariant(kind: Any?): ToastVariant = when (kind) {
    "success" -> ToastVariant.Success
    "error" -> ToastVariant.Error
    else -> ToastVariant.Info
}

/** This kit's words for a bridge error code (`permission_denied`) or its message key (`plugin.bridge.permissionDenied`). */
fun flarePluginBridgeErrorText(code: String, strings: FlareStrings): String = when (code.removePrefix("plugin.bridge.")) {
    "invalid_envelope", "invalidEnvelope" -> strings.pluginBridgeErrorInvalidEnvelope
    "unsupported_bridge", "unsupportedBridge" -> strings.pluginBridgeErrorUnsupportedBridge
    "not_ready", "notReady" -> strings.pluginBridgeErrorNotReady
    "method_not_found", "methodNotFound" -> strings.pluginBridgeErrorMethodNotFound
    "invalid_params", "invalidParams" -> strings.pluginBridgeErrorInvalidParams
    "payload_too_large", "payloadTooLarge" -> strings.pluginBridgeErrorPayloadTooLarge
    "permission_denied", "permissionDenied" -> strings.pluginBridgeErrorPermissionDenied
    "rate_limited", "rateLimited" -> strings.pluginBridgeErrorRateLimited
    "cancelled" -> strings.pluginBridgeErrorCancelled
    "gesture_required", "gestureRequired" -> strings.pluginBridgeErrorGestureRequired
    "quota_exceeded", "quotaExceeded" -> strings.pluginBridgeErrorQuotaExceeded
    "not_found", "notFound" -> strings.pluginBridgeErrorNotFound
    "unavailable" -> strings.pluginBridgeErrorUnavailable
    "timeout" -> strings.pluginBridgeErrorTimeout
    "operation_failed", "operationFailed" -> strings.pluginBridgeErrorOperationFailed
    "revoked" -> strings.pluginBridgeErrorRevoked
    else -> strings.pluginBridgeErrorInternal
}

/**
 * A plugin web bundle in Compose: [FlarePluginBundleView] with the page frame (a detail or composer form bundle
 * draws none: its sheet is the frame), the opening and crash states, and the host requests drawn with kit components.
 * Needs a `FlareToastHost` ancestor (toasts, confirmations).
 *
 * - [onFallback]: show the declarative variant instead (not offered, failed to open, crashed three times, withdrawn).
 * - [onClose]: `ui.close`, with the operation result's JSON for a composer form; also a signed-out session.
 * - [onNavigate]: `ui.navigate`; false answers `not_found`.
 * - [onOpenExternal]: opens an `https` link the viewer confirmed; the default is the system browser.
 * - [onHeightChange]: `ui.resize` in a sheet (dp); without it the request is `unavailable`.
 *
 * A sheet bundle sizes itself by [modifier] (see [flarePluginBundleSheetHeight]).
 */
@Composable
fun FlarePluginBundleHost(
    request: FlarePluginBundleOpenRequest,
    channel: FlarePluginBundleChannel,
    title: String,
    onFallback: (reason: String) -> Unit,
    onClose: (resultJson: String?) -> Unit,
    modifier: Modifier = Modifier,
    onBack: (() -> Unit)? = null,
    onNavigate: ((FlarePluginBundleNavigation) -> Boolean)? = null,
    onOpenExternal: ((String) -> Unit)? = null,
    onHeightChange: ((Int) -> Unit)? = null,
) {
    val strings = flareStrings()
    val dark = flareColors().bgPrimary.luminance() < 0.5f
    val context = LocalContext.current
    val toast = LocalFlareToast.current
    val dialogs = LocalFlareDialog.current
    val scope = rememberCoroutineScope()
    var state by remember(request) { mutableStateOf<FlarePluginBundleState>(FlarePluginBundleState.Opening) }
    var pageTitle by remember(request) { mutableStateOf<String?>(null) }
    var view by remember(request) { mutableStateOf<FlarePluginBundleView?>(null) }
    val fallback by rememberUpdatedState(onFallback)
    val close by rememberUpdatedState(onClose)
    val navigate by rememberUpdatedState(onNavigate)
    val external by rememberUpdatedState(onOpenExternal)
    val resize by rememberUpdatedState(onHeightChange)
    val currentStrings by rememberUpdatedState(strings)

    val delegate = remember(request) {
        object : FlarePluginBundleHostDelegate {
            override fun onStateChanged(state: FlarePluginBundleState) {
                when (state) {
                    is FlarePluginBundleState.Fallback -> fallback(state.reason)
                    FlarePluginBundleState.Closed -> close(null)
                    else -> Unit
                }
                // Assigned after the callbacks: a fallback replaces this host, so its state is never drawn.
                setState(state)
            }

            private fun setState(next: FlarePluginBundleState) {
                state = next
            }

            override fun onHostRequest(request: FlarePluginBundleHostRequest, respond: (FlarePluginBundleHostAnswer) -> Unit) {
                val params = request.params
                when (request.method) {
                    "ui.setTitle" -> {
                        val text = (params["title"] as? String)?.trim()?.take(64)
                        if (text.isNullOrEmpty()) respond(FlarePluginBundleHostAnswer.Failed("unavailable"))
                        else { pageTitle = text; respond(FlarePluginBundleHostAnswer.Done()) }
                    }
                    "ui.toast" -> {
                        val message = (params["message"] as? String)?.trim()?.take(200)
                        if (message.isNullOrEmpty()) respond(FlarePluginBundleHostAnswer.Failed("unavailable"))
                        else { toast.show(message, pluginBundleToastVariant(params["kind"])); respond(FlarePluginBundleHostAnswer.Done()) }
                    }
                    "ui.confirm" -> {
                        val ask = pluginBundleConfirm(params)
                        if (ask == null) { respond(FlarePluginBundleHostAnswer.Failed("unavailable")); return }
                        scope.launch {
                            val confirmed = dialogs.confirm(
                                FlareConfirmOptions(title = ask.title, description = ask.message.orEmpty(), confirmText = ask.confirmLabel),
                            )
                            respond(FlarePluginBundleHostAnswer.Done(pluginJson(mapOf("confirmed" to confirmed))))
                        }
                    }
                    "ui.openExternal" -> {
                        val url = (params["url"] as? String)?.trim().orEmpty()
                        if (!flarePluginBundleExternalUrl(url)) { respond(FlarePluginBundleHostAnswer.Failed("unavailable")); return }
                        scope.launch {
                            val s = currentStrings
                            val confirmed = dialogs.confirm(
                                FlareConfirmOptions(
                                    title = s.pluginBundleExternalTitle,
                                    description = s.pluginBundleExternalMessage,
                                    target = url,
                                    confirmText = s.pluginBundleExternalOpen,
                                ),
                            )
                            if (!confirmed) { respond(FlarePluginBundleHostAnswer.Failed("cancelled")); return@launch }
                            val opened = runCatching {
                                external?.invoke(url) ?: context.startActivity(
                                    Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                        .addCategory(Intent.CATEGORY_BROWSABLE)
                                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                                )
                            }.isSuccess
                            if (opened) respond(FlarePluginBundleHostAnswer.Done())
                            else { toast.show(s.pluginBridgeErrorUnavailable, ToastVariant.Error); respond(FlarePluginBundleHostAnswer.Failed("unavailable")) }
                        }
                    }
                    "clipboard.write" -> {
                        val text = params["text"] as? String
                        val manager = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                        if (text == null || manager == null) { respond(FlarePluginBundleHostAnswer.Failed("unavailable")); return }
                        manager.setPrimaryClip(ClipData.newPlainText("", text))
                        toast.show(currentStrings.pluginBundleCopied, ToastVariant.Success)
                        respond(FlarePluginBundleHostAnswer.Done())
                    }
                    "ui.navigate" -> {
                        val target = pluginBundleNavigation(params)
                        val handled = target != null && navigate?.invoke(target) == true
                        respond(if (handled) FlarePluginBundleHostAnswer.Done() else FlarePluginBundleHostAnswer.Failed("not_found"))
                    }
                    "ui.resize" -> {
                        val height = (params["height"] as? Number)?.toInt()
                        val handler = resize
                        if (height == null || height <= 0 || handler == null) {
                            respond(FlarePluginBundleHostAnswer.Failed("unavailable"))
                        } else { handler(height); respond(FlarePluginBundleHostAnswer.Done()) }
                    }
                    "ui.close" -> {
                        respond(FlarePluginBundleHostAnswer.Done())
                        val result = (params["result"] as? Map<*, *>)?.let(::pluginJson)
                        close(result)
                    }
                    else -> respond(FlarePluginBundleHostAnswer.Failed("unavailable"))
                }
            }
        }
    }

    // The screen's lifecycle drives the page's: paused in the background, suspended after 30 s, back on return.
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle, view) {
        val target = view
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_PAUSE -> target?.onHostPause()
                Lifecycle.Event.ON_RESUME -> target?.onHostResume()
                else -> Unit
            }
        }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    DisposableEffect(view, dark) {
        view?.setDark(dark)
        onDispose {}
    }
    DisposableEffect(view, request.locale) {
        view?.setLocale(request.locale)
        onDispose {}
    }

    val body: @Composable () -> Unit = {
        Box(Modifier.fillMaxSize()) {
            key(request) {
                AndroidView(
                    factory = { ctx ->
                        FlarePluginBundleView(ctx).also { created ->
                            created.start(request, channel, delegate, dark)
                            view = created
                        }
                    },
                    onRelease = { released -> released.dispose() },
                    modifier = Modifier.fillMaxSize(),
                )
            }
            when (val shown = state) {
                FlarePluginBundleState.Opening, FlarePluginBundleState.Suspended -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    EmptyState(title = strings.pluginBundleOpening, icon = "plugin", loading = true)
                }
                is FlarePluginBundleState.Crashed -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    EmptyState(
                        title = strings.pluginBundleCrashed,
                        description = strings.pluginBundleCrashedHint,
                        actionText = strings.pluginBundleReload,
                        icon = "warning",
                        tone = FlareEmptyStateTone.Error,
                        onAction = { view?.reload() },
                    )
                }
                else -> Unit
            }
        }
    }
    if (request.presentation == FlarePluginBundlePresentation.Page) {
        FlareScreen(title = pageTitle ?: title, onBack = onBack, scroll = false) {
            Box(modifier.fillMaxSize()) { body() }
        }
    } else {
        Box(modifier) { body() }
    }
}

/** A sheet bundle's height after `ui.resize` ([height] CSS px = dp), bounded to [maxDp]. */
fun flarePluginBundleSheetHeight(height: Int, maxDp: Int): Modifier =
    Modifier.fillMaxWidth().height(height.coerceIn(1, maxDp.coerceAtLeast(1)).dp)
