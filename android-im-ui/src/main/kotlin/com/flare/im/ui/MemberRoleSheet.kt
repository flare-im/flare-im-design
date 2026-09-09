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
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Logout
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** A member's role in the group. */
enum class FlareGroupMemberRole { Owner, Admin, Member }

/** Management actions a [MemberRoleSheet] can emit; names match the cross-platform contract. */
enum class FlareMemberRoleAction { Promote, Demote, Mute, Unmute, TransferOwner, Remove }

/** The member the sheet acts on; [id] must be stable and is echoed in the callback. */
data class FlareGroupMemberSnapshot(
    val id: String,
    val name: String,
    val role: FlareGroupMemberRole,
    val avatarUrl: String? = null,
    val muted: Boolean = false,
)

/** Host-declared capabilities. `false` → the action is not rendered. */
data class FlareMemberRoleCapabilities(
    val promote: Boolean = false,
    val demote: Boolean = false,
    val mute: Boolean = false,
    val unmute: Boolean = false,
    val remove: Boolean = false,
    val transferOwner: Boolean = false,
)

/** One host-supplied mute duration option; the kit ships no durations of its own. */
data class FlareMemberMuteDuration(val id: String, val label: String)

/** One displayable action; [danger] entries render in the trailing danger group. */
data class FlareMemberRoleActionEntry(
    val action: FlareMemberRoleAction,
    val danger: Boolean = false,
)

/**
 * Ordered management actions for [member] as seen by [viewerRole] — the same
 * rule set as the other platforms. Rank rules come first, capabilities only
 * narrow further:
 *
 *  - the owner is untouchable — no promote / demote / mute / remove / transfer;
 *  - a plain member sees nothing (the sheet then says it has no rights);
 *  - an admin cannot act on a peer admin and can never transfer ownership;
 *  - only the owner can transfer ownership;
 *  - promote only applies to a member, demote only to an admin;
 *  - mute / unmute are mutually exclusive by `member.muted`.
 *
 * `mute` still needs host-supplied durations — a sheet with none hides the row.
 */
fun memberRoleActions(
    member: FlareGroupMemberSnapshot,
    viewerRole: FlareGroupMemberRole,
    capabilities: FlareMemberRoleCapabilities,
): List<FlareMemberRoleActionEntry> {
    if (member.role == FlareGroupMemberRole.Owner) return emptyList()
    if (viewerRole == FlareGroupMemberRole.Member) return emptyList()
    if (viewerRole == FlareGroupMemberRole.Admin && member.role == FlareGroupMemberRole.Admin) return emptyList()
    return buildList {
        if (capabilities.promote && member.role == FlareGroupMemberRole.Member) {
            add(FlareMemberRoleActionEntry(FlareMemberRoleAction.Promote))
        }
        if (capabilities.demote && member.role == FlareGroupMemberRole.Admin) {
            add(FlareMemberRoleActionEntry(FlareMemberRoleAction.Demote))
        }
        if (capabilities.mute && !member.muted) add(FlareMemberRoleActionEntry(FlareMemberRoleAction.Mute))
        if (capabilities.unmute && member.muted) add(FlareMemberRoleActionEntry(FlareMemberRoleAction.Unmute))
        if (capabilities.transferOwner && viewerRole == FlareGroupMemberRole.Owner) {
            add(FlareMemberRoleActionEntry(FlareMemberRoleAction.TransferOwner, danger = true))
        }
        if (capabilities.remove) add(FlareMemberRoleActionEntry(FlareMemberRoleAction.Remove, danger = true))
    }
}

private fun iconFor(action: FlareMemberRoleAction): ImageVector = when (action) {
    FlareMemberRoleAction.Promote -> Icons.Outlined.VerifiedUser
    FlareMemberRoleAction.Demote -> Icons.Outlined.Person
    FlareMemberRoleAction.Mute -> Icons.Outlined.VolumeOff
    FlareMemberRoleAction.Unmute -> Icons.Outlined.Notifications
    FlareMemberRoleAction.TransferOwner -> Icons.Outlined.StarBorder
    FlareMemberRoleAction.Remove -> Icons.Outlined.Logout
}

/**
 * Management menu for ONE group member: change role, mute, remove, transfer
 * ownership. Owns no positioning — place it in `ModalBottomSheet` or a popup,
 * exactly like [ConversationActionSheet]. It only emits intent: the second
 * confirmation for remove / transferOwner is the host's job (DangerConfirm),
 * and mute durations come from the host.
 * Spec: Contacts/MemberRoleSheet (`MemberRoleSheet`).
 */
