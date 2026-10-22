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
import androidx.compose.foundation.layout.height
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
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
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
 *
 * [fill] is the fixed-height mode: the surface takes its whole cap and [content] fills what the handle and the title
 * leave, owning its scrolling — for pickers with their own header ([LocationPicker], [ContactPicker]), so hosts
 * write no fixed-height wrapper. Content that calls [FlareSheetOwnHeader] then gets no visible title: [title] stays
 * the sheet's accessible name. Without [fill] the declaration changes nothing. Handed to [Modal], it is the modal's
 * fill.
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
    fill: Boolean = false,
    content: @Composable ColumnScope.() -> Unit,
) {
    val strings = flareStrings()
    val compact = flareCompactOverlays()
    // Resolved once for the life of this sheet.
    val resolved = remember { resolveOverlayPresentation(presentation, compact) }
    // What the content declares about itself (its own header); read by the title below.
    val header = remember(fill) { FlareSheetHeaderSlot(fill) }
    val titleShown = flareSheetDrawsTitle(title, titleHidden, fill, header.owned)
    if (resolved == FlareResolvedOverlay.Modal) {
        FlareModalLayer(
            onClose = onClose,
            modifier = modifier,
            title = title,
            titleHidden = !titleShown,
            label = null,
            fallbackLabel = strings.bottomSheetLabel,
            width = FlareSizes.componentSheetDialogWidth,
            maxHeight = maxHeight,
            fill = fill,
            dismissible = dismissible,
            showClose = false,
            busy = false,
            // Sheet content owns its scrolling; the box only bounds it.
            scrollable = false,
            actions = null,
            footer = null,
            bodyPadding = PaddingValues(bottom = FlareSizes.spacingSm),
            content = { CompositionLocalProvider(LocalFlareSheetHeader provides header) { content() } },
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
                // The surface runs under the navigation bar / keyboard, so its cap includes that inset; filled, it
                // takes the whole cap.
                .then(if (fill) Modifier.height(cap + bottom) else Modifier.heightIn(max = cap + bottom))
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
            if (titleShown && title != null) {
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
            // Bounded: whatever the handle and title leave of the cap (all of it when filled).
            Column(Modifier.fillMaxWidth().weight(1f, fill = fill)) {
                CompositionLocalProvider(LocalFlareSheetHeader provides header) { content() }
            }
        }
    }
}

/** Whether a sheet draws its title: a title, not hidden, and not a filled sheet whose content brings its own header. */
internal fun flareSheetDrawsTitle(title: String?, titleHidden: Boolean, fill: Boolean, ownHeader: Boolean): Boolean =
    !title.isNullOrEmpty() && !titleHidden && !(fill && ownHeader)

/** What the content of one [BottomSheet] declares to it: how many parts of it draw their own header row. */
@Stable
internal class FlareSheetHeaderSlot(val fill: Boolean) {
    var owners by mutableIntStateOf(0)
    val owned: Boolean get() = owners > 0
}

/** The enclosing kit sheet's slot; null outside a [BottomSheet]. */
internal val LocalFlareSheetHeader = staticCompositionLocalOf<FlareSheetHeaderSlot?> { null }

/** Whether the enclosing kit sheet is in its fill mode (the content then fills the height it is given). */
@Composable
internal fun flareSheetFills(): Boolean = LocalFlareSheetHeader.current?.fill == true

/**
 * Declares that the content of the enclosing kit [BottomSheet] draws its own header row (a title with Cancel), as
 * [LocationPicker] and [ContactPicker] do. With the sheet's `fill` it then draws no visible title and keeps its title
 * as the accessible name only, so the two never repeat each other; without `fill`, or outside a sheet, it changes
 * nothing. Call it once from the content's composition; leaving the composition withdraws it. Spec:
 * Overlay/BottomSheet.
 */
@Composable
fun FlareSheetOwnHeader() {
    val slot = LocalFlareSheetHeader.current ?: return
    DisposableEffect(slot) {
        slot.owners += 1
        onDispose { slot.owners -= 1 }
    }
}
