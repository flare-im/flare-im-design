package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf

/** Toasts on screen at once; a new one pushes out the oldest (the web presenter's limit). */
internal const val FLARE_TOAST_LIMIT = 3

/** One toast of a [FlareToastState] stack. */
@Immutable
internal data class FlareToastEntry(
    val id: Long,
    val message: String,
    val variant: ToastVariant,
    val tone: FlareStatusTone?,
    val actionLabel: String?,
    /** Milliseconds on screen; 0 keeps the toast until its action or close runs. */
    val durationMs: Long,
)

/**
 * How long a toast stays: the host's [durationMs] (0 = until dismissed), else 4 s, or 6 s
 * for the danger tone. Danger is the tone the toast renders — an explicit [tone] wins over
 * the [ToastVariant.Error] variant, and a loading toast is never danger.
 */
internal fun flareToastDurationMs(variant: ToastVariant, tone: FlareStatusTone?, durationMs: Long?): Long {
    if (durationMs != null) return durationMs.coerceAtLeast(0)
    val danger = when {
        variant == ToastVariant.Loading -> false
        tone != null -> tone == FlareStatusTone.Danger
        else -> variant == ToastVariant.Error
    }
    return if (danger) 6_000 else 4_000
}

/**
 * Toast presenter state — a bounded stack that [FlareToastHost] draws and times. Screens
 * reach the host's state through [LocalFlareToast]; a host may also pass in a state it
 * created outside composition (a view model, a session), and [show] may be called from
 * any thread.
 */
@Stable
class FlareToastState {
    private val lock = Any()
    private var nextId = 0L
    private val actions = HashMap<Long, () -> Unit>()
    internal val entries = mutableStateListOf<FlareToastEntry>()

    /**
     * Shows [message] and returns a function that dismisses this toast early. [durationMs]
     * defaults to 4000, or 6000 for the danger tone; 0 keeps the toast until its action or
     * close runs. Running [onAction] (labelled [actionLabel]) dismisses the toast. At most
     * three toasts stay on screen: a new one removes the oldest.
     */
    fun show(
        message: String,
        variant: ToastVariant = ToastVariant.Info,
        tone: FlareStatusTone? = null,
        actionLabel: String? = null,
        onAction: (() -> Unit)? = null,
        durationMs: Long? = null,
    ): () -> Unit {
        val id = synchronized(lock) {
            val id = ++nextId
            entries += FlareToastEntry(id, message, variant, tone, actionLabel, flareToastDurationMs(variant, tone, durationMs))
            if (onAction != null) actions[id] = onAction
            while (entries.size > FLARE_TOAST_LIMIT) actions.remove(entries.removeAt(0).id)
            id
        }
        return { dismiss(id) }
    }

    internal fun dismiss(id: Long) {
        synchronized(lock) {
            entries.removeAll { it.id == id }
            actions.remove(id)
        }
    }

    internal fun runAction(id: Long) {
        val action = synchronized(lock) { actions[id] }
        dismiss(id)
        action?.invoke()
    }
}

@Composable
fun rememberFlareToastState(): FlareToastState = remember { FlareToastState() }

/**
 * The toast presenter of the nearest FlareToastHost: `LocalFlareToast.current.show("已保存")`.
 * Reading it outside a host is an error — there would be nothing to draw the toast.
 */
val LocalFlareToast = staticCompositionLocalOf<FlareToastState> {
    error("LocalFlareToast needs a FlareToastHost ancestor: install FlareToastHost at the root of the app.")
}
