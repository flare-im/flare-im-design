package com.flare.im.ui.bundlehost

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.View
import com.flare.im.ui.FlarePluginBundleChannel
import com.flare.im.ui.FlarePluginBundleEvents
import com.flare.im.ui.FlarePluginBundleHostAnswer
import com.flare.im.ui.FlarePluginBundleHostDelegate
import com.flare.im.ui.FlarePluginBundleHostRequest
import com.flare.im.ui.FlarePluginBundleOpenRequest
import com.flare.im.ui.FlarePluginBundlePresentation
import com.flare.im.ui.FlarePluginBundleResult
import com.flare.im.ui.FlarePluginBundleRuntime
import com.flare.im.ui.FlarePluginBundleState
import com.flare.im.ui.FlarePluginBundleView
import com.flare.im.ui.flarePluginBundleExternalUrl
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONObject

/*
 * The Android side of flare_plugin_bundle_host: the kit's FlarePluginBundleView (no Compose) in a Flutter platform
 * view. The view does the sandbox, the file interception, the bridge and the lifecycle exactly as in a native app; its
 * engine calls (FlarePluginBundleChannel) go back to Dart over the `flare_plugin_bundle_host` channel, where the app's
 * core SDK runs them, and what it asks the host to draw (`ui.*`, `clipboard.write`) and its states go to the Dart
 * widget over the view's own channel.
 */

/** The channel both sides use. */
internal const val BUNDLE_CHANNEL = "flare_plugin_bundle_host"

/** The platform view type. */
internal const val BUNDLE_VIEW_TYPE = "flare_plugin_bundle_host/view"

/**
 * The kit's Android library declares API 26; this app-facing host loads it only from there (the Flutter app's own floor
 * may be lower, with the library's minimum overridden), so below it no runtime is reported (D-17).
 */
internal const val BUNDLE_MIN_SDK = 26

class FlarePluginBundleHostPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var context: Context? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        val channel = MethodChannel(binding.binaryMessenger, BUNDLE_CHANNEL)
        channel.setMethodCallHandler(this)
        this.channel = channel
        binding.platformViewRegistry.registerViewFactory(
            BUNDLE_VIEW_TYPE,
            BundleViewFactory(binding.binaryMessenger, DartBundleEngine(channel)),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = context ?: return result.error("unavailable", null, null)
        when (call.method) {
            "runtime" -> result.success(
                if (Build.VERSION.SDK_INT >= BUNDLE_MIN_SDK) FlarePluginBundleRuntime.profileJson(context) else null,
            )
            "event" -> {
                val payload = call.argument<String>("payload")
                result.success(payload != null && Build.VERSION.SDK_INT >= BUNDLE_MIN_SDK && FlarePluginBundleEvents.dispatch(payload))
            }
            "unmetered" -> result.success(unmeteredNetwork(context))
            else -> result.notImplemented()
        }
    }
}

/** Whether the device is on an unmetered network (Wi-Fi), the only place entry bundles are fetched ahead. */
internal fun unmeteredNetwork(context: Context): Boolean {
    val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return false
    val capabilities = runCatching { manager.getNetworkCapabilities(manager.activeNetwork) }.getOrNull() ?: return false
    return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) ||
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
}

/**
 * The engine's routes, run by Dart: `engine` `{route, payload}` with the payload as JSON text. Dart answers the
 * engine's object as JSON text, or an error whose code is the refusal's reason. Calls go out on the main thread and
 * may come from any.
 */
internal class DartBundleEngine(private val channel: MethodChannel) : FlarePluginBundleChannel {
    private val main = Handler(Looper.getMainLooper())

