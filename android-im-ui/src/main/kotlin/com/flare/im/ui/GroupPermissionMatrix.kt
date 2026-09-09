package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AlternateEmail
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Join policy values as the backend defines them on the group model. */
const val FLARE_GROUP_JOIN_INVITE = 1
const val FLARE_GROUP_JOIN_APPROVAL = 2
const val FLARE_GROUP_JOIN_OPEN = 3

/**
 * The five settings the matrix edits — one key per real backend field
 * (`FlareGroupDetailModel`: joinPolicy, muteAll, onlyAdminCanAtAll,
 * onlyAdminCanPin, shareCardPermission). Nothing here is invented.
 * [wire] is the string key used in `busyKeys` / `errors`, shared with the other platforms.
 */
enum class FlareGroupPermissionKey(val wire: String) {
    JoinPolicy("joinPolicy"),
    MuteAll("muteAll"),
    OnlyAdminCanAtAll("onlyAdminCanAtAll"),
    OnlyAdminCanPin("onlyAdminCanPin"),
    ShareCardPermission("shareCardPermission"),
}

/** `Toggle` renders a switch (Boolean value); `Choice` renders a radio group (Int value). */
enum class FlareGroupPermissionRowKind { Toggle, Choice }

/** The subset of the group model this panel edits. */
data class FlareGroupPermissionSettings(
    val muteAll: Boolean = false,
    val onlyAdminCanAtAll: Boolean = false,
    val onlyAdminCanPin: Boolean = false,
    val shareCardPermission: Boolean = true,
    /** 1 = invite only, 2 = approval required, 3 = open. */
    val joinPolicy: Int = FLARE_GROUP_JOIN_APPROVAL,
)

/** One rendered row; [value] is a `Boolean` for toggle rows and an `Int` for choice rows. */
data class FlareGroupPermissionRow(
    val key: FlareGroupPermissionKey,
    val kind: FlareGroupPermissionRowKind,
    val value: Any,
    /** Viewer may change this row; `false` renders a read-only value, never a dead switch. */
    val editable: Boolean,
    /** This row's command is in flight — the row alone locks, its siblings stay usable. */
    val busy: Boolean,
    /** Why this row's last command failed; kept until the host dismisses it. */
    val error: String? = null,
) {
    val boolValue: Boolean get() = value == true
    val intValue: Int get() = value as? Int ?: -1
}

/** True when [value] is one of the three defined join policies. */
fun isGroupJoinPolicy(value: Int): Boolean =
    value == FLARE_GROUP_JOIN_INVITE || value == FLARE_GROUP_JOIN_APPROVAL || value == FLARE_GROUP_JOIN_OPEN

/**
 * The rows to render, in canonical order — same rule set as the other platforms.
 *
 * [FlareGroupPermissionRow.editable] carries permission only (`canManage`), so a
 * read-only panel keeps showing values instead of disabled controls; `busy` and
 * `error` are per key, so one failed setting neither hides nor reverts the ones
 * that succeeded. An unknown `joinPolicy` is passed through untouched rather
 * than misreporting the group's real state.
 */
fun groupPermissionRows(
    settings: FlareGroupPermissionSettings,
    canManage: Boolean,
    busyKeys: List<String> = emptyList(),
    errors: Map<String, String> = emptyMap(),
): List<FlareGroupPermissionRow> {
    val busy = busyKeys.toSet()
    return FlareGroupPermissionKey.entries.map { key ->
        val value: Any = when (key) {
            FlareGroupPermissionKey.JoinPolicy -> settings.joinPolicy
            FlareGroupPermissionKey.MuteAll -> settings.muteAll
            FlareGroupPermissionKey.OnlyAdminCanAtAll -> settings.onlyAdminCanAtAll
            FlareGroupPermissionKey.OnlyAdminCanPin -> settings.onlyAdminCanPin
            FlareGroupPermissionKey.ShareCardPermission -> settings.shareCardPermission
        }
        FlareGroupPermissionRow(
            key = key,
            kind = if (key == FlareGroupPermissionKey.JoinPolicy) FlareGroupPermissionRowKind.Choice
            else FlareGroupPermissionRowKind.Toggle,
            value = value,
            editable = canManage,
            busy = busy.contains(key.wire),
            error = errors[key.wire],
        )
    }
}

private fun iconFor(key: FlareGroupPermissionKey): ImageVector = when (key) {
    FlareGroupPermissionKey.JoinPolicy -> Icons.Outlined.Lock
    FlareGroupPermissionKey.MuteAll -> Icons.Outlined.VolumeOff
    FlareGroupPermissionKey.OnlyAdminCanAtAll -> Icons.Outlined.AlternateEmail
    FlareGroupPermissionKey.OnlyAdminCanPin -> Icons.Outlined.PushPin
    FlareGroupPermissionKey.ShareCardPermission -> Icons.Outlined.Share
}

/**
 * Group permission panel — the "group settings" section of group management.
 *
 * The host owns the values: switching a row only calls [onChange], and the
 * displayed value flips when the host writes the confirmed settings back. Each
 * row has its own busy and its own failure, so a partial failure keeps the rows
 * that succeeded. Spec: Contacts/GroupPermissionMatrix (`GroupPermissionMatrix`).
 */
