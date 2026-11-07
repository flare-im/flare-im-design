package com.flare.im.ui

import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight

/**
 * The update prompt: the SDK's update status in as plain values, the kit's words, progress and actions out, and every
 * action back to the host. Spec: Feedback/UpdatePrompt (`UpdatePrompt`).
 *
 * What shows when is [flareUpdatePrompt]'s call (`spec/update-prompt-vectors.json`, the same in every kit). The prompt
 * holds no SDK and never closes itself: composing it shows it, and the host removes it. The three forms are the kit's own
 * surfaces: [FlareUpdatePromptForm.Sheet] is [BottomSheet], [FlareUpdatePromptForm.Modal] is [Modal], and
 * [FlareUpdatePromptForm.Fullscreen] a [FlareScreen] page on the overlay window, which back cannot leave.
 *
 * An action is drawn only when the host passes its handler. The scrim, Escape and back call [onLater], so they do nothing
 * on a forced prompt or one nobody can postpone. The title and the message are live regions, polite, or assertive on a
 * forced prompt; the percent stays out of them.
 */
@Composable
fun UpdatePrompt(
    /** `UpdateStatus.prompt`. */
    form: FlareUpdatePromptForm,
    /** `UpdateStatus.release?.version`; blank draws no version line. */
    version: String? = null,
    /** `UpdateStatus.release.notes`, already in the reader's language. */
    notes: List<String> = emptyList(),
    /** `UpdateStatus.blockReason`, already in the reader's language: a forced offer says it in place of its fixed words. */
    reason: String? = null,
    /** `UpdateStatus.release.sizeBytes`; null on a store update. */
    sizeBytes: Long? = null,
    /** `UpdateStatus.release.mandatory`: nothing here can postpone it. */
    mandatory: Boolean = false,
    /** `UpdateStatus.state`. */
    state: String? = null,
    /** `UpdateStatus.progress`, as it arrives. */
    progress: FlareUpdateProgress? = null,
    /** `UpdateStatus.error.code`. */
    errorCode: String? = null,
    /** `UpdateStatus.error.retryable`. */
    retryable: Boolean = true,
    /** Where the fallback goes: the website on a direct install, the app store otherwise. */
    fallbackTarget: FlareUpdateFallbackTarget = FlareUpdateFallbackTarget.Website,
    /** A forced prompt may step aside into read-only browsing. */
    canContinueReadOnly: Boolean = false,
    /** Update now, continue on a metered network, or restart to finish. */
    onUpdate: (() -> Unit)? = null,
    /** Put it off, or send the download to the background. The scrim, Escape and back ask for this too. */
    onLater: (() -> Unit)? = null,
    /** Skip this version (`update.skip`). */
    onSkip: (() -> Unit)? = null,
    /** Try the failed step again. */
    onRetry: (() -> Unit)? = null,
    /** Open the website or the app store. */
    onFallback: (() -> Unit)? = null,
    /** Step aside into read-only browsing. */
    onContinueReadOnly: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val model = flareUpdatePrompt(form, mandatory, state, progress, errorCode, retryable, sizeBytes, canContinueReadOnly, reason)
    val title = model.title.label(strings)
    val dismissible = model.dismissible && onLater != null
    val handlers: (FlareUpdatePromptAction) -> (() -> Unit)? = { action ->
        when (action) {
            FlareUpdatePromptAction.Update, FlareUpdatePromptAction.ContinueDownload, FlareUpdatePromptAction.Restart -> onUpdate
            FlareUpdatePromptAction.Retry -> onRetry
            FlareUpdatePromptAction.Fallback -> onFallback
            FlareUpdatePromptAction.Later, FlareUpdatePromptAction.Background -> onLater
            FlareUpdatePromptAction.Skip -> onSkip
            FlareUpdatePromptAction.ContinueReadOnly -> onContinueReadOnly
        }
    }
    val body: @Composable (Modifier) -> Unit = { modifier ->
        UpdatePromptBody(modifier, model, version, notes, reason, sizeBytes, progress, fallbackTarget, handlers)
    }
    when (form) {
        FlareUpdatePromptForm.Sheet -> BottomSheet(
            onClose = { onLater?.invoke() },
            title = title,
            titleHidden = true,
            dismissible = dismissible,
        ) {
            body(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(FlareSizes.spacingLg))
        }
        FlareUpdatePromptForm.Modal -> Modal(
            onClose = { onLater?.invoke() },
            title = title,
            titleHidden = true,
            dismissible = dismissible,
            showClose = false,
            scrollable = false,
        ) {
            body(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()))
        }
        FlareUpdatePromptForm.Fullscreen -> UpdatePromptPage(title) {
            body(Modifier.widthIn(max = FlareSizes.componentSheetDialogWidth).fillMaxWidth())
        }
    }
}

