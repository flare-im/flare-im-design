package com.flare.im.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Which system permission the prompt explains. Spec: General/PermissionPrompt. */
enum class FlarePermissionKind { Microphone, Camera, Notifications, Storage, Photos, Contacts, Location, Screen }

/** Host-reported permission state; the composable never queries the platform. */
enum class FlarePermissionState { Undetermined, Denied, Restricted, Unavailable }

/**
 * Action visibility computed from state + which callbacks the host supplied.
 * [request] only while undetermined, [openSettings] only while denied, [dismiss] whenever
 * supplied; [enabled] is false while busy (visible actions stay rendered but disabled).
 */
data class FlarePermissionActions(val request: Boolean, val openSettings: Boolean, val dismiss: Boolean, val enabled: Boolean)

fun permissionActions(
    state: FlarePermissionState,
    hasRequest: Boolean,
    hasOpenSettings: Boolean,
    hasDismiss: Boolean,
    busy: Boolean = false,
): FlarePermissionActions = FlarePermissionActions(
    request = state == FlarePermissionState.Undetermined && hasRequest,
    openSettings = state == FlarePermissionState.Denied && hasOpenSettings,
    dismiss = hasDismiss,
    enabled = !busy,
)

/** Default copy for a kind + state pair. */
data class FlarePermissionCopy(val title: String, val description: String, val primaryLabel: String)

private fun kindNoun(kind: FlarePermissionKind): String = when (kind) {
    FlarePermissionKind.Microphone -> "麦克风"
    FlarePermissionKind.Camera -> "摄像头"
    FlarePermissionKind.Notifications -> "通知"
    FlarePermissionKind.Storage -> "存储空间"
    FlarePermissionKind.Photos -> "相册"
    FlarePermissionKind.Contacts -> "通讯录"
    FlarePermissionKind.Location -> "位置信息"
    FlarePermissionKind.Screen -> "屏幕录制"
}

private fun kindVerb(kind: FlarePermissionKind): String = when (kind) {
    FlarePermissionKind.Microphone -> "使用麦克风"
    FlarePermissionKind.Camera -> "使用摄像头"
    FlarePermissionKind.Notifications -> "发送通知"
    FlarePermissionKind.Storage -> "访问存储空间"
    FlarePermissionKind.Photos -> "访问相册"
    FlarePermissionKind.Contacts -> "访问通讯录"
    FlarePermissionKind.Location -> "获取位置信息"
    FlarePermissionKind.Screen -> "录制屏幕内容"
}

/** Kit icon name per kind (resolved through [FlareIcon]; same names on every platform). */
fun permissionIconName(kind: FlarePermissionKind): String = when (kind) {
    FlarePermissionKind.Microphone -> "mic"
    FlarePermissionKind.Camera -> "camera"
    FlarePermissionKind.Notifications -> "notification"
    FlarePermissionKind.Storage -> "folder"
    FlarePermissionKind.Photos -> "image"
    FlarePermissionKind.Contacts -> "people"
    FlarePermissionKind.Location -> "location"
    FlarePermissionKind.Screen -> "devices"
}

/** State glyph so status never relies on colour alone. */
fun permissionStateIconName(state: FlarePermissionState): String = when (state) {
    FlarePermissionState.Undetermined -> "info"
    FlarePermissionState.Denied -> "block"
    FlarePermissionState.Restricted -> "lock"
    FlarePermissionState.Unavailable -> "warning"
}

/** `featureLabel` (e.g. "发送语音消息") is embedded in the description. */
fun defaultPermissionCopy(kind: FlarePermissionKind, state: FlarePermissionState, featureLabel: String? = null): FlarePermissionCopy {
    val feature = featureLabel?.trim().takeUnless { it.isNullOrEmpty() } ?: "此功能"
    val verb = kindVerb(kind)
    val title = "需要${kindNoun(kind)}权限"
    return when (state) {
        FlarePermissionState.Undetermined -> FlarePermissionCopy(title, "${feature}需要${verb}，请允许后继续。", "允许")
        FlarePermissionState.Denied -> FlarePermissionCopy(title, "${verb}的权限已被拒绝，${feature}无法使用。请前往系统设置开启。", "前往设置")
        FlarePermissionState.Restricted -> FlarePermissionCopy(title, "${verb}的权限受设备或组织策略限制，${feature}暂不可用。", "")
        FlarePermissionState.Unavailable -> FlarePermissionCopy(title, "当前设备或运行环境不支持${verb}，${feature}暂不可用。", "")
    }
}

fun defaultPermissionStateLabel(state: FlarePermissionState): String = when (state) {
    FlarePermissionState.Undetermined -> "未授权"
    FlarePermissionState.Denied -> "已拒绝"
    FlarePermissionState.Restricted -> "受限制"
    FlarePermissionState.Unavailable -> "不可用"
}

