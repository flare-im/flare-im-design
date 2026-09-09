package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Screen-share state reported by the host / RTC plugin.
 * Idle — nothing is being shared, the local user may start. Requesting — a share was requested and the
 * system / plugin has not answered yet. Sharing — the local user is sharing. Viewing — someone else is
 * sharing and the local user is watching. Unavailable — the runtime or plugin does not support it.
 */
enum class FlareScreenShareState { Idle, Requesting, Sharing, Viewing, Unavailable }

enum class FlareScreenShareAction { Start, Stop, Cancel }

/** Semantic tone per state; every state also carries an icon and text, never colour alone. */
fun screenShareTone(state: FlareScreenShareState): FlareStatusTone = when (state) {
    FlareScreenShareState.Idle -> FlareStatusTone.Neutral
    FlareScreenShareState.Requesting -> FlareStatusTone.Warning
    FlareScreenShareState.Sharing -> FlareStatusTone.Success
    FlareScreenShareState.Viewing -> FlareStatusTone.Info
    FlareScreenShareState.Unavailable -> FlareStatusTone.Neutral
}

/** Kit icon per state; the same semantic names resolve on Vue / Flutter / iOS. */
fun screenShareIconName(state: FlareScreenShareState): String = when (state) {
    FlareScreenShareState.Idle -> "devices"
    FlareScreenShareState.Requesting -> "refresh"
    FlareScreenShareState.Sharing -> "video"
    FlareScreenShareState.Viewing -> "eye"
    FlareScreenShareState.Unavailable -> "block"
}

/**
 * Which actions are visible, and whether they may be pressed.
 * [start] only while idle, [stop] only while sharing (a viewer can never stop someone else's share),
 * [cancel] only while requesting; [enabled] is false while busy so visible actions keep their place.
 */
data class FlareScreenShareActions(
    val start: Boolean,
    val stop: Boolean,
    val cancel: Boolean,
    val enabled: Boolean,
) {
    operator fun contains(action: FlareScreenShareAction): Boolean = when (action) {
        FlareScreenShareAction.Start -> start
        FlareScreenShareAction.Stop -> stop
        FlareScreenShareAction.Cancel -> cancel
    }

    fun isEmpty(): Boolean = !start && !stop && !cancel

    fun isNotEmpty(): Boolean = !isEmpty()
}

/**
 * Actions the host may currently trigger. Viewing and unavailable never expose one — an unsupported
 * runtime shows the reason instead of a button that would do nothing. Visibility ignores [busy] on
 * purpose so buttons do not disappear mid-command.
 */
fun screenShareActions(
    state: FlareScreenShareState,
    hasStart: Boolean,
    hasStop: Boolean,
    hasCancel: Boolean,
    busy: Boolean = false,
): FlareScreenShareActions = FlareScreenShareActions(
    start = state == FlareScreenShareState.Idle && hasStart,
    stop = state == FlareScreenShareState.Sharing && hasStop,
    cancel = state == FlareScreenShareState.Requesting && hasCancel,
    enabled = !busy,
)