/** The fullscreen form: a page on the shared overlay window, so it covers the app and back cannot leave it. */
@Composable
private fun UpdatePromptPage(title: String, content: @Composable () -> Unit) {
    val reducedMotion = flareReducedMotion()
    FlareOverlayScaffold(
        kind = FlareOverlaySurfaceKind.Modal,
        onClose = {},
        dismissible = false,
        scrim = flareColors().bgPrimary,
        scrimLabel = null,
        contentAlignment = Alignment.Center,
        enter = if (reducedMotion) EnterTransition.None else fadeIn(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)),
        exit = if (reducedMotion) ExitTransition.None else fadeOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)),
    ) { _, _ ->
        Box(Modifier.fillMaxSize().semantics { paneTitle = title }) {
            FlareScreen(surface = FlareScreenSurface.Surface, padded = true) {
                Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) { content() }
            }
        }
    }
}

@Composable
private fun UpdatePromptBody(
    modifier: Modifier,
    model: FlareUpdatePromptModel,
    version: String?,
    notes: List<String>,
    reason: String?,
    sizeBytes: Long?,
    progress: FlareUpdateProgress?,
    fallbackTarget: FlareUpdateFallbackTarget,
    handlers: (FlareUpdatePromptAction) -> (() -> Unit)?,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val size = sizeBytes?.let { formatBytes(it.toDouble()) }
    val title = model.title.label(strings)
    val versionText = if (flareUpdateVersionShown(version)) "${strings.updatePromptVersion} $version" else null
    val mode = if (model.live == FlareUpdatePromptLive.Assertive) LiveRegionMode.Assertive else LiveRegionMode.Polite
    val drawn = model.actions.filter { handlers(it) != null }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            Text(
                title,
                color = colors.textPrimary,
                fontSize = FlareSizes.fontSizeXl,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.semantics {
                    heading()
                    liveRegion = mode
                },
            )
            versionText?.let { text ->
                Text(
                    if (size == null) text else "$text · $size",
                    color = colors.textSecondary,
                    fontSize = FlareTextRoles.Caption.fontSize,
                )
            }
        }
        model.message?.let { message ->
            Text(
                message.label(strings, size, reason),
                color = colors.textSecondary,
                fontSize = FlareTextRoles.Body.fontSize,
                modifier = Modifier.semantics { liveRegion = mode },
            )
        }
        model.progress?.let { bar ->
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                ProgressBar(value = bar.value, indeterminate = bar.value == null, label = title)
                updatePromptProgressText(bar, progress)?.let { text ->
                    Text(text, color = colors.textSecondary, fontSize = FlareTextRoles.Caption.fontSize)
                }
            }
        }
        if (model.notes && notes.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(
                    strings.updatePromptNotes,
                    color = colors.textPrimary,
                    fontSize = FlareTextRoles.Body.fontSize,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.semantics { heading() },
                )
                notes.forEach { note ->
                    Text("• $note", color = colors.textSecondary, fontSize = FlareTextRoles.Body.fontSize)
                }
            }
        }
        if (drawn.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                drawn.forEachIndexed { index, action ->
                    Button(
                        label = action.label(strings, fallbackTarget),
                        variant = updatePromptVariant(action, index),
                        size = FlareControlSize.Lg,
                        block = true,
                        onClick = handlers(action),
                    )
                }
            }
        }
    }
}

/** The first action drawn is primary; a way that still gets somewhere is secondary, and the rest step back. */
private fun updatePromptVariant(action: FlareUpdatePromptAction, index: Int): FlareButtonVariant = when {
    index == 0 -> FlareButtonVariant.Primary
    action == FlareUpdatePromptAction.Fallback || action == FlareUpdatePromptAction.ContinueReadOnly -> FlareButtonVariant.Secondary
    else -> FlareButtonVariant.Quiet
}

private fun updatePromptProgressText(bar: FlareProgressBarValue, progress: FlareUpdateProgress?): String? {
    val percent = bar.percent ?: return null
    val received = progress?.received?.let { formatBytes(it.toDouble()) }
    val total = progress?.total?.let { formatBytes(it.toDouble()) }
    return if (received != null && total != null) "$percent% · $received / $total" else "$percent%"
}
