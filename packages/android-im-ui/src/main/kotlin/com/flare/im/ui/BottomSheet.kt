package com.flare.im.ui

import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * How a [BottomSheet] appears. [Auto] is a bottom sheet on the phone form factor ([flareCompactOverlays]) and
 * otherwise hands the content to [Modal] as a centered box; [Sheet] is always a bottom sheet. A centered box on
 * every form factor is [Modal] itself, and a side panel is [Drawer].
 */
enum class FlareSheetPresentation { Auto, Sheet }

/**
 * Bottom sheet — the kit surface for short, focused tasks: pickers, forms, confirms, prompts and sheet content
 * such as [MessageActionSheet] or [MomentAudienceSheet]. Spec: General/BottomSheet (`BottomSheet`).
 *
 * Composing it shows it; the host removes it in [onClose]. [presentation] is resolved once, when the sheet
 * opens, and kept until it closes (rotating across the breakpoint does not swap the window and lose the
 * content's state). As a sheet it opens a full-display dialog window with the token scrim (`colors.scrim`, the
 * platform dim is off) and a bottom-aligned surface carrying the top radius, a drag handle, the optional
 * [title] (the accessible name; drawn unless [titleHidden]) and the navigation-bar and keyboard insets. Off the
 * phone form factor ([FlareSheetPresentation.Auto]) the same content is shown by [Modal], with the title leading
 * its header and no close button — the scrim, back and Escape close it as they close the sheet.
 *
 * The surface is at most [maxHeight] tall (default 72% of the window after the keyboard and the safe area) and
 * gives [content] bounded constraints; [content] owns its scrolling (a lazy list, or a
 * `Column(Modifier.weight(1f, fill = false).verticalScroll(…))` for a long static body) — the sheet never wraps
 * it in a scroll container. While [dismissible], system back, Escape and a tap on the scrim slide the sheet out
 * and then call [onClose] (immediately under reduced motion); a host that removes the sheet itself closes it
 * without the slide.
 */
@Composable
fun BottomSheet(
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    titleHidden: Boolean = false,
    maxHeight: Dp? = null,
    dismissible: Boolean = true,
    presentation: FlareSheetPresentation = FlareSheetPresentation.Auto,
    content: @Composable ColumnScope.() -> Unit,
) {
    val strings = flareStrings()
    val compact = flareCompactOverlays()
    // Resolved once for the life of this sheet.
    val resolved = remember { resolveOverlayPresentation(presentation, compact) }
    if (resolved == FlareResolvedOverlay.Modal) {
        FlareModalLayer(
            onClose = onClose,
            modifier = modifier,
            title = title,
            titleHidden = titleHidden,
            label = null,
            fallbackLabel = strings.bottomSheetLabel,
            width = FlareSizes.componentSheetDialogWidth,
            maxHeight = maxHeight,
            fill = false,
            dismissible = dismissible,
            showClose = false,
            busy = false,
            // Sheet content owns its scrolling; the box only bounds it.
            scrollable = false,
            actions = null,
            footer = null,
            bodyPadding = PaddingValues(bottom = FlareSizes.spacingSm),
            content = content,
        )
        return
    }

    val colors = flareColors()
    val reducedMotion = flareReducedMotion()
    FlareOverlayScaffold(
        kind = FlareOverlaySurfaceKind.Sheet,
        onClose = onClose,
        dismissible = dismissible,
        scrim = colors.scrim,
        // A sheet has no close button: the scrim is its close control.
        scrimLabel = if (flareScrimAnnounced(dismissible, showClose = false)) strings.close else null,
        contentAlignment = Alignment.BottomCenter,
        enter = if (reducedMotion) EnterTransition.None
        else slideInVertically(tween(FlareMotion.slow, easing = FlareMotion.slowEasing)) { it },
        exit = if (reducedMotion) ExitTransition.None
        else slideOutVertically(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) { it },
    ) { _, bounds ->
        // Read in the sheet's own dialog window, whose insets include the keyboard it raises.
        val density = LocalDensity.current
        val safeDrawing = WindowInsets.safeDrawing
        val top = with(density) { safeDrawing.getTop(this).toDp() }
        val bottom = with(density) { safeDrawing.getBottom(this).toDp() }
        val usable = (bounds.height - top - bottom).coerceAtLeast(0.dp)
        // Never up to the status bar: a header's height of scrim stays above the tallest sheet.
        val cap = flareOverlayMaxHeight(maxHeight, available = usable, ceiling = usable - FlareSizes.headerHeight)
        Column(
            // The web sheet's 640 cap, which the bubble width token carries.
            modifier.fillMaxWidth().widthIn(max = FlareSizes.bubbleMaxWidth)
                // The surface runs under the navigation bar / keyboard, so its cap includes that inset.
                .heightIn(max = cap + bottom)
                .clip(RoundedCornerShape(topStart = FlareSizes.radius2xl, topEnd = FlareSizes.radius2xl))
                .background(colors.bgPrimary)
                // A tap on the sheet itself never reaches the scrim behind it.
                .pointerInput(Unit) { detectTapGestures {} }
                .semantics { paneTitle = title?.takeIf { it.isNotBlank() } ?: strings.bottomSheetLabel }
                .navigationBarsPadding()
                .imePadding(),
        ) {
            Box(
                Modifier.align(Alignment.CenterHorizontally)
                    .padding(top = FlareSizes.spacingSm, bottom = FlareSizes.spacingXs)
                    .size(width = FlareSizes.iconSizeXl, height = FlareSizes.spacingXs)
                    .clip(RoundedCornerShape(FlareSizes.radiusFull))
                    .background(colors.borderPrimary),
            )
            if (title != null && !titleHidden) {
                Text(
                    title,
                    color = colors.textTertiary,
                    fontSize = FlareSizes.fontSizeMd.value.sp,
                    fontWeight = FontWeight.Medium,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                        .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs)
                        .semantics { heading() },
                )
            }
            // Bounded: whatever the handle and title leave of the cap.
            Column(Modifier.fillMaxWidth().weight(1f, fill = false)) { content() }
        }
    }
}
