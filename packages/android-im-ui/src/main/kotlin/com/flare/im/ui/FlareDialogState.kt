package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.channels.Channel

/**
 * A destructive or irreversible step the user must confirm, asked through [FlareDialogState.confirm]
 * and shown as [DangerConfirm] (the Vue and iOS `FlareConfirmOptions`).
 */
@Immutable
data class FlareConfirmOptions(
    val title: String,
    val description: String,
    /** What the step applies to (a message, a contact), on its own line; null shows none. */
    val target: String? = null,
    /** Defaults to the strings table's confirm action. */
    val confirmText: String? = null,
    /** Defaults to the strings table's cancel. */
    val cancelText: String? = null,
    /**
     * Runs after the user confirms, with the dialog busy. A thrown error keeps the dialog open showing the
     * error's message, so the user can confirm again to retry, or cancel.
     */
    val action: (suspend () -> Unit)? = null,
)

/** One value the user types (a remark, a group name, a comment), asked through [FlareDialogState.prompt]. */
@Immutable
data class FlarePromptOptions(
    val title: String,
    /** A line above the field explaining what the value is for; null shows none. */
    val message: String? = null,
    /** The draft the field opens with (the current remark, say). */
    val value: String = "",
    val placeholder: String? = null,
    val maxLength: Int? = null,
    val multiline: Boolean = false,
    /** Whether an empty value can be confirmed (clearing a remark); otherwise confirm waits for text. */
    val allowEmpty: Boolean = false,
    /** Defaults to the strings table's confirm action. */
    val confirmText: String? = null,
    /** Defaults to the strings table's cancel. */
    val cancelText: String? = null,
    /**
     * Runs with the trimmed value after the user confirms, with the dialog busy. A thrown error keeps the dialog
     * open with the draft and the error's message; confirming again retries.
     */
    val submit: (suspend (String) -> Unit)? = null,
)

/** The dialog on screen: exactly one of [confirm] / [prompt], whether its work runs, and the last failure. */
@Immutable
internal data class FlareDialogRequest(
    val id: Long,
    val confirm: FlareConfirmOptions? = null,
    val prompt: FlarePromptOptions? = null,
    val busy: Boolean = false,
    val error: String? = null,
)

/**
 * Confirm and prompt presenter state, drawn by [FlareToastHost] and reached below it through
 * [LocalFlareDialog] (the Vue `useFlareConfirm` and iOS `FlareFeedback` contract, plus a single-value
 * prompt). Screens ask and suspend; they hold no dialog, busy or error state of their own:
 *
 * ```kotlin
 * val dialogs = LocalFlareDialog.current
 * scope.launch {
 *     if (dialogs.confirm(FlareConfirmOptions("删除好友", "确定删除？", action = { removeOrThrow() }))) onBack()
 * }
 * ```
 *
 * One dialog shows at a time: a newer request replaces an idle one (which resolves as cancelled), and a
 * request made while one is busy resolves as cancelled at once. Cancelling the asking coroutine closes its
 * dialog, and stops its work.
 */
@Stable
class FlareDialogState {
    private val lock = Any()
    private var nextId = 0L
    private var decisions: Channel<String?>? = null

    internal var request by mutableStateOf<FlareDialogRequest?>(null)
        private set

    /** Asks the user to confirm; true once confirmed and [FlareConfirmOptions.action] (if any) succeeded, false when cancelled. */
    suspend fun confirm(options: FlareConfirmOptions): Boolean =
        present(FlareDialogRequest(id = 0, confirm = options)) { options.action?.invoke() } != null

    /** Asks the user for one value; the trimmed value once confirmed and [FlarePromptOptions.submit] (if any) succeeded, null when cancelled. */
    suspend fun prompt(options: FlarePromptOptions): String? =
        present(FlareDialogRequest(id = 0, prompt = options)) { value -> options.submit?.invoke(value) }

