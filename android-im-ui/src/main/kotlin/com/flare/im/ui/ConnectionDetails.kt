package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalLayoutDirection

/** Connection / session state supplied by the host; the UI never opens or closes a connection. */
enum class FlareConnectionState { Connected, Connecting, Reconnecting, Offline, SessionExpired, Kicked, SdkUnready }

enum class FlareConnectionAction { Reconnect, Reauth, CopyDiagnostics }

/** Semantic tone per state; every state also carries an icon and text, never colour alone. */
fun connectionTone(state: FlareConnectionState): FlareStatusTone = when (state) {
    FlareConnectionState.Connected -> FlareStatusTone.Success
    FlareConnectionState.Connecting, FlareConnectionState.Reconnecting -> FlareStatusTone.Warning
    FlareConnectionState.Offline, FlareConnectionState.SessionExpired, FlareConnectionState.Kicked -> FlareStatusTone.Danger
    FlareConnectionState.SdkUnready -> FlareStatusTone.Neutral
}

/** States that show an indeterminate progress indicator. */
fun connectionInProgress(state: FlareConnectionState): Boolean =
    state == FlareConnectionState.Connecting || state == FlareConnectionState.Reconnecting

/**
 * Actions the host may currently trigger. Reconnect only while offline/reconnecting, reauth only after
 * sessionExpired/kicked, copyDiagnostics only with non-blank diagnostics. SdkUnready never exposes an
 * action; busy disables everything.
 */
fun availableConnectionActions(
    state: FlareConnectionState,
    hasReconnect: Boolean,
    hasReauth: Boolean,
    hasDiagnostics: Boolean,
    busy: Boolean,
): List<FlareConnectionAction> {
    if (busy || state == FlareConnectionState.SdkUnready) return emptyList()
    val actions = mutableListOf<FlareConnectionAction>()
    if (hasReconnect && (state == FlareConnectionState.Offline || state == FlareConnectionState.Reconnecting)) {
        actions += FlareConnectionAction.Reconnect
    }
    if (hasReauth && (state == FlareConnectionState.SessionExpired || state == FlareConnectionState.Kicked)) {
        actions += FlareConnectionAction.Reauth
    }
    if (hasDiagnostics) actions += FlareConnectionAction.CopyDiagnostics
    return actions
}