@Composable
fun GroupPermissionMatrix(
    settings: FlareGroupPermissionSettings,
    /** Viewer may edit; false renders read-only value rows, never dead switches. */
    canManage: Boolean = false,
    /** Keys whose command is in flight — the host sets this before dispatching. */
    busyKeys: List<String> = emptyList(),
    /** Per-key failure reason, kept on screen until the host dismisses it. */
    errors: Map<String, String> = emptyMap(),
    title: String = "群设置",
    readOnlyHintText: String = "仅群主和管理员可修改",
    joinPolicyLabel: String = "加群方式",
    joinPolicyDescription: String = "决定他人如何加入本群",
    joinInviteText: String = "仅邀请",
    joinApprovalText: String = "需管理员审批",
    joinOpenText: String = "允许直接加入",
    unknownJoinPolicyText: String = "当前加群方式未知，请重新选择",
    muteAllLabel: String = "全员禁言",
    muteAllDescription: String = "开启后仅群主和管理员可发言",
    onlyAdminCanAtAllLabel: String = "仅管理员可 @所有人",
    onlyAdminCanAtAllDescription: String = "限制 @所有人 的使用范围",
    onlyAdminCanPinLabel: String = "仅管理员可置顶消息",
    onlyAdminCanPinDescription: String = "限制群内置顶消息的权限",
    shareCardPermissionLabel: String = "允许分享群名片",
    shareCardPermissionDescription: String = "关闭后成员不能把本群分享给他人",
    onText: String = "已开启",
    offText: String = "已关闭",
    busyText: String = "提交中",
    retryText: String = "重试",
    dismissErrorText: String = "忽略此错误",
    onChange: ((FlareGroupPermissionKey, Any) -> Unit)? = null,
    onDismissError: ((FlareGroupPermissionKey) -> Unit)? = null,
) {
    val colors = flareColors()
    // Editing needs both the permission and a host callback to honour it.
    val canEdit = canManage && onChange != null
    val rows = groupPermissionRows(settings, canEdit, busyKeys, errors)
    // What this panel last asked for, per key, so "retry" resends the same intent.
    // Not optimistic state: the rendered value stays the host's.
    val lastAttempt = remember { mutableStateMapOf<FlareGroupPermissionKey, Any>() }

    fun labelFor(key: FlareGroupPermissionKey) = when (key) {
        FlareGroupPermissionKey.JoinPolicy -> joinPolicyLabel
        FlareGroupPermissionKey.MuteAll -> muteAllLabel
        FlareGroupPermissionKey.OnlyAdminCanAtAll -> onlyAdminCanAtAllLabel
        FlareGroupPermissionKey.OnlyAdminCanPin -> onlyAdminCanPinLabel
        FlareGroupPermissionKey.ShareCardPermission -> shareCardPermissionLabel
    }

    fun descriptionFor(key: FlareGroupPermissionKey) = when (key) {
        FlareGroupPermissionKey.JoinPolicy -> joinPolicyDescription
        FlareGroupPermissionKey.MuteAll -> muteAllDescription
        FlareGroupPermissionKey.OnlyAdminCanAtAll -> onlyAdminCanAtAllDescription
        FlareGroupPermissionKey.OnlyAdminCanPin -> onlyAdminCanPinDescription
        FlareGroupPermissionKey.ShareCardPermission -> shareCardPermissionDescription
    }

    val joinOptions = listOf(
        FLARE_GROUP_JOIN_INVITE to joinInviteText,
        FLARE_GROUP_JOIN_APPROVAL to joinApprovalText,
        FLARE_GROUP_JOIN_OPEN to joinOpenText,
    )
    fun joinPolicyText(value: Int) = joinOptions.firstOrNull { it.first == value }?.second ?: unknownJoinPolicyText

    fun dispatch(row: FlareGroupPermissionRow, value: Any) {
        if (!canEdit || row.busy) return
        lastAttempt[row.key] = value
        onChange?.invoke(row.key, value)
    }

    // A choice row can be retried only when we know what was attempted; its options stay live anyway.
    fun retryValue(row: FlareGroupPermissionRow): Any? = lastAttempt[row.key]
        ?: if (row.kind == FlareGroupPermissionRowKind.Toggle) !row.boolValue else null

    Column(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg))
            .padding(FlareSizes.spacingMd)
            .semantics { contentDescription = title },
    ) {
        Row(
            Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                title,
                color = colors.textPrimary,
                fontSize = FlareSizes.fontSizeLg.value.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f),
            )
            if (!canEdit) {
                Icon(Icons.Outlined.Lock, null, Modifier.size(14.dp), tint = colors.textTertiary)
                Spacer(Modifier.width(4.dp))
                Text(readOnlyHintText, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
        }

        rows.forEachIndexed { index, row ->
            if (index > 0) HorizontalDivider(color = colors.borderSecondary)
            Column(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingSm)) {
                Row(
                    Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        Modifier.size(32.dp).clip(CircleShape).background(colors.primary.copy(alpha = 0.10f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(iconFor(row.key), null, Modifier.size(18.dp), tint = colors.primary)
                    }
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column(Modifier.weight(1f)) {
                        Text(
                            labelFor(row.key),
                            color = colors.textPrimary,
                            fontSize = FlareSizes.fontSizeLg.value.sp,
                            fontWeight = FontWeight.Medium,
                        )
                        Text(
                            descriptionFor(row.key),
                            color = colors.textSecondary,
                            fontSize = FlareSizes.fontSizeSm.value.sp,
                        )
                    }
                    Spacer(Modifier.width(FlareSizes.spacingSm))
                    if (row.busy) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            CircularProgressIndicator(
                                Modifier.size(14.dp),
                                color = colors.textTertiary,
                                strokeWidth = 2.dp,
                            )
                            Spacer(Modifier.width(5.dp))
                            Text(busyText, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                            Spacer(Modifier.width(FlareSizes.spacingSm))
                        }
                    }
                    if (row.kind == FlareGroupPermissionRowKind.Toggle) {
                        if (row.editable) {
                            Switch(value = row.boolValue, disabled = row.busy) { v -> dispatch(row, v) }
                        } else {
                            Text(
                                if (row.boolValue) onText else offText,
                                color = colors.textSecondary,
                                fontSize = FlareSizes.fontSizeMd.value.sp,
                            )
                        }
                    } else if (!row.editable) {
                        Text(
                            joinPolicyText(row.intValue),
                            color = colors.textSecondary,
                            fontSize = FlareSizes.fontSizeMd.value.sp,
                        )
                    }
                }

                if (row.kind == FlareGroupPermissionRowKind.Choice && row.editable) {
                    Column(Modifier.padding(start = 44.dp, top = FlareSizes.spacingXs)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            joinOptions.forEach { (value, label) ->
                                ChoiceChip(
                                    label = label,
                                    selected = row.intValue == value,
                                    enabled = row.editable && !row.busy,
                                    colors = colors,
                                ) { dispatch(row, value) }
                            }
                        }
                        if (!isGroupJoinPolicy(row.intValue)) {
                            Text(
                                unknownJoinPolicyText,
                                color = colors.warning,
                                fontSize = FlareSizes.fontSizeSm.value.sp,
                                modifier = Modifier.padding(top = 4.dp),
                            )
                        }
                    }
                }

                val error = row.error
                if (error != null) {
                    val retry = retryValue(row)
                    Row(
                        Modifier.padding(start = 44.dp, top = FlareSizes.spacingXs)
                            .clip(RoundedCornerShape(FlareSizes.radiusSm))
                            .background(colors.error.copy(alpha = 0.08f))
                            .padding(horizontal = 8.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Outlined.ErrorOutline, null, Modifier.size(14.dp), tint = colors.error)
                        Spacer(Modifier.width(6.dp))
                        Text(
                            error,
                            color = colors.error,
                            fontSize = FlareSizes.fontSizeSm.value.sp,
                            modifier = Modifier.weight(1f),
                        )
                        if (row.editable && !row.busy && retry != null) {
                            Row(
                                Modifier.clip(RoundedCornerShape(FlareSizes.radiusSm))
                                    .clickable(role = Role.Button, onClickLabel = retryText) { dispatch(row, retry) }
                                    .padding(horizontal = 8.dp, vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(Icons.Outlined.Refresh, null, Modifier.size(14.dp), tint = colors.textPrimary)
                                Spacer(Modifier.width(4.dp))
                                Text(retryText, color = colors.textPrimary, fontSize = FlareSizes.fontSizeSm.value.sp)
                            }
                        }
                        if (onDismissError != null) {
                            Icon(
                                Icons.Outlined.Close,
                                null,
                                Modifier.size(20.dp)
                                    .clip(RoundedCornerShape(FlareSizes.radiusSm))
                                    .clickable(role = Role.Button, onClickLabel = dismissErrorText) {
                                        onDismissError(row.key)
                                    }
                                    .padding(3.dp),
                                tint = colors.textSecondary,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ChoiceChip(
    label: String,
    selected: Boolean,
    enabled: Boolean,
    colors: FlareColors,
    onClick: () -> Unit,
) {
    Row(
        Modifier.heightIn(min = FlareSizes.touchTarget)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(if (selected) colors.bgSelected else colors.bgSecondary)
            .border(
                1.dp,
                if (selected) colors.borderSelected else colors.borderPrimary,
                RoundedCornerShape(FlareSizes.radiusMd),
            )
            .alpha(if (enabled) 1f else 0.5f)
            .clickable(enabled = enabled, role = Role.RadioButton, onClickLabel = label) { onClick() }
            .padding(horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(14.dp), contentAlignment = Alignment.Center) {
            if (selected) Icon(Icons.Outlined.Check, null, Modifier.size(14.dp), tint = colors.primary)
        }
        Spacer(Modifier.width(5.dp))
        Text(
            label,
            color = if (selected) colors.primary else colors.textPrimary,
            fontSize = FlareSizes.fontSizeMd.value.sp,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
        )
    }
}