@Composable
fun MemberRoleSheet(
    member: FlareGroupMemberSnapshot,
    /** The viewer's own role in this group — rank rules come before capabilities. */
    viewerRole: FlareGroupMemberRole,
    capabilities: FlareMemberRoleCapabilities = FlareMemberRoleCapabilities(),
    /** Host-supplied mute durations; empty hides mute — the kit invents no durations. */
    muteDurations: List<FlareMemberMuteDuration> = emptyList(),
    /** Host sets this synchronously before dispatching; disables every action. */
    busy: Boolean = false,
    ownerRoleText: String = "群主",
    adminRoleText: String = "管理员",
    memberRoleText: String = "成员",
    mutedText: String = "已禁言",
    promoteText: String = "设为管理员",
    demoteText: String = "取消管理员",
    muteText: String = "禁言",
    unmuteText: String = "解除禁言",
    removeText: String = "移出群聊",
    transferOwnerText: String = "转让群主",
    dangerGroupText: String = "危险操作",
    emptyText: String = "你没有管理权限",
    ownerProtectedText: String = "群主不可被管理",
    onAction: ((String, FlareMemberRoleAction, String?) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var muteOpen by remember(member.id, busy) { mutableStateOf(false) }
    val entries = memberRoleActions(member, viewerRole, capabilities)
        // mute needs host durations; with none supplied the row is not offered.
        .filter { it.action != FlareMemberRoleAction.Mute || muteDurations.isNotEmpty() }
    val primary = entries.filter { !it.danger }
    val danger = entries.filter { it.danger }
    // The owner is protected by rank, not by missing capabilities — say which it is.
    val emptyReason = if (member.role == FlareGroupMemberRole.Owner) ownerProtectedText else emptyText
    val roleText = when (member.role) {
        FlareGroupMemberRole.Owner -> ownerRoleText
        FlareGroupMemberRole.Admin -> adminRoleText
        FlareGroupMemberRole.Member -> memberRoleText
    }
    fun labelFor(action: FlareMemberRoleAction) = when (action) {
        FlareMemberRoleAction.Promote -> promoteText
        FlareMemberRoleAction.Demote -> demoteText
        FlareMemberRoleAction.Mute -> muteText
        FlareMemberRoleAction.Unmute -> unmuteText
        FlareMemberRoleAction.TransferOwner -> transferOwnerText
        FlareMemberRoleAction.Remove -> removeText
    }

    Column(
        Modifier.fillMaxWidth()
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs)
            .semantics { contentDescription = member.name }
            .onPreviewKeyEvent { ev ->
                when {
                    ev.key != Key.Escape -> false
                    muteOpen -> { muteOpen = false; true }
                    onClose != null -> { onClose(); true }
                    else -> false
                }
            },
    ) {
        // Header: who this menu acts on, with role and mute state as text + icon.
        Row(
            Modifier.fillMaxWidth()
                .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Avatar(userId = member.id, displayName = member.name, size = 40.dp)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Column(Modifier.weight(1f)) {
                Text(
                    member.name,
                    color = colors.textPrimary,
                    fontSize = FlareSizes.fontSizeXl.value.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.size(3.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val isPlain = member.role == FlareGroupMemberRole.Member
                    Text(
                        roleText,
                        color = if (isPlain) colors.textSecondary else colors.primary,
                        fontSize = FlareSizes.fontSizeSm.value.sp,
                        fontWeight = if (isPlain) FontWeight.Normal else FontWeight.SemiBold,
                        modifier = Modifier
                            .clip(RoundedCornerShape(FlareSizes.radiusSm))
                            .background(if (isPlain) colors.bgSecondary else colors.primary.copy(alpha = 0.12f))
                            .padding(horizontal = 6.dp, vertical = 1.dp),
                    )
                    if (member.muted) {
                        Spacer(Modifier.width(6.dp))
                        Icon(Icons.Outlined.VolumeOff, null, Modifier.size(12.dp), tint = colors.warning)
                        Spacer(Modifier.width(3.dp))
                        Text(mutedText, color = colors.warning, fontSize = FlareSizes.fontSizeSm.value.sp)
                    }
                }
            }
        }

        if (entries.isEmpty()) {
            Text(
                emptyReason,
                color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeLg.value.sp,
                modifier = Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            )
        }

        if (primary.isNotEmpty()) {
            MemberActionGroup(colors) {
                primary.forEach { entry ->
                    MemberActionRow(
                        entry = entry,
                        label = labelFor(entry.action),
                        expanded = if (entry.action == FlareMemberRoleAction.Mute) muteOpen else null,
                        busy = busy,
                        colors = colors,
                        onClick = if (onAction == null) null else {
                            {
                                if (entry.action == FlareMemberRoleAction.Mute) muteOpen = !muteOpen
                                else onAction(member.id, entry.action, null)
                            }
                        },
                    )
                    if (entry.action == FlareMemberRoleAction.Mute && muteOpen) {
                        Row(
                            Modifier.fillMaxWidth().padding(
                                start = 56.dp,
                                end = FlareSizes.spacingMd,
                                top = FlareSizes.spacingXs,
                                bottom = FlareSizes.spacingSm,
                            ),
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            muteDurations.forEach { duration ->
                                val enabled = !busy && onAction != null
                                Text(
                                    duration.label,
                                    color = colors.textPrimary,
                                    fontSize = FlareSizes.fontSizeMd.value.sp,
                                    modifier = Modifier
                                        .heightIn(min = FlareSizes.touchTarget)
                                        .clip(RoundedCornerShape(FlareSizes.radiusMd))
                                        .background(colors.bgSecondary)
                                        .border(
                                            1.dp,
                                            colors.borderPrimary,
                                            RoundedCornerShape(FlareSizes.radiusMd),
                                        )
                                        .alpha(if (enabled) 1f else 0.5f)
                                        .clickable(
                                            enabled = enabled,
                                            role = Role.Button,
                                            onClickLabel = duration.label,
                                        ) { onAction?.invoke(member.id, FlareMemberRoleAction.Mute, duration.id) }
                                        .padding(horizontal = 12.dp, vertical = 14.dp),
                                )
                            }
                        }
                    }
                }
            }
        }

        if (danger.isNotEmpty()) {
            Spacer(Modifier.size(FlareSizes.spacingSm))
            MemberActionGroup(colors) {
                HorizontalDivider(color = colors.borderSecondary)
                Text(
                    dangerGroupText,
                    color = colors.textTertiary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.padding(
                        horizontal = FlareSizes.spacingMd,
                        vertical = FlareSizes.spacingXs,
                    ),
                )
                danger.forEach { entry ->
                    MemberActionRow(
                        entry = entry,
                        label = labelFor(entry.action),
                        expanded = null,
                        busy = busy,
                        colors = colors,
                        onClick = onAction?.let { cb -> { cb(member.id, entry.action, null) } },
                    )
                }
            }
        }
    }
}

@Composable
private fun MemberActionGroup(colors: FlareColors, content: @Composable () -> Unit) {
    Column(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radius2xl))
            .background(colors.bgPrimary)
            .padding(vertical = FlareSizes.spacingXs),
    ) { content() }
}

