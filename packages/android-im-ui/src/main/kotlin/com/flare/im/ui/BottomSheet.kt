package com.flare.im.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.traversalIndex
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

/** True inside [BottomSheet]: kit sheet content draws on the sheet's surface rather than its own. */
internal val LocalFlareBottomSheet = staticCompositionLocalOf { false }

/**
 * Modal bottom sheet — the kit presenter for sheet content such as [MessageActionSheet],
 * [MomentAudienceSheet] or a short form. Spec: General/BottomSheet (`BottomSheet`).
 *
 * Composing it shows it; the host removes it in [onClose]. It opens a dialog window: the
 * window's dim is the scrim, and a bottom-aligned surface carries the top radius, a drag
 * handle, the optional [title] and the navigation-bar and keyboard insets. While
 * [dismissible], system back and a tap on the scrim slide the sheet out and then call
 * [onClose] (immediately under reduced motion); a host that removes the sheet itself
 * closes it without the slide. [content] owns its scrolling.
 */
@Composable
fun BottomSheet(
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    dismissible: Boolean = true,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    val currentOnClose by rememberUpdatedState(onClose)
    val shown = remember { MutableTransitionState(reducedMotion) }
    var closing by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { shown.targetState = true }
    val close: () -> Unit = {
        if (dismissible && !closing) {
            if (reducedMotion) currentOnClose() else { closing = true; shown.targetState = false }
        }
    }
    val currentClose by rememberUpdatedState(close)
    if (closing && shown.isIdle && !shown.currentState) {
        LaunchedEffect(Unit) {
            currentOnClose()
            // Still composed after onClose: the host kept the sheet, so it comes back.
            closing = false
            shown.targetState = true
        }
    }
    Dialog(
        onDismissRequest = close,
        properties = DialogProperties(
            dismissOnBackPress = dismissible,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false,
        ),
    ) {
        // The dialog window takes the whole display; the insets below keep the sheet's content clear of
        // the bars and the keyboard.
        FlareEdgeToEdgeDialogWindow()
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) {
            if (dismissible) {
                // Outside the sheet: the window dim shows through, this layer only takes the tap.
                Box(
                    Modifier.fillMaxSize()
                        .pointerInput(Unit) { detectTapGestures { currentClose() } }
                        .semantics {
                            contentDescription = strings.close
                            traversalIndex = 1f
                            onClick { currentClose(); true }
                        },
                )
            }
            AnimatedVisibility(
                visibleState = shown,
                modifier = Modifier.windowInsetsPadding(WindowInsets.statusBars).padding(top = FlareSizes.headerHeight),
                enter = if (reducedMotion) EnterTransition.None
                else slideInVertically(tween(FlareMotion.slow, easing = FlareMotion.slowEasing)) { it },
                exit = if (reducedMotion) ExitTransition.None
                else slideOutVertically(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) { it },
            ) {
                Column(
                    // The web sheet's 640 cap, which the bubble width token carries.
                    modifier.fillMaxWidth().widthIn(max = FlareSizes.bubbleMaxWidth)
                        .clip(RoundedCornerShape(topStart = FlareSizes.radius2xl, topEnd = FlareSizes.radius2xl))
                        .background(colors.bgPrimary)
                        // A tap on the sheet itself never reaches the scrim behind it.
                        .pointerInput(Unit) { detectTapGestures {} }
                        .semantics { paneTitle = title ?: strings.bottomSheetLabel }
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
                    if (title != null) {
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
                    CompositionLocalProvider(LocalFlareBottomSheet provides true) { content() }
                }
            }
        }
    }
}