    private fun call(route: String, payload: () -> JSONObject, answer: ((FlarePluginBundleResult) -> Unit)?) {
        val text = runCatching { payload().toString() }.getOrElse {
            answer?.invoke(FlarePluginBundleResult.Failure("invalid_request"))
            return
        }
        main.post {
            channel.invokeMethod(
                "engine",
                mapOf("route" to route, "payload" to text),
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        answer?.invoke(engineAnswer(result))
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        answer?.invoke(FlarePluginBundleResult.Failure(engineFailureReason(errorCode)))
                    }

                    override fun notImplemented() {
                        answer?.invoke(FlarePluginBundleResult.Failure("unavailable"))
                    }
                },
            )
        }
    }

    override fun open(requestJson: String, answer: (FlarePluginBundleResult) -> Unit) =
        call("plugin_bundle_open", { JSONObject(requestJson) }, answer)

    override fun bridge(sessionId: String, envelope: String, userGesture: Boolean, answer: (FlarePluginBundleResult) -> Unit) =
        call(
            "plugin_bundle_bridge",
            { JSONObject().put("sessionId", sessionId).put("envelope", envelope).put("userGesture", userGesture) },
            answer,
        )

    override fun hostResult(
        sessionId: String,
        id: String,
        resultJson: String?,
        error: String?,
        answer: (FlarePluginBundleResult) -> Unit,
    ) = call(
        "plugin_bundle_host_result",
        {
            val payload = JSONObject().put("sessionId", sessionId).put("id", id)
            if (error != null) payload.put("error", error) else payload.put("result", JSONObject(resultJson ?: "{}"))
        },
        answer,
    )

    override fun hostEvent(sessionId: String, event: String, payloadJson: String, answer: (FlarePluginBundleResult) -> Unit) =
        call(
            "plugin_bundle_host_event",
            { JSONObject().put("event", event).put("payload", JSONObject(payloadJson)).put("sessionId", sessionId) },
            answer,
        )

    override fun close(sessionId: String) = call("plugin_bundle_close", { JSONObject().put("sessionId", sessionId) }, null)
}

/** Dart's answer to an engine call: the object's JSON text, anything else is `unavailable`. */
internal fun engineAnswer(result: Any?): FlarePluginBundleResult =
    (result as? String)?.takeIf { it.isNotBlank() }?.let { FlarePluginBundleResult.Answer(it) }
        ?: FlarePluginBundleResult.Failure("unavailable")

/** A refusal's reason as Dart names it (`not_offered`, ...); anything that is not one is `unavailable`. */
internal fun engineFailureReason(code: String?): String =
    code?.takeIf { it.isNotEmpty() && it.all { c -> c in 'a'..'z' || c == '_' } } ?: "unavailable"

/** The open request the Dart widget sent (the request without the theme, as JSON text); null when it is not one. */
internal fun bundleOpenRequestOf(text: String?): FlarePluginBundleOpenRequest? {
    val json = runCatching { JSONObject(text ?: return null) }.getOrNull() ?: return null
    val pluginId = json.optString("pluginId").takeIf { it.isNotBlank() } ?: return null
    val contributionId = json.optString("contributionId").takeIf { it.isNotBlank() } ?: return null
    val presentation = bundlePresentationOf(json.optString("presentation"))
    val conversation = json.optJSONObject("conversation")
    return FlarePluginBundleOpenRequest(
        pluginId = pluginId,
        contributionId = contributionId,
        route = json.optString("route").takeIf { it.isNotBlank() },
        argumentsJson = json.optJSONObject("arguments")?.toString(),
        presentation = presentation,
        conversationId = conversation?.optString("id")?.takeIf { it.isNotBlank() },
        conversationType = conversation?.optString("type")?.takeIf { it.isNotBlank() },
        locale = json.optString("locale"),
    )
}

/** The wire name of a presentation; an unknown one is a page. */
internal fun bundlePresentationOf(wire: String?): FlarePluginBundlePresentation =
    FlarePluginBundlePresentation.entries.firstOrNull { it.wire == wire } ?: FlarePluginBundlePresentation.Page

/** A state as the Dart widget reads it: `{state, reason?, count?}`. */
internal fun bundleStateArguments(state: FlarePluginBundleState): Map<String, Any?> = when (state) {
    FlarePluginBundleState.Opening -> mapOf("state" to "opening")
    FlarePluginBundleState.Ready -> mapOf("state" to "ready")
    FlarePluginBundleState.Suspended -> mapOf("state" to "suspended")
    is FlarePluginBundleState.Crashed -> mapOf("state" to "crashed", "count" to state.count)
    is FlarePluginBundleState.Fallback -> mapOf("state" to "fallback", "reason" to state.reason)
    FlarePluginBundleState.Closed -> mapOf("state" to "closed")
}