/**
 * Connection / session details panel — opened from a StatusBanner or shown on the "network & connection"
 * settings page. The host owns the state; this view only presents it and dispatches
 * reconnect / reauth / copyDiagnostics. Spec: General/ConnectionDetails (`ConnectionDetails`).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ConnectionDetails(
    state: FlareConnectionState,
    transport: String? = null,
    endpoint: String? = null,
    lastSyncAt: String? = null,
    reason: String? = null,
    diagnostics: String? = null,
    busy: Boolean = false,
    title: String = "连接详情",
    connectedText: String = "已连接",
    connectingText: String = "正在连接",
    reconnectingText: String = "正在重新连接",
    offlineText: String = "离线",
    sessionExpiredText: String = "登录已过期",
    kickedText: String = "已在其他设备登录",
    sdkUnreadyText: String = "客户端尚未就绪",
    transportLabel: String = "传输协议",
    endpointLabel: String = "服务地址",
    lastSyncLabel: String = "上次同步",
    diagnosticsLabel: String = "诊断信息",
    reconnectText: String = "重新连接",
    reauthText: String = "重新登录",
    copyDiagnosticsText: String = "复制诊断信息",
    onReconnect: (() -> Unit)? = null,
    onReauth: (() -> Unit)? = null,
    onCopyDiagnostics: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val tone = statusToneColor(colors, connectionTone(state))
    val stateText = when (state) {
        FlareConnectionState.Connected -> connectedText
        FlareConnectionState.Connecting -> connectingText
        FlareConnectionState.Reconnecting -> reconnectingText
        FlareConnectionState.Offline -> offlineText
        FlareConnectionState.SessionExpired -> sessionExpiredText
        FlareConnectionState.Kicked -> kickedText
        FlareConnectionState.SdkUnready -> sdkUnreadyText
    }
    val stateIcon = when (state) {
        FlareConnectionState.Connected -> "success"
        FlareConnectionState.Connecting, FlareConnectionState.Reconnecting -> "refresh"
        FlareConnectionState.Offline -> "error"
        FlareConnectionState.SessionExpired -> "lock"
        FlareConnectionState.Kicked -> "devices"
        FlareConnectionState.SdkUnready -> "info"
    }
    val hasDiagnostics = !diagnostics.isNullOrBlank()
    // Visibility ignores busy (buttons stay in place); busy only disables them.
    val visible = availableConnectionActions(
        state,
        hasReconnect = onReconnect != null,
        hasReauth = onReauth != null,
        hasDiagnostics = hasDiagnostics && onCopyDiagnostics != null,
        busy = false,
    )
    var diagnosticsOpen by rememberSaveable { mutableStateOf(false) }

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
                .background(tone.copy(alpha = 0.10f))
                .border(1.dp, tone.copy(alpha = 0.24f), RoundedCornerShape(FlareSizes.radiusLg))
                .padding(FlareSizes.spacingMd)
                .semantics { liveRegion = LiveRegionMode.Polite },
            verticalAlignment = Alignment.Top,
        ) {
            FlareIcon(stateIcon, size = 20.dp, tint = tone)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(stateText, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
                if (!reason.isNullOrEmpty()) {
                    Text(reason, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
            }
        }

        if (connectionInProgress(state)) {
            LinearProgressIndicator(
                modifier = Modifier.fillMaxWidth().semantics { contentDescription = stateText },
                color = tone,
                trackColor = colors.bgSecondary,
            )
        }

        if (transport != null || endpoint != null || lastSyncAt != null) {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                if (transport != null) MetaRow(transportLabel, transport, colors)
                if (endpoint != null) MetaRow(endpointLabel, endpoint, colors, ellipsis = true)
                if (lastSyncAt != null) MetaRow(lastSyncLabel, lastSyncAt, colors)
            }
        }

        if (visible.isNotEmpty()) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                if (FlareConnectionAction.Reconnect in visible) {
                    PrimaryButton(reconnectText, busy, colors) { onReconnect?.invoke() }
                }
                if (FlareConnectionAction.Reauth in visible) {
                    PrimaryButton(reauthText, busy, colors) { onReauth?.invoke() }
                }
                if (FlareConnectionAction.CopyDiagnostics in visible) {
                    OutlinedButton(
                        onClick = { onCopyDiagnostics?.invoke() },
                        enabled = !busy,
                        shape = RoundedCornerShape(FlareSizes.radiusMd),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.textPrimary, disabledContentColor = colors.textDisabled),
                        modifier = Modifier.defaultMinSize(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget),
                    ) {
                        FlareIcon("copy", size = 16.dp, tint = if (busy) colors.textDisabled else colors.textPrimary)
                        Spacer(Modifier.width(FlareSizes.spacingXs))
                        Text(copyDiagnosticsText, fontSize = FlareSizes.fontSizeLg.value.sp)
                    }
                }
            }
        }

        if (hasDiagnostics) {
            TextButton(
                onClick = { diagnosticsOpen = !diagnosticsOpen },
                modifier = Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget),
                colors = ButtonDefaults.textButtonColors(contentColor = colors.textSecondary),
            ) {
                Box(Modifier.rotate(if (diagnosticsOpen) 90f else 0f)) {
                    FlareIcon("forward", size = 14.dp, tint = colors.textSecondary)
                }
                Spacer(Modifier.width(FlareSizes.spacingXs))
                Text(diagnosticsLabel, fontSize = FlareSizes.fontSizeMd.value.sp)
            }
            if (diagnosticsOpen) {
                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .heightIn(max = 240.dp)
                            .clip(RoundedCornerShape(FlareSizes.radiusMd))
                            .background(colors.bgSecondary)
                            .padding(FlareSizes.spacingMd)
                            .verticalScroll(rememberScrollState()),
                    ) {
                        Text(
                            diagnostics!!,
                            color = colors.textSecondary,
                            fontSize = FlareSizes.fontSizeSm.value.sp,
                            fontFamily = FontFamily.Monospace,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MetaRow(label: String, value: String, colors: FlareColors, ellipsis: Boolean = false) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
        Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp, modifier = Modifier.width(88.dp))
        if (ellipsis) {
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                Text(
                    value,
                    color = colors.textPrimary,
                    fontSize = FlareSizes.fontSizeMd.value.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f).semantics { contentDescription = value },
                )
            }
        } else {
            Text(value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp, modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun PrimaryButton(text: String, busy: Boolean, colors: FlareColors, onClick: () -> Unit) {
    Button(
        onClick = onClick,
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
        Text(text, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
    }
}
