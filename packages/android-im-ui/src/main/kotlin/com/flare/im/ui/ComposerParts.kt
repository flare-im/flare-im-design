package com.flare.im.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Hold-to-talk voice button (语音) — a composable composer part. Press and hold
 * to record, release to send; the host owns recording via the callbacks.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun FlareVoiceHoldButton(
    label: String? = null,
    recordingLabel: String? = null,
    cancelLabel: String? = null,
    cancelThreshold: Float = 80f,
    onStart: (() -> Unit)? = null,
    onEnd: (() -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val label = label ?: strings.voiceHoldButtonLabel
    val recordingLabel = recordingLabel ?: strings.voiceHoldButtonRecording
    val cancelLabel = cancelLabel ?: strings.voiceHoldButtonCancel
    val colors = flareColors()
    var pressing by remember { mutableStateOf(false) }
    var willCancel by remember { mutableStateOf(false) }
    val haptics = LocalHapticFeedback.current
    val bg = if (!pressing) colors.bgSecondary else if (willCancel) colors.error else colors.primary
    Box(
        Modifier.fillMaxWidth().height(FlareSizes.componentComposerActionHeight)
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(bg)
            .pointerInput(cancelThreshold) {
                val cancelPx = cancelThreshold * density
                awaitEachGesture {
                    val down = awaitFirstDown()
                    pressing = true
                    willCancel = false
                    onStart?.invoke()
                    var cancelled = false
                    while (true) {
                        val event = awaitPointerEvent()
                        val change = event.changes.firstOrNull { it.id == down.id } ?: break
                        // Sliding up past the threshold from the press origin arms cancel.
                        val c = (change.position.y - down.position.y) < -cancelPx
                        // Sliding past the line changes what letting go means, so it is felt as well as seen.
                        if (flareHapticCrossed(willCancel, c)) haptics.flareHapticTick()
                        if (c != willCancel) willCancel = c
                        cancelled = c
                        if (!change.pressed) break
                    }
                    pressing = false
                    willCancel = false
                    if (cancelled) onCancel?.invoke() else onEnd?.invoke()
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        Text(
            if (!pressing) label else if (willCancel) cancelLabel else recordingLabel,
            color = if (pressing) Color.White else colors.textSecondary,
            fontSize = FlareSizes.fontSizeLg.value.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}

/** How [FlareComposerActionPanel] lays out: a phone pages the grid sideways, a desktop shows at most `rows` rows and scrolls the rest. */
enum class FlareComposerPanelFormFactor { Mobile, Desktop }

/** Height of one row of "+" tiles. */
val FlareComposerPanelRowHeight = 76.dp

/** The pages of a "+" grid on a phone: [rows] × [columns] tiles each, in order. */
fun <T> composerPanelPages(actions: List<T>, rows: Int, columns: Int): List<List<T>> = actions.chunked(rows * columns)

/** The page a reader stays on when the list changes: the same one, clamped when pages go away. */
fun composerPanelPage(current: Int, pages: Int): Int = current.coerceIn(0, (pages - 1).coerceAtLeast(0))

/**
 * The composer's bottom function area (下方功能区) — an inline grid of attachment
 * actions. Composable part; wrap in `AnimatedVisibility` to expand under the
 * input, or use standalone. Shares [FlareComposerAction] with the action sheet.
 *
 * Items are ordered by `order`, then by position. On a phone ([formFactor] Mobile) the grid pages sideways,
 * [rows] × [columns] per page, with page dots; on a desktop it shows at most [rows] rows and scrolls. A new list keeps
 * the page the reader is on (clamped when pages go away); a tile that appears fades in (150 ms, none with reduced
 * motion).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun FlareComposerActionPanel(
    actions: List<FlareComposerAction>? = null,
    capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
    columns: Int = 4,
    formFactor: FlareComposerPanelFormFactor = FlareComposerPanelFormFactor.Mobile,
    /** Rows per page on a phone (default 2), most rows shown on a desktop (default 3). */
    rows: Int? = null,
    onAction: ((FlareComposerAction) -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    val resolvedActions = resolveComposerActions(defaultComposerActions(), capabilities, actions)
    val paged = formFactor == FlareComposerPanelFormFactor.Mobile
    val rowCount = (rows ?: if (paged) 2 else 3).coerceAtLeast(1)
    val gridHeight = FlareComposerPanelRowHeight * rowCount + FlareSizes.spacingLg * (rowCount - 1)
    // Ids drawn so far: a tile not among them fades in. The first frame draws without a fade.
    val seen = remember { mutableSetOf<String>() }
    val drawn = remember { booleanArrayOf(false) }
    val fresh = if (drawn[0]) resolvedActions.map { it.id }.filterNot { it in seen }.toSet() else emptySet()
    SideEffect {
        seen.clear()
        seen.addAll(resolvedActions.map { it.id })
        drawn[0] = true
    }
    @Composable
    fun tile(action: FlareComposerAction, modifier: Modifier) {
        val label = action.resolvedLabel(strings)
        val shown = remember { MutableTransitionState(action.id !in fresh || reducedMotion).apply { targetState = true } }
        AnimatedVisibility(shown, modifier, enter = fadeIn(tween(FlareMotion.fast)), exit = ExitTransition.None) {
            Column(
                Modifier.height(FlareComposerPanelRowHeight).flareDimmed(if (action.enabled) 1f else FlareOpacity.disabled)
                    .clickable(enabled = action.enabled) { onAction?.invoke(action) },
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(
                    Modifier.size(FlareSizes.componentComposerActionWidth).clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(Color.Transparent),
                    contentAlignment = Alignment.Center,
                ) { FlareIcon(name = action.resolvedIcon, size = 20.dp, tint = colors.textPrimary, contentDescription = action.accessibilityLabel ?: label) }
                Spacer(Modifier.size(FlareSizes.spacingXs))
                Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeXs.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
    @Composable
    fun grid(items: List<FlareComposerAction>) {
        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
            items.chunked(columns).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
                    row.forEach { action -> key(action.id) { tile(action, Modifier.weight(1f)) } }
                    repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
    }
    Column(Modifier.fillMaxWidth().background(colors.bgPrimary).padding(FlareSizes.spacingLg)) {
        if (paged) {
            val pages = composerPanelPages(resolvedActions, rowCount, columns)
            val pager = rememberPagerState { pages.size }
            HorizontalPager(pager, Modifier.fillMaxWidth().height(gridHeight), verticalAlignment = Alignment.Top) { index ->
                grid(pages.getOrElse(index) { emptyList() })
            }
            if (pages.size > 1) {
                val current = composerPanelPage(pager.currentPage, pages.size)
                // The pager carries paging for TalkBack; the dots only show where the reader is.
                Row(
                    Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm).clearAndSetSemantics {},
                    horizontalArrangement = Arrangement.Center,
                ) {
                    repeat(pages.size) { index ->
                        val width by animateDpAsState(if (index == current) 12.dp else 5.dp, tween(if (reducedMotion) 0 else FlareMotion.fast), label = "dot")
                        Box(
                            Modifier.padding(horizontal = FlareSizes.spacing3xs).size(width, 5.dp).clip(RoundedCornerShape(FlareSizes.radiusFull))
                                .background(if (index == current) colors.primary else colors.borderPrimary),
                        )
                    }
                }
            }
        } else {
            Box(Modifier.fillMaxWidth().heightIn(max = gridHeight).verticalScroll(rememberScrollState())) { grid(resolvedActions) }
        }
    }
}

/**
 * Send button (发送) — a composable composer part. Theme primary when active,
 * disabled otherwise; fires onSend only when active.
 */
/**
 * Send — a paper plane, and nothing else.
 *
 * It used to be a filled brand disc with a white glyph inside. Sending is the
 * same kind of act as every other key in the tool row — one tap, one outcome —
 * so it is drawn the same way, and only colour says which one sends: the brand
 * at rest against the row, faded while there is nothing to send. That is also
 * what [Composer]'s own send key does, and the two must not drift.
 */
@Composable
fun FlareComposerSendButton(active: Boolean, onSend: (() -> Unit)? = null) {
    val colors = flareColors()
    Box(
        Modifier.size(FlareSizes.componentComposerActionWidth).clickable(enabled = active) { onSend?.invoke() },
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.AutoMirrored.Filled.Send, flareStrings().send, Modifier.size(20.dp),
            tint = colors.primaryText.copy(alpha = if (active) 1f else 0.38f),
        )
    }
}

/**
 * Reply strip (回复条) — a composable composer part shown above the input when
 * replying. Left brand rail + sender / summary + cancel.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun FlareComposerReplyStrip(
    senderName: String,
    summary: String,
    label: String? = null,
    onCancel: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val label = label ?: strings.composerReplyStripLabel
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.messageReplyBackground),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(3.dp).height(36.dp).background(colors.messageReplyBorder))
        Column(
            Modifier.weight(1f).padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
        ) {
            Text(
                "$label $senderName", color = colors.primaryText,
                fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold,
            )
            Text(summary, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1)
        }
        Box(
            Modifier.padding(end = FlareSizes.spacingSm).size(18.dp).clickable { onCancel?.invoke() },
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Rounded.Close, flareStrings().cancelReply, Modifier.size(18.dp), tint = colors.textTertiary) }
    }
}
