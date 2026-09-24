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
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Refresh
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

/**
 * How people join a group. Declaration order is the display order of the choices: open,
 * approval, invite. The kit does not encode backend numbers — a host maps its own values in its
 * mapper, and a policy it does not know is `null` (shown as not set), never a guessed default.
 */
enum class FlareGroupJoinPolicy { Open, Approval, Invite }

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

/** `Toggle` renders a switch (Boolean value); `Choice` renders a radio group ([FlareGroupJoinPolicy] value). */
enum class FlareGroupPermissionRowKind { Toggle, Choice }

/** The subset of the group model this panel edits. */
data class FlareGroupPermissionSettings(
    val muteAll: Boolean = false,
    val onlyAdminCanAtAll: Boolean = false,
    val onlyAdminCanPin: Boolean = false,
    val shareCardPermission: Boolean = true,
    /** Null when the host does not know the policy: no choice is selected and the panel says so. */
    val joinPolicy: FlareGroupJoinPolicy? = null,
)

/**
 * One rendered row; [value] is a `Boolean` for toggle rows and a [FlareGroupJoinPolicy] — or
 * null when unknown — for the choice row.
 */
data class FlareGroupPermissionRow(
    val key: FlareGroupPermissionKey,
    val kind: FlareGroupPermissionRowKind,
    val value: Any?,
    /** Viewer may change this row; `false` renders a read-only value, never a dead switch. */
    val editable: Boolean,
    /** This row's command is in flight — the row alone locks, its siblings stay usable. */
    val busy: Boolean,
    /** Why this row's last command failed; kept until the host dismisses it. */
    val error: String? = null,
) {
    val boolValue: Boolean get() = value == true
    /** The choice row's policy; null when the host does not know it. */
    val joinPolicyValue: FlareGroupJoinPolicy? get() = value as? FlareGroupJoinPolicy
}

/**
 * The rows to render, in canonical order — same rule set as the other platforms.
 *
 * [FlareGroupPermissionRow.editable] carries permission only (`canManage`), so a
 * read-only panel keeps showing values instead of disabled controls; `busy` and
 * `error` are per key, so one failed setting neither hides nor reverts the ones
 * that succeeded. An unknown (null) `joinPolicy` is passed through as null rather
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
        val value: Any? = when (key) {
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

/** Registry icon per permission row; muting everyone is `silence` (nobody may speak), not the notification bell. */
internal fun groupPermissionIconName(key: FlareGroupPermissionKey): String = when (key) {
    FlareGroupPermissionKey.JoinPolicy -> "lock"
    FlareGroupPermissionKey.MuteAll -> "silence"
    FlareGroupPermissionKey.OnlyAdminCanAtAll -> "mention"
    FlareGroupPermissionKey.OnlyAdminCanPin -> "pin"
    FlareGroupPermissionKey.ShareCardPermission -> "share"
}

private fun iconFor(key: FlareGroupPermissionKey): ImageVector = flareIconVector(groupPermissionIconName(key))

/**
 * Group permission panel — the "group settings" section of group management.
 *
 * The host owns the values: switching a row only calls [onChange], and the
 * displayed value flips when the host writes the confirmed settings back. Each
 * row has its own busy and its own failure, so a partial failure keeps the rows
 * that succeeded. Spec: Contacts/GroupPermissionMatrix (`GroupPermissionMatrix`).
 */