/**
 * Unified "permission missing / denied" panel. The host owns the real permission state and the
 * request / openSettings side effects; this composable only explains and dispatches.
 * Spec: General/PermissionPrompt (`PermissionPrompt`).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun PermissionPrompt(
    kind: FlarePermissionKind,
    state: FlarePermissionState,
    featureLabel: String? = null,
    detail: String? = null,
    busy: Boolean = false,
    compact: Boolean = false,
    title: String? = null,
    description: String? = null,
    stateText: String? = null,
    requestText: String? = null,
    openSettingsText: String? = null,
    dismissText: String = "知道了",
    onRequest: (() -> Unit)? = null,
    onOpenSettings: (() -> Unit)? = null,
    onDismiss: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val colors = flareColors()
    val copy = defaultPermissionCopy(kind, state, featureLabel)
    val actions = permissionActions(state, onRequest != null, onOpenSettings != null, onDismiss != null, busy)
    val resolvedTitle = title ?: copy.title
    val tone = when (state) {
        FlarePermissionState.Undetermined -> colors.info
        FlarePermissionState.Denied -> colors.error
        FlarePermissionState.Restricted -> colors.warning
        FlarePermissionState.Unavailable -> colors.textSecondary
    }
    val hasActions = actions.request || actions.openSettings || actions.dismiss
    val radius = if (compact) FlareSizes.radiusMd else FlareSizes.radiusLg

    val icon: @Composable () -> Unit = {
        Box(
            Modifier.size(if (compact) 32.dp else 44.dp).clip(CircleShape).background(colors.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) { FlareIcon(permissionIconName(kind), size = if (compact) 20.dp else 26.dp, tint = colors.primary) }
    }
    val textBlock: @Composable (Modifier) -> Unit = { m ->
        Column(m, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            FlowRow(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(
                    resolvedTitle,
                    color = colors.textPrimary,
                    fontSize = (if (compact) FlareSizes.fontSizeLg else FlareSizes.fontSizeXl).value.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Row(
                    Modifier
                        .clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .background(tone.copy(alpha = 0.12f))
                        .padding(horizontal = FlareSizes.spacingSm, vertical = 2.dp)
                        .semantics { liveRegion = LiveRegionMode.Polite },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                ) {
                    FlareIcon(permissionStateIconName(state), size = 14.dp, tint = tone)
                    Text(stateText ?: defaultPermissionStateLabel(state), color = tone, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
                }
            }
            Text(
                description ?: copy.description,
                color = colors.textSecondary,
                fontSize = (if (compact) FlareSizes.fontSizeSm else FlareSizes.fontSizeMd).value.sp,
            )
            if (!detail.isNullOrEmpty()) {
                Text(detail, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
        }
    }
    val actionRow: @Composable () -> Unit = {
        FlowRow(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            if (actions.request && onRequest != null) {
                PrimaryButton(requestText ?: copy.primaryLabel, onClick = onRequest, enabled = actions.enabled, loading = busy, modifier = Modifier.widthIn(min = 48.dp, max = 240.dp))
            }
            if (actions.openSettings && onOpenSettings != null) {
                PrimaryButton(openSettingsText ?: copy.primaryLabel, onClick = onOpenSettings, enabled = actions.enabled, loading = busy, modifier = Modifier.widthIn(min = 48.dp, max = 240.dp))
            }
            if (actions.dismiss && onDismiss != null) {
                OutlinedButton(
                    onClick = onDismiss,
                    enabled = actions.enabled,
                    shape = RoundedCornerShape(FlareSizes.radiusLg),
                    border = BorderStroke(1.dp, colors.borderPrimary),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.textPrimary),
                    modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp),
                ) { Text(dismissText, fontSize = FlareSizes.fontSizeXl.value.sp, fontWeight = FontWeight.SemiBold) }
            }
        }
    }

    Box(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(radius))
            .background(colors.bgSecondary)
            .then(if (compact) Modifier.border(1.dp, colors.borderSecondary, RoundedCornerShape(radius)) else Modifier)
            .padding(horizontal = if (compact) FlareSizes.spacingMd else FlareSizes.spacingLg, vertical = if (compact) FlareSizes.spacingSm else FlareSizes.spacingLg)
            .semantics { contentDescription = resolvedTitle },
    ) {
        if (compact) {
            BoxWithConstraints {
                if (maxWidth >= 480.dp) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        icon()
                        Spacer(Modifier.width(FlareSizes.spacingMd))
                        textBlock(Modifier.weight(1f))
                        if (hasActions) { Spacer(Modifier.width(FlareSizes.spacingMd)); actionRow() }
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            icon()
                            Spacer(Modifier.width(FlareSizes.spacingMd))
                            textBlock(Modifier.weight(1f))
                        }
                        if (hasActions) actionRow()
                    }
                }
            }
        } else {
            Row(verticalAlignment = Alignment.Top) {
                icon()
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    textBlock(Modifier.fillMaxWidth())
                    if (hasActions) { Spacer(Modifier.height(FlareSizes.spacingMd)); actionRow() }
                }
            }
        }
    }
}

