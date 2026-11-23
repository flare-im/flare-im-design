package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.offset
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset

/** The window a call takes (3.1): its width and height, or null for the whole screen (a phone). */
internal fun callSurfaceSize(mode: FlareCallMode, compact: Boolean, expanded: Boolean, maxWidth: Dp, maxHeight: Dp): Pair<Dp, Dp>? = when {
    compact -> null
    expanded -> (maxWidth - FlareSizes.spacingXl * 2) to (maxHeight * 0.9f)
    mode == FlareCallMode.Audio -> FlareSizes.componentCallWindowAudioWidth to FlareSizes.componentCallWindowAudioHeight
    else -> FlareSizes.componentCallWindowVideoWidth to FlareSizes.componentCallWindowVideoHeight
}.let { size -> size?.let { (w, h) -> minOf(w, maxWidth) to minOf(h, maxHeight) } }

/**
 * Call surface — the window that carries a call view ([CallView], [GroupCallView]). Spec: Call/CallSurface
 * (`CallSurface`), 3.1 of docs/plugin-experience.md. On a phone ([flareCompactOverlays]) it is the true full screen: no
 * scrim edge, no corners, the stage under the status and navigation bars. On a tablet window it floats in the middle:
 * audio `component.callWindowAudioWidth` × `callWindowAudioHeight`, video `callWindowVideoWidth` ×
 * `callWindowVideoHeight`, [expanded] the window less `spacing.xl` a side and 90% high; `radius.xl` and a large
 * shadow (`shadows.xl`; none in full screen); it is dragged by its top 48 (the title area) and stays inside the
 * screen. [label] is the window's accessible name. A window offers expand / collapse at its top end
 * ([onExpandedChange]); back (Esc) only leaves the expanded window — it never minimizes or hangs up. [onMinimize] (the
 * contract's `minimize`) draws the collapse key at the top start, on the expand key's row in a window, under the status
 * bar in full screen; pass it here or to the call view inside, not both.
 */
@Composable
fun CallSurface(
    mode: FlareCallMode,
    modifier: Modifier = Modifier,
    expanded: Boolean = false,
    label: String? = null,
    onExpandedChange: ((Boolean) -> Unit)? = null,
    onMinimize: (() -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    val compact = flareCompactOverlays()
    val strings = flareStrings()
    FlareNativeBackEffect(enabled = !compact && expanded && onExpandedChange != null) { onExpandedChange?.invoke(false) }
    BoxWithConstraints(modifier.fillMaxSize().semantics { label?.let { paneTitle = it } }, contentAlignment = Alignment.Center) {
        val size = callSurfaceSize(mode, compact, expanded, maxWidth, maxHeight)
        if (size == null) {
            Box(Modifier.fillMaxSize()) {
                content()
                if (onMinimize != null) CallMinimizeKey(onMinimize, Modifier.align(Alignment.TopStart).statusBarsPadding()
                    .padding(start = FlareSizes.spacing2sm, top = FlareSizes.spacing2sm))
            }
        } else {
            val shape = RoundedCornerShape(FlareSizes.radiusXl)
            val density = LocalDensity.current
            var offset by remember(expanded) { mutableStateOf(Offset.Zero) }
            var grabbed by remember { mutableStateOf(false) }
            // The window may move until its edge meets the screen's; it never leaves it.
            val limitX = with(density) { ((maxWidth - size.first) / 2).toPx() }.coerceAtLeast(0f)
            val limitY = with(density) { ((maxHeight - size.second) / 2).toPx() }.coerceAtLeast(0f)
            Box(
                Modifier.offset { IntOffset(offset.x.toInt(), offset.y.toInt()) }
                    .size(size.first, size.second).shadow(flareShadowElevation(flareShadows().xl), shape, clip = false).clip(shape)
                    .pointerInput(expanded) {
                        detectDragGestures(
                            onDragStart = { start -> grabbed = !expanded && start.y <= FlareSizes.touchTarget.toPx() },
                            onDragEnd = { grabbed = false },
                            onDragCancel = { grabbed = false },
                        ) { change, amount ->
                            if (!grabbed) return@detectDragGestures
                            change.consume()
                            offset = Offset((offset.x + amount.x).coerceIn(-limitX, limitX), (offset.y + amount.y).coerceIn(-limitY, limitY))
                        }
                    },
            ) {
                content()
                // 3.1: minimize at the start and expand at the end of the title area's one row.
                if (onMinimize != null) CallMinimizeKey(onMinimize, Modifier.align(Alignment.TopStart).padding(FlareSizes.spacingXs))
                // 3.1: a window expands to the screen less spacing.xl a side, and back.
                if (onExpandedChange != null) CallRoundKey(
                    label = if (expanded) strings.collapse else strings.expand, icon = if (expanded) "collapse" else "expand",
                    size = callSmallKeySize, fill = flareColors().callControl, pressed = flareColors().callControlHover,
                    iconSize = FlareSizes.iconSizeMd, onClick = { onExpandedChange(!expanded) },
                    modifier = Modifier.align(Alignment.TopEnd).padding(FlareSizes.spacingXs),
                )
            }
        }
    }
}
