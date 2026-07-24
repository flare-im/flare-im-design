package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The full data model for [FlareGroupDetail] — a group's settings / management page.
 * Mirrors the Vue kit's `FlareGroupDetailModel` (directory.ts): a presentational
 * snapshot the host maps from its session, plus the flags that gate the management
 * sections. The component renders this and emits intents; the host performs the
 * `social.group.*` writes and refreshes the model.
 */
data class FlareGroupDetailModel(
    val groupId: String,
    val name: String,
    val avatarUrl: String? = null,
    val memberCount: Int = 0,
    val announcement: String? = null,
    val members: List<Contact> = emptyList(),
    val ownerId: String = "",
    val adminIds: List<String> = emptyList(),
    /** Muted member ids — drives the per-member mute action label. */
    val mutedIds: List<String> = emptyList(),
    /** Viewer owns or administers the group (gates the management sections). */
    val canManage: Boolean = false,
    val isOwner: Boolean = false,
    /** Viewer's own nickname in this group. */
    val myNickname: String? = null,
    /** Viewer's per-group notification / pin preference. */
    val myMuted: Boolean = false,
    val myPinned: Boolean = false,
    /** Join policy: 1 = invite-only, 2 = approval, 3 = open. */
    val joinPolicy: Int = 3,
    val muteAll: Boolean = false,
    val onlyAdminCanAtAll: Boolean = false,
    val onlyAdminCanPin: Boolean = false,
    val shareCardPermission: Boolean = false,
)

/** A pending group join request, resolved for display. */
data class FlareGroupJoinRequestView(
    val requestId: String,
    val applicantId: String,
    val applicantName: String,
    val avatarUrl: String? = null,
    val message: String? = null,
)

/**
 * Chinese-default labels for [FlareGroupDetail]. Following the kit convention, strings
 * are passed as params (no Android string resources) so any host can localize.
 */
data class FlareGroupDetailLabels(
    val fallbackTitle: String = "群聊",
    val back: String = "返回",
    val unavailable: String = "群信息不可用",
    val unavailableHint: String = "未连接服务时无法加载群详情。",
    val notSet: String = "未设置",
    // Sections
    val infoSection: String = "群信息",
    val myInGroupSection: String = "我在本群",
    val manageSection: String = "群管理",
    val permsSection: String = "群权限",
    // 群信息
    val name: String = "群聊名称",
    val announcement: String = "群公告",
    val members: String = "群成员",
    // 我在本群
    val myNickname: String = "我的群昵称",
    val muteNotif: String = "消息免打扰",
    val pinGroup: String = "置顶该群",
    // 群管理
    val joinMode: String = "进群方式",
    val joinRequests: String = "入群申请",
    val muteAll: String = "全员禁言",
    val inviteLink: String = "群邀请链接",
    // 群权限
    val onlyAdminAtAll: String = "仅管理员可@全体成员",
    val onlyAdminPin: String = "仅管理员可置顶消息",
    val shareCard: String = "允许分享群名片",
    // 进群方式 options
    val joinOpen: String = "允许任何人加入",
    val joinApproval: String = "需管理员审批",
    val joinInvite: String = "仅邀请加入",
    // Footer
    val message: String = "发消息",
    val leave: String = "退出群聊",
    val dissolve: String = "解散群聊",
    // Edit sheets
    val editName: String = "群聊名称",
    val editAnnouncement: String = "群公告",
    val nicknamePlaceholder: String = "输入群昵称",
    val save: String = "保存",
    val cancel: String = "取消",
    // Member management
    val memberManage: String = "成员管理",
    val setAdmin: String = "设为管理员",
    val unsetAdmin: String = "取消管理员",
    val mute: String = "禁言 1 天",
    val unmute: String = "取消禁言",
    val transferOwner: String = "转让群主",
    val removeMember: String = "移出群聊",
    val transferConfirmPrefix: String = "确定把群主转让给「",
    val transferConfirmSuffix: String = "」吗？转让后你将变为普通成员，此操作不可撤销。",
    val confirmTransfer: String = "确认转让",
    // Invite members
    val invite: String = "邀请",
    val inviteSearchPlaceholder: String = "选择要邀请的联系人",
    // Join requests
    val loading: String = "加载中…",
    val noRequests: String = "暂无待处理的入群申请",
    val reject: String = "拒绝",
    val approve: String = "通过",
    // Invite link
    val inviteLinkHint: String = "分享邀请码，好友可凭码加入本群。",
    val generating: String = "生成中…",
    val inviteCodeLabel: String = "邀请码",
    val copyCode: String = "复制",
    val cannotGenerate: String = "暂时无法获取邀请链接。",
    val close: String = "关闭",
    // Leave / dissolve confirm
    val leaveConfirmText: String = "退出后将不再接收该群消息。",
    val dissolveConfirmText: String = "解散后所有成员将被移出，且不可恢复。",
    val confirm: String = "确定",
)

