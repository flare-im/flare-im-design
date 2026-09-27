package com.flare.im.ui

import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp

/** How far a modal grows from while it appears (and shrinks to while it leaves). */
private const val FLARE_MODAL_ENTER_SCALE = 0.96f

/**
 * Modal — a centered box over the token scrim for focused tasks (global search, wider editing flows).
 * Spec: Overlay/Modal (`Modal`).
 *
 * Composing it shows it; the host removes it in [onClose], which runs after the exit animation (at once
 * under reduced motion). It opens a full-display dialog window whose platform dim is off: the scrim is
 * `colors.scrim`, and the box is [width] wide (default `FlareSizes.componentSheetDialogWidth`) but never
 * closer than spacing-xl to the window's sides, and at most [maxHeight] tall (default 72% of the window
 * after the keyboard and the safe area). With [fill] it always takes that whole height, so page-like
 * content does not resize as results arrive.
 *
 * The header row is `title … [actions] [close?]` and is left out when there is nothing to show; [footer]
 * is the button row under the body. While [dismissible] and not [busy], the scrim, system back, Escape
 * and the close button close it; otherwise they do nothing and the close button stays, disabled. With
 * [scrollable] the body scrolls inside the cap; without, [content] owns its scrolling and gets bounded
 * constraints (lists, search results). The pane is named by [title], else [label], else the strings
 * table's `modalLabel`.
 */
@Composable
fun Modal(
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    titleHidden: Boolean = false,
    label: String? = null,
    width: Dp = FlareSizes.componentSheetDialogWidth,
    maxHeight: Dp? = null,
    fill: Boolean = false,
    dismissible: Boolean = true,
    showClose: Boolean = true,
    busy: Boolean = false,
    scrollable: Boolean = true,
    actions: (@Composable RowScope.() -> Unit)? = null,
    footer: (@Composable () -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    FlareModalLayer(
        onClose = onClose,
        modifier = modifier,
        title = title,
        titleHidden = titleHidden,
        label = label,
        fallbackLabel = flareStrings().modalLabel,
        width = width,
        maxHeight = maxHeight,
        fill = fill,
        dismissible = dismissible,
        showClose = showClose,
        busy = busy,
        scrollable = scrollable,
        actions = actions,
        footer = footer,
        bodyPadding = PaddingValues(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        content = content,
    )
}

/**
 * The one centered-box implementation: [Modal] and the wide form of [BottomSheet] (which hands its content here
 * with no close button and no body padding, since sheet content brings its own) both draw through it.
 */
@Composable
internal fun FlareModalLayer(
    onClose: () -> Unit,
    modifier: Modifier,
    title: String?,
    titleHidden: Boolean,
    label: String?,
    fallbackLabel: String,
    width: Dp,
    maxHeight: Dp?,
    fill: Boolean,
    dismissible: Boolean,
    showClose: Boolean,
    busy: Boolean,
    scrollable: Boolean,
    actions: (@Composable RowScope.() -> Unit)?,
    footer: (@Composable () -> Unit)?,
    bodyPadding: PaddingValues,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    val open = dismissible && !busy
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    val depth = flareShadowElevation(flareShadows().xl)
    FlareOverlayScaffold(
        kind = FlareOverlaySurfaceKind.Modal,
        onClose = onClose,
        dismissible = open,
        scrim = colors.scrim,
        scrimLabel = if (flareScrimAnnounced(open, showClose)) strings.close else null,
        contentAlignment = Alignment.Center,
        enter = if (reducedMotion) EnterTransition.None
        else fadeIn(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) +
            scaleIn(tween(FlareMotion.normal, easing = FlareMotion.normalEasing), initialScale = FLARE_MODAL_ENTER_SCALE),
        exit = if (reducedMotion) ExitTransition.None
        else fadeOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) +
            scaleOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing), targetScale = FLARE_MODAL_ENTER_SCALE),
        // A floating box: the bars and the keyboard are margins around it, never padding inside it. Resolved in the
        // dialog window (whose insets include the keyboard it raises) and consumed, so a hosted FlareScreen does
        // not pad for them again.
        boundsModifier = Modifier.safeDrawingPadding(),
    ) { close, bounds ->
        val boxWidth = flareModalWidth(width, bounds.width)
        val room = bounds.height - FlareSizes.spacingXl * 2
        val cap = flareOverlayMaxHeight(maxHeight, available = bounds.height, ceiling = room)
        Column(
            modifier.width(boxWidth)
                .then(if (fill) Modifier.height(cap) else Modifier.heightIn(max = cap))
                .shadow(depth, shape, clip = false)
                .clip(shape)
                .background(colors.bgPrimary)
                // A tap on the box itself never reaches the scrim behind it.
                .pointerInput(Unit) { detectTapGestures {} }
                .semantics { paneTitle = flareOverlayPaneTitle(title, label, fallbackLabel) },
        ) {
            if (flareOverlayHeaderVisible(title, titleHidden, actions != null, showClose, showBack = false)) {
                FlareOverlayHeader(
                    title = title,
                    titleHidden = titleHidden,
                    showBack = false,
                    showClose = showClose,
                    enabled = open,
                    onBack = {},
                    onClose = close,
                    actions = actions,
                )
            } else {
                Spacer(Modifier.height(FlareSizes.spacingSm))
            }
            val body = Modifier.fillMaxWidth().weight(1f, fill = fill)
            if (scrollable) {
                Column(body.verticalScroll(rememberScrollState()).padding(bodyPadding)) { content() }
            } else {
                Column(body.padding(bodyPadding)) { content() }
            }
            if (footer != null) {
                Box(
                    Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
                    contentAlignment = Alignment.CenterEnd,
                ) { footer() }
            }
        }
    }
}