    private suspend fun present(initial: FlareDialogRequest, work: suspend (String) -> Unit): String? {
        val channel = Channel<String?>(Channel.CONFLATED)
        synchronized(lock) {
            if (request?.busy == true) return null
            // The idle dialog on screen is replaced, and counts as cancelled.
            decisions?.trySend(null)
            decisions = channel
            request = initial.copy(id = ++nextId)
        }
        try {
            while (true) {
                val value = channel.receive() ?: return null
                try {
                    work(value)
                    return value
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (failure: Throwable) {
                    val message = failure.message?.takeIf { it.isNotBlank() } ?: failure.toString()
                    synchronized(lock) {
                        if (decisions === channel) request = request?.copy(busy = false, error = message)
                    }
                }
            }
        } finally {
            synchronized(lock) {
                if (decisions === channel) {
                    decisions = null
                    request = null
                }
            }
        }
    }

    /**
     * The confirm button: marks the dialog busy and hands [value] (a prompt's draft, trimmed) to the asking
     * coroutine. Ignored while busy, and for a prompt whose empty value is not allowed.
     */
    internal fun accept(value: String = "") {
        synchronized(lock) {
            val current = request ?: return
            if (current.busy) return
            val prompt = current.prompt
            val submitted = if (prompt != null) value.trim() else ""
            if (prompt != null && !prompt.allowEmpty && submitted.isEmpty()) return
            request = current.copy(busy = true, error = null)
            decisions?.trySend(submitted)
        }
    }

    /** The cancel button, back or a tap outside: closes an idle dialog at once. Ignored while busy. */
    internal fun cancel() {
        synchronized(lock) {
            val current = request ?: return
            if (current.busy) return
            decisions?.trySend(null)
            decisions = null
            request = null
        }
    }
}

@Composable
fun rememberFlareDialogState(): FlareDialogState = remember { FlareDialogState() }

/**
 * The confirm and prompt presenter of the nearest [FlareToastHost]:
 * `LocalFlareDialog.current.prompt(FlarePromptOptions("修改备注"))`. Reading it outside a host is an error.
 */
val LocalFlareDialog = staticCompositionLocalOf<FlareDialogState> {
    error("LocalFlareDialog needs a FlareToastHost ancestor: install FlareToastHost at the root of the app.")
}

/** Draws the request of [state]: a [DangerConfirm] for a confirmation, the prompt dialog for a value. */
@Composable
internal fun FlareDialogPresenter(state: FlareDialogState) {
    val request = state.request ?: return
    key(request.id) {
        request.confirm?.let { options ->
            DangerConfirm(
                title = options.title,
                description = options.description,
                target = options.target.orEmpty(),
                busy = request.busy,
                error = request.error,
                confirmText = options.confirmText,
                cancelText = options.cancelText,
                onConfirm = { state.accept() },
                onCancel = { state.cancel() },
            )
        }
        request.prompt?.let { options ->
            FlarePromptDialog(options, request.busy, request.error, onConfirm = state::accept, onCancel = state::cancel)
        }
    }
}

/** The prompt: the kit [FormDialog] around one kit [Input]; the draft survives a failed submit. */
@Composable
private fun FlarePromptDialog(
    options: FlarePromptOptions,
    busy: Boolean,
    error: String?,
    onConfirm: (String) -> Unit,
    onCancel: () -> Unit,
) {
    val strings = flareStrings()
    val colors = flareColors()
    var draft by remember { mutableStateOf(options.value) }
    val filled = options.allowEmpty || draft.isNotBlank()
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }
    FormDialog(
        title = options.title,
        confirmLabel = options.confirmText ?: strings.confirmAction,
        cancelLabel = options.cancelText ?: strings.cancel,
        onClose = onCancel,
        onConfirm = { onConfirm(draft) },
        confirmEnabled = filled,
        busy = busy,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            options.message?.takeIf { it.isNotBlank() }?.let {
                Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd)
            }
            FormField(error = error) {
                Box(Modifier.focusRequester(focus)) {
                    Input(
                        value = draft,
                        onValueChange = { draft = it },
                        placeholder = options.placeholder,
                        multiline = options.multiline,
                        maxLength = options.maxLength,
                        disabled = busy,
                        onSubmit = { if (filled && !busy && !options.multiline) onConfirm(draft) },
                    )
                }
            }
        }
    }
}