private const val JOIN_INVITE = 1
private const val JOIN_APPROVAL = 2
private const val JOIN_OPEN = 3

/** 进群方式 label. */
private fun joinPolicyLabel(policy: Int, labels: FlareGroupDetailLabels): String = when (policy) {
    JOIN_APPROVAL -> labels.joinApproval
    JOIN_INVITE -> labels.joinInvite
    else -> labels.joinOpen
}

/**
 * Group detail / management — a full presentational screen: header, hero, member grid,
 * and Feishu-style settings (群信息 / 我在本群 / 群管理 / 群权限, owner-admin gated), plus the
 * member action sheet, join-request approval, invite picker and invite link. It owns all
 * dialogs / sheets and reuses the kit [GroupMemberGrid] and [SettingsRow]. Purely
 * presentational — NO SDK / session: it renders [model] and emits intents.
 *
 * Mirrors the Vue kit's `FlareGroupDetail.vue`.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FlareGroupDetail(
    model: FlareGroupDetailModel?,
    modifier: Modifier = Modifier,
    loading: Boolean = false,
    joinRequests: List<FlareGroupJoinRequestView> = emptyList(),
    loadingJoinRequests: Boolean = false,
    inviteCode: String? = null,
    loadingInviteLink: Boolean = false,
    invitableContacts: List<Contact> = emptyList(),
    labels: FlareGroupDetailLabels = FlareGroupDetailLabels(),
    onBack: () -> Unit = {},
    onOpenChat: () -> Unit = {},
    onUpdateName: (String) -> Unit = {},
    onUpdateAnnouncement: (String) -> Unit = {},
    onUpdateMyNickname: (String) -> Unit = {},
    onSetJoinPolicy: (Int) -> Unit = {},
    onToggleMuteAll: (Boolean) -> Unit = {},
    /** key ∈ {"onlyAdminCanAtAll", "onlyAdminCanPin", "shareCardPermission"}. */
    onSetFlag: (String, Boolean) -> Unit = { _, _ -> },
    onToggleMyMuted: (Boolean) -> Unit = {},
    onToggleMyPinned: (Boolean) -> Unit = {},
    onLoadJoinRequests: () -> Unit = {},
    onRespondRequest: (String, Boolean) -> Unit = { _, _ -> },
    onEnsureInviteLink: () -> Unit = {},
    onPromoteMember: (String) -> Unit = {},
    onMuteMember: (String) -> Unit = {},
    onTransferOwner: (String) -> Unit = {},
    onRemoveMember: (String) -> Unit = {},
    onLoadContacts: () -> Unit = {},
    onInviteMembers: (List<String>) -> Unit = {},
    onLeave: () -> Unit = {},
) {
    val colors = flareColors()

    // Edit sheets ("name" | "announcement" | "nickname")
    var editKind by remember { mutableStateOf<String?>(null) }
    // Governance sheets / dialogs
    var joinModeOpen by remember { mutableStateOf(false) }
    var joinRequestsOpen by remember { mutableStateOf(false) }
    var inviteLinkOpen by remember { mutableStateOf(false) }
    var inviteMembersOpen by remember { mutableStateOf(false) }
    var confirmLeave by remember { mutableStateOf(false) }
    // Per-member management: selected member id
    var memberSheet by remember { mutableStateOf<String?>(null) }
    var transferTarget by remember { mutableStateOf<String?>(null) }
    val memberSheetState = rememberModalBottomSheetState()

    Column(modifier.fillMaxSize().background(colors.bgSecondary)) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, labels.back, tint = colors.textPrimary) }
            Text(
                model?.name ?: labels.fallbackTitle, color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSize3xl.value.sp,
            )
        }

        if (model == null) {
            if (loading) {
                Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    CircularProgressIndicator()
                }
            } else {
                EmptyState(title = labels.unavailable, description = labels.unavailableHint)
            }
            return@Column
        }

        val m = model
        val groupName = m.name.ifEmpty { labels.fallbackTitle }

        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            // Hero
            Column(
                Modifier.fillMaxWidth().padding(top = FlareSizes.spacingXl, bottom = FlareSizes.spacingSm),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Avatar(userId = m.groupId, displayName = groupName, size = 72.dp)
                Spacer(Modifier.height(10.dp))
                Text(groupName, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSize3xl.value.sp)
            }

            GroupMemberGrid(
                members = m.members,
                ownerId = m.ownerId,
                adminIds = m.adminIds,
                showAdd = m.canManage,
                onSelect = { id -> if (m.canManage && id != m.ownerId) memberSheet = id },
                onAddMember = { onLoadContacts(); inviteMembersOpen = true },
            )

            // 群信息
            SectionTitle(labels.infoSection)
            SettingsRow(
                item = SettingsItem("name", labels.name, kind = FlareSettingKind.Value, detail = m.name.ifEmpty { "-" }),
                onSelect = { if (m.canManage) editKind = "name" },
            )
            SettingsRow(
                item = SettingsItem("announcement", labels.announcement, kind = FlareSettingKind.Value, detail = m.announcement?.ifEmpty { null } ?: labels.notSet),
                onSelect = { if (m.canManage) editKind = "announcement" },
            )
            SettingsRow(
                item = SettingsItem("members", labels.members, kind = FlareSettingKind.Value, detail = "${m.memberCount}"),
            )

            // 我在本群
            SectionTitle(labels.myInGroupSection)
            SettingsRow(
                item = SettingsItem("myNickname", labels.myNickname, kind = FlareSettingKind.Value, detail = m.myNickname?.ifEmpty { null } ?: labels.notSet),
                onSelect = { editKind = "nickname" },
            )
            SettingsRow(
                item = SettingsItem("myMuted", labels.muteNotif, kind = FlareSettingKind.Toggle, value = m.myMuted),
                onToggle = { _, v -> onToggleMyMuted(v) },
            )
            SettingsRow(
                item = SettingsItem("myPinned", labels.pinGroup, kind = FlareSettingKind.Toggle, value = m.myPinned),
                onToggle = { _, v -> onToggleMyPinned(v) },
            )

            // 群管理 (owner/admin only)
            if (m.canManage) {
                SectionTitle(labels.manageSection)
                SettingsRow(
                    item = SettingsItem("joinPolicy", labels.joinMode, kind = FlareSettingKind.Value, detail = joinPolicyLabel(m.joinPolicy, labels)),
                    onSelect = { joinModeOpen = true },
                )
                SettingsRow(
                    item = SettingsItem("joinRequests", labels.joinRequests, kind = FlareSettingKind.Navigation, detail = joinRequests.size.takeIf { it > 0 }?.toString()),
                    onSelect = { onLoadJoinRequests(); joinRequestsOpen = true },
                )
                SettingsRow(
                    item = SettingsItem("muteAll", labels.muteAll, kind = FlareSettingKind.Toggle, value = m.muteAll),
                    onToggle = { _, v -> onToggleMuteAll(v) },
                )
                SettingsRow(
                    item = SettingsItem("inviteLink", labels.inviteLink, kind = FlareSettingKind.Navigation),
                    onSelect = { onEnsureInviteLink(); inviteLinkOpen = true },
                )

                // 群权限 (owner/admin only)
                SectionTitle(labels.permsSection)
                SettingsRow(
                    item = SettingsItem("onlyAdminAtAll", labels.onlyAdminAtAll, kind = FlareSettingKind.Toggle, value = m.onlyAdminCanAtAll),
                    onToggle = { _, v -> onSetFlag("onlyAdminCanAtAll", v) },
                )
                SettingsRow(
                    item = SettingsItem("onlyAdminPin", labels.onlyAdminPin, kind = FlareSettingKind.Toggle, value = m.onlyAdminCanPin),
                    onToggle = { _, v -> onSetFlag("onlyAdminCanPin", v) },
                )
                SettingsRow(
                    item = SettingsItem("shareCard", labels.shareCard, kind = FlareSettingKind.Toggle, value = m.shareCardPermission),
                    onToggle = { _, v -> onSetFlag("shareCardPermission", v) },
                )
            }

            // Footer — 发消息 + 退出/解散
            Spacer(Modifier.height(FlareSizes.spacingLg))
            Column(Modifier.padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                PrimaryButton(text = labels.message, onClick = onOpenChat, modifier = Modifier.fillMaxWidth())
                DangerBlockButton(text = if (m.isOwner) labels.dissolve else labels.leave, onClick = { confirmLeave = true })
            }
        }
    }

    // ── Edit name / announcement / nickname ─────────────────────────────────────
    editKind?.let { kind ->
        val m = model
        val title = when (kind) {
            "announcement" -> labels.editAnnouncement
            "nickname" -> labels.myNickname
            else -> labels.editName
        }
        val initial = when (kind) {
            "announcement" -> m?.announcement ?: ""
            "nickname" -> m?.myNickname ?: ""
            else -> m?.name ?: ""
        }
        val multiline = kind == "announcement"
        EditFieldDialog(
            title = title, initial = initial, multiline = multiline,
            placeholder = if (kind == "nickname") labels.nicknamePlaceholder else title,
            saveText = labels.save, cancelText = labels.cancel,
            onDismiss = { editKind = null },
            onSave = { v ->
                editKind = null
                when (kind) {
                    "name" -> onUpdateName(v.trim())
                    "announcement" -> onUpdateAnnouncement(v.trim())
                    "nickname" -> onUpdateMyNickname(v.trim())
                }
            },
        )
    }

    // ── Per-member management ───────────────────────────────────────────────────
    val selected = memberSheet
    if (selected != null && model != null) {
        val m = model
        val member = m.members.firstOrNull { it.id == selected }
        val isAdmin = m.adminIds.contains(selected)
        val isMuted = m.mutedIds.contains(selected)
        ModalBottomSheet(onDismissRequest = { memberSheet = null }, sheetState = memberSheetState) {
            Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                Text(member?.name ?: labels.memberManage, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                SecondaryBlockButton(text = if (isAdmin) labels.unsetAdmin else labels.setAdmin) { memberSheet = null; onPromoteMember(selected) }
                SecondaryBlockButton(text = if (isMuted) labels.unmute else labels.mute) { memberSheet = null; onMuteMember(selected) }
                if (m.isOwner) {
                    SecondaryBlockButton(text = labels.transferOwner) { transferTarget = selected; memberSheet = null }
                }
                DangerBlockButton(text = labels.removeMember) { memberSheet = null; onRemoveMember(selected) }
            }
        }
    }

    // ── Transfer owner confirm ──────────────────────────────────────────────────
    transferTarget?.let { target ->
        val name = model?.members?.firstOrNull { it.id == target }?.name ?: ""
        AlertDialog(
            onDismissRequest = { transferTarget = null },
            title = { Text(labels.transferOwner) },
            text = { Text(labels.transferConfirmPrefix + name + labels.transferConfirmSuffix) },
            confirmButton = { TextButton(onClick = { transferTarget = null; onTransferOwner(target) }) { Text(labels.confirmTransfer, color = colors.error) } },
            dismissButton = { TextButton(onClick = { transferTarget = null }) { Text(labels.cancel) } },
        )
    }

    // ── Join policy ─────────────────────────────────────────────────────────────
    if (joinModeOpen && model != null) {
        var draft by remember(model.joinPolicy) { mutableStateOf(model.joinPolicy.toString()) }
        AlertDialog(
            onDismissRequest = { joinModeOpen = false },
            title = { Text(labels.joinMode) },
            text = {
                RadioGroup(
                    options = listOf(
                        FlareSelectOption(JOIN_OPEN.toString(), labels.joinOpen),
                        FlareSelectOption(JOIN_APPROVAL.toString(), labels.joinApproval),
                        FlareSelectOption(JOIN_INVITE.toString(), labels.joinInvite),
                    ),
                    value = draft, vertical = true, onSelect = { draft = it },
                )
            },
            confirmButton = { TextButton(onClick = { joinModeOpen = false; onSetJoinPolicy(draft.toIntOrNull() ?: JOIN_OPEN) }) { Text(labels.save) } },
            dismissButton = { TextButton(onClick = { joinModeOpen = false }) { Text(labels.cancel) } },
        )
    }

    // ── Join requests ───────────────────────────────────────────────────────────
    if (joinRequestsOpen) {
        ModalBottomSheet(onDismissRequest = { joinRequestsOpen = false }) {
            Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Text(labels.joinRequests, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                if (loadingJoinRequests && joinRequests.isEmpty()) {
                    Row(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg), horizontalArrangement = Arrangement.Center) { CircularProgressIndicator() }
                } else if (joinRequests.isEmpty()) {
                    Text(labels.noRequests, color = colors.textTertiary, fontSize = 14.sp)
                } else {
                    joinRequests.forEach { req ->
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Avatar(userId = req.applicantId, displayName = req.applicantName, size = 40.dp)
                            Spacer(Modifier.width(FlareSizes.spacingMd))
                            Column(Modifier.weight(1f)) {
                                Text(req.applicantName, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = 15.sp)
                                req.message?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textTertiary, fontSize = 13.sp) }
                            }
                            PrimaryButton(text = labels.approve, onClick = { onRespondRequest(req.requestId, true) })
                            Spacer(Modifier.width(FlareSizes.spacingSm))
                            SecondaryBlockButton(text = labels.reject, block = false) { onRespondRequest(req.requestId, false) }
                        }
                    }
                }
            }
        }
    }

    // ── Invite link ─────────────────────────────────────────────────────────────
    if (inviteLinkOpen) {
        val clipboard = LocalClipboardManager.current
        AlertDialog(
            onDismissRequest = { inviteLinkOpen = false },
            title = { Text(labels.inviteLink) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    Text(labels.inviteLinkHint, color = colors.textTertiary, fontSize = 13.sp)
                    if (loadingInviteLink && inviteCode.isNullOrEmpty()) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) { CircularProgressIndicator() }
                    } else if (inviteCode.isNullOrEmpty()) {
                        Text(labels.cannotGenerate, color = colors.textTertiary)
                    } else {
                        Text(labels.inviteCodeLabel, color = colors.textTertiary, fontSize = 13.sp)
                        Text(inviteCode, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = 18.sp)
                    }
                }
            },
            confirmButton = {
                TextButton(
                    enabled = !inviteCode.isNullOrEmpty(),
                    onClick = { inviteCode?.let { clipboard.setText(AnnotatedString(it)) }; inviteLinkOpen = false },
                ) { Text(labels.copyCode) }
            },
            dismissButton = { TextButton(onClick = { inviteLinkOpen = false }) { Text(labels.close) } },
        )
    }

    // ── Invite members ──────────────────────────────────────────────────────────
    if (inviteMembersOpen) {
        val memberIds = model?.members?.map { it.id }?.toSet() ?: emptySet()
        val invitable = invitableContacts.filter { it.id !in memberIds }
        ModalBottomSheet(onDismissRequest = { inviteMembersOpen = false }) {
            StartConversationDialog(
                searchPlaceholder = labels.inviteSearchPlaceholder,
                contacts = invitable.map { FlareContactOption(id = it.id, name = it.name, avatarUrl = it.avatarUrl, subtitle = it.signature) },
                allowGroup = true,
                onConfirm = { ids ->
                    inviteMembersOpen = false
                    if (ids.isNotEmpty()) onInviteMembers(ids)
                },
            )
        }
    }

    // ── Leave / dissolve confirm ────────────────────────────────────────────────
    if (confirmLeave) {
        val owner = model?.isOwner == true
        AlertDialog(
            onDismissRequest = { confirmLeave = false },
            title = { Text(if (owner) labels.dissolve else labels.leave) },
            text = { Text(if (owner) labels.dissolveConfirmText else labels.leaveConfirmText) },
            confirmButton = { TextButton(onClick = { confirmLeave = false; onLeave() }) { Text(labels.confirm, color = colors.error) } },
            dismissButton = { TextButton(onClick = { confirmLeave = false }) { Text(labels.cancel) } },
        )
    }
}