@Composable
private fun MemberActionRow(
    entry: FlareMemberRoleActionEntry,
    label: String,
    expanded: Boolean?,
    busy: Boolean,
    colors: FlareColors,
    onClick: (() -> Unit)?,
) {
    val enabled = !busy && onClick != null
    var focused by remember { mutableStateOf(false) }
    val accent = if (entry.danger) colors.error else colors.primary
    val fg = if (!enabled) colors.textDisabled else if (entry.danger) colors.error else colors.textPrimary
    val iconFg = if (enabled) accent else colors.textDisabled
    val iconBg = if (enabled) accent.copy(alpha = if (entry.danger) 0.12f else 0.10f) else colors.bgDisabled
    Row(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(if (focused) colors.bgHover else colors.bgPrimary)
            .onFocusChanged { focused = it.isFocused }
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = label) { onClick?.invoke() }
            .heightIn(min = FlareSizes.touchTarget)
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(44.dp).clip(CircleShape).background(iconBg), contentAlignment = Alignment.Center) {
            Icon(iconFor(entry.action), null, Modifier.size(20.dp), tint = iconFg)
        }
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Text(
            label,
            color = fg,
            fontSize = FlareSizes.fontSize2xl.value.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.weight(1f),
        )
        if (expanded != null) {
            Icon(
                if (expanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,
                null,
                Modifier.size(16.dp),
                tint = colors.textTertiary,
            )
        }
    }
}