/**
 * Screen-share control and status panel for an ongoing call. Capture, source enumeration and encoding
 * belong to the host / RTC plugin; this view only presents the reported state and dispatches
 * start / stop / cancel intents. Permission denial is NOT handled here: the host renders
 * `PermissionPrompt(kind = FlarePermissionKind.Screen, state = FlarePermissionState.Denied)` instead,
 * so one intent keeps exactly one path. Spec: Call/ScreenShare (`ScreenShare`).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ScreenShare(
    state: FlareScreenShareState,
    sourceLabel: String? = null,
    presenterName: String? = null,
    detail: String? = null,
    busy: Boolean = false,
    title: String = "屏幕共享",
    idleText: String = "未在共享",
    requestingText: String = "正在请求共享",
    sharingText: String = "正在共享屏幕",
    viewingText: String = "正在观看共享",
    unavailableText: String = "当前环境不支持屏幕共享",
    sourceRowLabel: String = "共享内容",
    presenterRowLabel: String = "共享者",
    startText: String = "共享屏幕",
    stopText: String = "停止共享",
    cancelText: String = "取消请求",
    onStart: (() -> Unit)? = null,
    onStop: (() -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val tone = statusToneColor(colors, screenShareTone(state))
    val active = state == FlareScreenShareState.Sharing
    val stateText = when (state) {
        FlareScreenShareState.Idle -> idleText
        FlareScreenShareState.Requesting -> requestingText
        FlareScreenShareState.Sharing -> sharingText
        FlareScreenShareState.Viewing -> viewingText
        FlareScreenShareState.Unavailable -> unavailableText
    }
    // Visibility ignores busy (buttons stay in place); busy only disables them.
    val actions = screenShareActions(
        state,
        hasStart = onStart != null,
        hasStop = onStop != null,
        hasCancel = onCancel != null,
        busy = false,
    )
    val source = if (state == FlareScreenShareState.Sharing) sourceLabel?.trim().orEmpty() else ""
    val presenter = if (state == FlareScreenShareState.Viewing) presenterName?.trim().orEmpty() else ""
    val detailText = detail?.trim().orEmpty()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl))
            .padding(FlareSizes.spacingLg)
            .semantics { contentDescription = title },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl.value.sp, fontWeight = FontWeight.SemiBold)

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(tone.copy(alpha = if (active) 0.16f else 0.10f))
                .border(1.dp, tone.copy(alpha = if (active) 0.44f else 0.24f), RoundedCornerShape(FlareSizes.radiusLg))
                .padding(FlareSizes.spacingMd)
                .semantics { liveRegion = LiveRegionMode.Polite },
            verticalAlignment = Alignment.Top,
        ) {
            FlareIcon(screenShareIconName(state), size = 20.dp, tint = tone)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(stateText, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
                if (detailText.isNotEmpty()) {
                    Text(detailText, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
            }
        }

        if (state == FlareScreenShareState.Requesting) {
            LinearProgressIndicator(
                modifier = Modifier.fillMaxWidth().semantics { contentDescription = requestingText },
                color = tone,
                trackColor = colors.bgSecondary,
            )
        }

        if (source.isNotEmpty() || presenter.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                if (source.isNotEmpty()) ScreenShareMetaRow(sourceRowLabel, source, colors)
                if (presenter.isNotEmpty()) ScreenShareMetaRow(presenterRowLabel, presenter, colors)
            }
        }

        if (actions.isNotEmpty()) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                if (FlareScreenShareAction.Start in actions) {
                    Button(
                        onClick = { onStart?.invoke() },
                        enabled = !busy,
                        shape = RoundedCornerShape(FlareSizes.radiusMd),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = colors.primary,
                            contentColor = Color.White,
                            disabledContainerColor = colors.bgDisabled,
                            disabledContentColor = colors.textDisabled,
                        ),
                        modifier = Modifier.defaultMinSize(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget),
                    ) {
                        FlareIcon("devices", size = 16.dp, tint = if (busy) colors.textDisabled else Color.White)
                        Spacer(Modifier.width(FlareSizes.spacingXs))
                        Text(startText, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
                if (FlareScreenShareAction.Stop in actions) {
                    OutlinedButton(
                        onClick = { onStop?.invoke() },
                        enabled = !busy,
                        shape = RoundedCornerShape(FlareSizes.radiusMd),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = colors.error,
                            disabledContentColor = colors.textDisabled,
                        ),
                        modifier = Modifier.defaultMinSize(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget),
                    ) {
                        FlareIcon("block", size = 16.dp, tint = if (busy) colors.textDisabled else colors.error)
                        Spacer(Modifier.width(FlareSizes.spacingXs))
                        Text(stopText, fontSize = FlareSizes.fontSizeLg.value.sp)
                    }
                }
                if (FlareScreenShareAction.Cancel in actions) {
                    OutlinedButton(
                        onClick = { onCancel?.invoke() },
                        enabled = !busy,
                        shape = RoundedCornerShape(FlareSizes.radiusMd),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = colors.textPrimary,
                            disabledContentColor = colors.textDisabled,
                        ),
                        modifier = Modifier.defaultMinSize(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget),
                    ) {
                        Text(cancelText, fontSize = FlareSizes.fontSizeLg.value.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun ScreenShareMetaRow(label: String, value: String, colors: FlareColors) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
        Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp, modifier = Modifier.width(88.dp))
        Text(value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp, modifier = Modifier.weight(1f))
    }
}