@Composable
private fun SectionTitle(title: String) {
    val colors = flareColors()
    Spacer(Modifier.height(FlareSizes.spacingMd))
    Text(
        title, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
        modifier = Modifier.padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
    )
}

/** A small edit dialog: a kit [Input] with save / cancel. */
@Composable
private fun EditFieldDialog(
    title: String,
    initial: String,
    multiline: Boolean,
    placeholder: String,
    saveText: String,
    cancelText: String,
    onDismiss: () -> Unit,
    onSave: (String) -> Unit,
) {
    var value by remember { mutableStateOf(initial) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Input(value = value, onValueChange = { value = it }, placeholder = placeholder, multiline = multiline, maxLength = if (multiline) 200 else 30) },
        confirmButton = { TextButton(onClick = { onSave(value) }) { Text(saveText) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(cancelText) } },
    )
}

@Composable
private fun SecondaryBlockButton(text: String, block: Boolean = true, onClick: () -> Unit) {
    val colors = flareColors()
    OutlinedButton(
        onClick = onClick,
        shape = RoundedCornerShape(FlareSizes.radiusLg),
        colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.textPrimary),
        modifier = if (block) Modifier.fillMaxWidth() else Modifier,
    ) { Text(text) }
}

@Composable
private fun DangerBlockButton(text: String, onClick: () -> Unit) {
    val colors = flareColors()
    Button(
        onClick = onClick,
        shape = RoundedCornerShape(FlareSizes.radiusLg),
        colors = ButtonDefaults.buttonColors(containerColor = colors.error),
        modifier = Modifier.fillMaxWidth().height(48.dp),
    ) { Text(text, color = Color.White, fontSize = FlareSizes.fontSizeXl.value.sp) }
}
