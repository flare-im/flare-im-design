package com.flare.im.ui

import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp

/** The inline edge a [Drawer] docks to; it follows the layout direction (End is the left edge under RTL). */
enum class FlareDrawerPlacement { End, Start }

/**
 * Drawer — a full-height modal panel sliding in from the inline end (default) or start edge over the token scrim,
 * for long-lived secondary content beside the main view: conversation, group and contact details, settings
 * stacks, the profile editor. Spec: Overlay/Drawer (`Drawer`). On the phone form factor such content is a page
 * instead: hosts decide with [flareCompactOverlays] (and their own single-pane layout fact, which wins).
 *
 * Composing it shows it; the host removes it in [onClose], which runs after the slide out (at once under reduced
 * motion). It opens a full-display dialog window whose platform dim is off: the scrim is `colors.scrim`, and the
 * panel is [width] wide (default `FlareSizes.componentSheetWidth`) but always leaves a touch target of scrim to
 * tap. The panel reaches under the status and navigation bars and keeps its content clear of them, so a hosted
 * page (a FlareScreen) does not pad for them again.
 *
 * The header row is `[back?] title … [actions] [close?]`; there is none when there is no visible title, no
 * [actions], no back and no close — page content that brings its own header passes [label] for the name and
 * `showClose = false`. [content] always gets the bounded remaining height and owns its scrolling; [footer] sticks
 * to the bottom. With [showBack] the host steps its own pages inside [content]: the back control, system back and
 * Escape run [onBack] instead of closing, and focus moves to the panel whenever the back state or the title
 * changes. While not [dismissible], the scrim, back, Escape and the header controls do nothing (the controls stay,
 * disabled). The pane is named by [title], else [label], else the strings table's `drawerLabel`.
 */
@Composable
fun Drawer(
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    titleHidden: Boolean = false,
    label: String? = null,
    placement: FlareDrawerPlacement = FlareDrawerPlacement.End,
    width: Dp = FlareSizes.componentSheetWidth,
    dismissible: Boolean = true,
    showClose: Boolean = true,
    showBack: Boolean = false,
    onBack: (() -> Unit)? = null,
    actions: (@Composable RowScope.() -> Unit)? = null,
    footer: (@Composable () -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    val sign = flareDrawerSlideSign(placement, LocalLayoutDirection.current)
    val end = placement == FlareDrawerPlacement.End
    // Rounded on the edge that faces the content it covers; start/end corners mirror with the layout direction.
    val shape = if (end) {
        RoundedCornerShape(topStart = FlareSizes.radiusXl, bottomStart = FlareSizes.radiusXl)
    } else {
        RoundedCornerShape(topEnd = FlareSizes.radiusXl, bottomEnd = FlareSizes.radiusXl)
    }
    val depth = flareShadowElevation(flareShadows().xl)
    // Without an onBack the back control has nowhere to step to, so back closes as it would without it.
    val step: (() -> Unit)? = if (showBack) onBack else null
    FlareOverlayScaffold(
        kind = FlareOverlaySurfaceKind.Drawer,
        onClose = onClose,
        dismissible = dismissible,
        scrim = colors.scrim,
        scrimLabel = if (flareScrimAnnounced(dismissible, showClose)) strings.close else null,
        contentAlignment = if (end) Alignment.CenterEnd else Alignment.CenterStart,
        enter = if (reducedMotion) EnterTransition.None
        else slideInHorizontally(tween(FlareMotion.slow, easing = FlareMotion.slowEasing)) { it * sign },
        exit = if (reducedMotion) ExitTransition.None
        else slideOutHorizontally(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) { it * sign },
        onBack = step,
        // The panel runs under the status bar: its icons must read on the panel's surface.
        lightStatusBars = colors.bgPrimary.luminance() > 0.5f,
        focusKey = showBack to title,
    ) { close, bounds ->
        // Read in the drawer's own dialog window: the bars on the side it docks to, and the keyboard it raises.
        val insets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Vertical + if (end) WindowInsetsSides.End else WindowInsetsSides.Start,
        )
        Column(
            modifier.fillMaxHeight()
                .width(flareDrawerWidth(width, bounds.width))
                .shadow(depth, shape, clip = false)
                .clip(shape)
                .background(colors.bgPrimary)
                // A tap on the panel itself never reaches the scrim behind it.
                .pointerInput(Unit) { detectTapGestures {} }
                .semantics { paneTitle = flareOverlayPaneTitle(title, label, strings.drawerLabel) }
                // Consumed here, so a hosted page does not pad for the bars again.
                .windowInsetsPadding(insets),
        ) {
            if (flareOverlayHeaderVisible(title, titleHidden, actions != null, showClose, showBack)) {
                FlareOverlayHeader(
                    title = title,
                    titleHidden = titleHidden,
                    showBack = showBack,
                    showClose = showClose,
                    enabled = dismissible,
                    onBack = { (step ?: close)() },
                    onClose = close,
                    actions = actions,
                )
            }
            Column(Modifier.fillMaxWidth().weight(1f)) { content() }
            if (footer != null) {
                Box(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg)) { footer() }
            }
        }
    }
}