@Suppress("NAME_SHADOWING")
@Composable
fun GroupPermissionMatrix(
    settings: FlareGroupPermissionSettings,
    /** Viewer may edit; false renders read-only value rows, never dead switches. */
    canManage: Boolean = false,
    /** Keys whose command is in flight — the host sets this before dispatching. */
    busyKeys: List<String> = emptyList(),
    /** Per-key failure reason, kept on screen until the host dismisses it. */
    errors: Map<String, String> = emptyMap(),
    title: String? = null,
    readOnlyHintText: String? = null,
    joinPolicyLabel: String? = null,
    joinPolicyDescription: String? = null,
    joinInviteText: String? = null,
    joinApprovalText: String? = null,
    joinOpenText: String? = null,
    unknownJoinPolicyText: String? = null,
    muteAllLabel: String? = null,
    muteAllDescription: String? = null,
    onlyAdminCanAtAllLabel: String? = null,
    onlyAdminCanAtAllDescription: String? = null,
    onlyAdminCanPinLabel: String? = null,
    onlyAdminCanPinDescription: String? = null,
    shareCardPermissionLabel: String? = null,
    shareCardPermissionDescription: String? = null,
    onText: String? = null,
    offText: String? = null,
    busyText: String? = null,
    retryText: String? = null,
    dismissErrorText: String? = null,
    /** The requested value: a `Boolean` for a toggle row, a [FlareGroupJoinPolicy] for the join policy. */
    onChange: ((FlareGroupPermissionKey, Any) -> Unit)? = null,
    onDismissError: ((FlareGroupPermissionKey) -> Unit)? = null,
) {
    val strings = flareStrings()
    val title = title ?: strings.groupPermissionMatrixTitle
    val readOnlyHintText = readOnlyHintText ?: strings.groupPermissionMatrixReadOnlyHint
    val joinPolicyLabel = joinPolicyLabel ?: strings.groupPermissionMatrixJoinPolicy
    val joinPolicyDescription = joinPolicyDescription ?: strings.groupPermissionMatrixJoinPolicyDescription
    val joinInviteText = joinInviteText ?: strings.groupPermissionMatrixJoinInvite
    val joinApprovalText = joinApprovalText ?: strings.groupPermissionMatrixJoinApproval
    val joinOpenText = joinOpenText ?: strings.groupPermissionMatrixJoinOpen
    val unknownJoinPolicyText = unknownJoinPolicyText ?: strings.groupPermissionMatrixUnknownJoinPolicy
    val muteAllLabel = muteAllLabel ?: strings.groupPermissionMatrixMuteAll
    val muteAllDescription = muteAllDescription ?: strings.groupPermissionMatrixMuteAllDescription
    val onlyAdminCanAtAllLabel = onlyAdminCanAtAllLabel ?: strings.groupPermissionMatrixOnlyAdminCanAtAll
    val onlyAdminCanAtAllDescription = onlyAdminCanAtAllDescription ?: strings.groupPermissionMatrixOnlyAdminCanAtAllDescription
    val onlyAdminCanPinLabel = onlyAdminCanPinLabel ?: strings.groupPermissionMatrixOnlyAdminCanPin
    val onlyAdminCanPinDescription = onlyAdminCanPinDescription ?: strings.groupPermissionMatrixOnlyAdminCanPinDescription
    val shareCardPermissionLabel = shareCardPermissionLabel ?: strings.groupPermissionMatrixShareCardPermission
    val shareCardPermissionDescription = shareCardPermissionDescription ?: strings.groupPermissionMatrixShareCardPermissionDescription
    val onText = onText ?: strings.groupPermissionMatrixOn
    val offText = offText ?: strings.groupPermissionMatrixOff
    val busyText = busyText ?: strings.groupPermissionMatrixBusy
    val retryText = retryText ?: strings.retry
    val dismissErrorText = dismissErrorText ?: strings.groupPermissionMatrixDismissError
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

    fun joinChoiceText(policy: FlareGroupJoinPolicy) = when (policy) {
        FlareGroupJoinPolicy.Open -> joinOpenText
        FlareGroupJoinPolicy.Approval -> joinApprovalText
        FlareGroupJoinPolicy.Invite -> joinInviteText
    }
    fun joinPolicyText(policy: FlareGroupJoinPolicy?) = policy?.let(::joinChoiceText) ?: unknownJoinPolicyText

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
                Icon(Icons.Outlined.Lock, null, Modifier.size(FlareSizes.spacing2md), tint = colors.textTertiary)
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
                        Icon(iconFor(row.key), null, Modifier.size(18.dp), tint = colors.primaryText)
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
                                Modifier.size(FlareSizes.spacing2md),
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
                            joinPolicyText(row.joinPolicyValue),
                            color = colors.textSecondary,
                            fontSize = FlareSizes.fontSizeMd.value.sp,
                        )
                    }
                }

                if (row.kind == FlareGroupPermissionRowKind.Choice && row.editable) {
                    Column(Modifier.padding(start = 44.dp, top = FlareSizes.spacingXs)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
                            FlareGroupJoinPolicy.entries.forEach { policy ->
                                ChoiceChip(
                                    label = joinChoiceText(policy),
                                    selected = row.joinPolicyValue == policy,
                                    enabled = row.editable && !row.busy,
                                    colors = colors,
                                ) { dispatch(row, policy) }
                            }
                        }
                        if (row.joinPolicyValue == null) {
                            Text(
                                unknownJoinPolicyText,
                                color = colors.warningText,
                                fontSize = FlareSizes.fontSizeSm.value.sp,
                                modifier = Modifier.padding(top = FlareSizes.spacingXs),
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
                            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacing2xs),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Outlined.ErrorOutline, null, Modifier.size(FlareSizes.spacing2md), tint = colors.errorText)
                        Spacer(Modifier.width(6.dp))
                        Text(
                            error,
                            color = colors.errorText,
                            fontSize = FlareSizes.fontSizeSm.value.sp,
                            modifier = Modifier.weight(1f),
                        )
                        if (row.editable && !row.busy && retry != null) {
                            Row(
                                Modifier.clip(RoundedCornerShape(FlareSizes.radiusSm))
                                    .clickable(role = Role.Button, onClickLabel = retryText) { dispatch(row, retry) }
                                    .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(Icons.Outlined.Refresh, null, Modifier.size(FlareSizes.spacing2md), tint = colors.textPrimary)
                                Spacer(Modifier.width(4.dp))
                                Text(retryText, color = colors.textPrimary, fontSize = FlareSizes.fontSizeSm.value.sp)
                            }
                        }
                        if (onDismissError != null) {
                            // A named 48 dp target around the 14 dp glyph, like the relation bar's dismiss button.
                            FlareIconControl(
                                label = dismissErrorText,
                                onClick = { onDismissError(row.key) },
                                shape = RoundedCornerShape(FlareSizes.radiusSm),
                            ) {
                                Icon(flareIconVector("close"), null, Modifier.size(FlareSizes.spacing2md), tint = colors.textSecondary)
                            }
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
            .padding(horizontal = FlareSizes.spacing2sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(FlareSizes.spacing2md), contentAlignment = Alignment.Center) {
            if (selected) Icon(Icons.Outlined.Check, null, Modifier.size(FlareSizes.spacing2md), tint = colors.primaryText)
        }
        Spacer(Modifier.width(5.dp))
        Text(
            label,
            color = if (selected) colors.primaryText else colors.textPrimary,
            fontSize = FlareSizes.fontSizeMd.value.sp,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
        )
    }
}