/** The Dart widget's answer to a host request: `{result}` (an object's JSON text) or `{error}`. */
internal fun bundleHostAnswerOf(answer: Any?): FlarePluginBundleHostAnswer {
    val map = answer as? Map<*, *> ?: return FlarePluginBundleHostAnswer.Failed("unavailable")
    (map["error"] as? String)?.let { return FlarePluginBundleHostAnswer.Failed(engineFailureReason(it)) }
    val result = (map["result"] as? String)?.takeIf { it.trim().startsWith("{") } ?: "{}"
    return FlarePluginBundleHostAnswer.Done(result)
}

internal class BundleViewFactory(
    private val messenger: BinaryMessenger,
    private val engine: FlarePluginBundleChannel,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        BundlePlatformView(context, MethodChannel(messenger, "$BUNDLE_VIEW_TYPE/view_$viewId"), engine, args as? Map<*, *>)
}

/**
 * One bundle page: the kit view, its delegate (states and host requests go to the Dart widget) and what the widget
 * tells it (the screen paused or resumed, the theme, the locale, reload, an external link it confirmed).
 */
internal class BundlePlatformView(
    private val context: Context,
    private val channel: MethodChannel,
    engine: FlarePluginBundleChannel,
    params: Map<*, *>?,
) : PlatformView, MethodChannel.MethodCallHandler, FlarePluginBundleHostDelegate {
    private val view = FlarePluginBundleView(context)
    private var disposed = false

    /**
     * The last state, for the widget's `attach`: a state sent before the widget's handler was set (a fallback right at
     * creation) would otherwise be lost.
     */
    private var lastState: FlarePluginBundleState = FlarePluginBundleState.Opening

    init {
        channel.setMethodCallHandler(this)
        val request = bundleOpenRequestOf(params?.get("request") as? String)
        when {
            request == null -> onStateChanged(FlarePluginBundleState.Fallback("invalid_request"))
            Build.VERSION.SDK_INT < BUNDLE_MIN_SDK -> onStateChanged(FlarePluginBundleState.Fallback("unsupported"))
            else -> view.start(request, engine, this, params?.get("dark") == true)
        }
    }

    override fun getView(): View = view

    override fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        view.dispose()
    }

    override fun onStateChanged(state: FlarePluginBundleState) {
        lastState = state
        if (!disposed) channel.invokeMethod("state", bundleStateArguments(state))
    }

    override fun onHostRequest(request: FlarePluginBundleHostRequest, respond: (FlarePluginBundleHostAnswer) -> Unit) {
        val arguments = mapOf("id" to request.id, "method" to request.method, "params" to request.paramsJson)
        Handler(Looper.getMainLooper()).post {
            if (disposed) return@post respond(FlarePluginBundleHostAnswer.Failed("unavailable"))
            channel.invokeMethod("hostRequest", arguments, object : MethodChannel.Result {
                override fun success(result: Any?) = respond(bundleHostAnswerOf(result))

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
                    respond(FlarePluginBundleHostAnswer.Failed("unavailable"))

                override fun notImplemented() = respond(FlarePluginBundleHostAnswer.Failed("unavailable"))
            })
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (disposed) return result.error("unavailable", null, null)
        when (call.method) {
            "attach" -> result.success(bundleStateArguments(lastState))
            "pause" -> { view.onHostPause(); result.success(null) }
            "resume" -> { view.onHostResume(); result.success(null) }
            "setDark" -> { view.setDark(call.argument<Boolean>("dark") == true); result.success(null) }
            "setLocale" -> {
                call.argument<String>("locale")?.takeIf { it.isNotBlank() }?.let(view::setLocale)
                result.success(null)
            }
            "reload" -> { view.reload(); result.success(null) }
            "openExternal" -> result.success(openExternal(call.argument<String>("url")))
            else -> result.notImplemented()
        }
    }

    /** An https link the viewer confirmed in Dart, in the system browser (D-13). */
    private fun openExternal(url: String?): Boolean {
        if (url == null || !flarePluginBundleExternalUrl(url)) return false
        return runCatching {
            context.startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    .addCategory(Intent.CATEGORY_BROWSABLE)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }.isSuccess
    }
}
