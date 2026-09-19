package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

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
    /**
     * Viewer's per-group notification / pin preference; **null when the host could not read it** — the row
     * then reads as unavailable instead of a switch claiming "off" for a setting nobody knows (Vue
     * `FlareGroupDetailModel.myMuted`).
     */
    val myMuted: Boolean? = false,
    val myPinned: Boolean? = false,
    /** How people join; null when the host does not know — the row shows "not set" and nothing is preselected. */
    val joinPolicy: FlareGroupJoinPolicy? = null,
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
    /** Shown in place of a switch whose state could not be read; the copy lives in [FlareStrings]. */
    val settingUnavailable: String = FlareStrings().groupDetailSettingUnavailable,
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
)

/**
 * [FlareGroupDetail]'s labels from [strings] — the `groupDetail*` keys (plus the shared `back` / `cancel` /
 * `close` / `reject` / `sendMessage`), which is what [FlareGroupDetail] uses when the host passes none. The
 * data class's own defaults used to win, so a host that had translated the kit through [LocalFlareStrings]
 * still saw Chinese here.
 */
fun flareGroupDetailLabels(strings: FlareStrings): FlareGroupDetailLabels = FlareGroupDetailLabels(
    fallbackTitle = strings.groupDetailFallbackTitle,
    back = strings.back,
    unavailable = strings.groupDetailUnavailable,
    unavailableHint = strings.groupDetailUnavailableHint,
    notSet = strings.groupDetailNotSet,
    settingUnavailable = strings.groupDetailSettingUnavailable,
    infoSection = strings.groupDetailInfoSection,
    myInGroupSection = strings.groupDetailMyInGroupSection,
    manageSection = strings.groupDetailManageSection,
    permsSection = strings.groupDetailPermsSection,
    name = strings.groupDetailName,
    announcement = strings.groupDetailAnnouncement,
    members = strings.groupDetailMembers,
    myNickname = strings.groupDetailMyNickname,
    muteNotif = strings.groupDetailMuteNotif,
    pinGroup = strings.groupDetailPinGroup,
    joinMode = strings.groupDetailJoinMode,
    joinRequests = strings.groupDetailJoinRequests,
    muteAll = strings.groupDetailMuteAll,
    inviteLink = strings.groupDetailInviteLink,
    onlyAdminAtAll = strings.groupDetailOnlyAdminAtAll,
    onlyAdminPin = strings.groupDetailOnlyAdminPin,
    shareCard = strings.groupDetailShareCard,
    joinOpen = strings.groupDetailJoinOpen,
    joinApproval = strings.groupDetailJoinApproval,
    joinInvite = strings.groupDetailJoinInvite,
    message = strings.sendMessage,
    leave = strings.groupDetailLeave,
    dissolve = strings.groupDetailDissolve,
    editName = strings.groupDetailEditName,
    editAnnouncement = strings.groupDetailEditAnnouncement,
    nicknamePlaceholder = strings.groupDetailNicknamePlaceholder,
    save = strings.groupDetailSave,
    cancel = strings.cancel,
    memberManage = strings.groupDetailMemberManage,
    setAdmin = strings.groupDetailSetAdmin,
    unsetAdmin = strings.groupDetailUnsetAdmin,
    mute = strings.groupDetailMute,
    unmute = strings.groupDetailUnmute,
    transferOwner = strings.groupDetailTransferOwner,
    removeMember = strings.groupDetailRemoveMember,
    transferConfirmPrefix = strings.groupDetailTransferConfirmPrefix,
    transferConfirmSuffix = strings.groupDetailTransferConfirmSuffix,
    confirmTransfer = strings.groupDetailConfirmTransfer,
    invite = strings.groupDetailInvite,
    inviteSearchPlaceholder = strings.groupDetailInviteSearchPlaceholder,
    loading = strings.groupDetailLoading,
    noRequests = strings.groupDetailNoRequests,
    reject = strings.reject,
    approve = strings.groupDetailApprove,
    inviteLinkHint = strings.groupDetailInviteLinkHint,
    generating = strings.groupDetailGenerating,
    inviteCodeLabel = strings.groupDetailInviteCodeLabel,
    copyCode = strings.groupDetailCopyCode,
    cannotGenerate = strings.groupDetailCannotGenerate,
    close = strings.close,
)

/** 进群方式 label: the policy's choice label, or the not-set copy when the host does not know it. */
internal fun groupJoinPolicyLabel(policy: FlareGroupJoinPolicy?, labels: FlareGroupDetailLabels): String = when (policy) {
    FlareGroupJoinPolicy.Open -> labels.joinOpen
    FlareGroupJoinPolicy.Approval -> labels.joinApproval
    FlareGroupJoinPolicy.Invite -> labels.joinInvite
    null -> labels.notSet
}

/** Cells in the member preview grid, the add tile included: four rows of five (Vue `MEMBER_PREVIEW_CELLS`). */
internal const val GROUP_MEMBER_PREVIEW_CELLS = 20

/** The members the grid previews: the first 19 and the add tile when the viewer manages, otherwise the first 20. */
internal fun groupPreviewMembers(members: List<Contact>, canManage: Boolean): List<Contact> =
    members.take(if (canManage) GROUP_MEMBER_PREVIEW_CELLS - 1 else GROUP_MEMBER_PREVIEW_CELLS)

/** The members whose name contains [query] (case-insensitive); every member for a blank query. */
internal fun groupMembersMatching(members: List<Contact>, query: String): List<Contact> {
    val q = query.trim().lowercase()
    return if (q.isEmpty()) members else members.filter { it.name.lowercase().contains(q) }
}

/** Chooses the visible members while preserving the old local path when the host has no remote search. */
internal fun visibleGroupMembers(localMembers: List<Contact>, query: String, remoteMembers: List<Contact>?, remoteEnabled: Boolean): List<Contact> =
    if (remoteEnabled) remoteMembers ?: groupMembersMatching(localMembers, query) else groupMembersMatching(localMembers, query)

/** What a group detail editor changes: the group's name, its announcement, or the viewer's nickname in it. */
enum class FlareGroupDetailEditKind { Name, Announcement, Nickname }

/**
 * The prompt that edits [kind] of [model] (Vue `saveEdit`): it opens on the current value; a name cannot be saved
 * empty, while an announcement or a nickname can be cleared. Confirming runs [save] with the trimmed value while
 * the prompt is busy; a thrown error keeps the prompt open with the draft and the error's message.
 */
internal fun groupDetailEditPrompt(
    kind: FlareGroupDetailEditKind,
    model: FlareGroupDetailModel,
    labels: FlareGroupDetailLabels,
    save: suspend (String) -> Unit,
): FlarePromptOptions {
    val title = when (kind) {
        FlareGroupDetailEditKind.Name -> labels.editName
        FlareGroupDetailEditKind.Announcement -> labels.editAnnouncement
        FlareGroupDetailEditKind.Nickname -> labels.myNickname
    }
    return FlarePromptOptions(
        title = title,
        value = when (kind) {
            FlareGroupDetailEditKind.Name -> model.name
            FlareGroupDetailEditKind.Announcement -> model.announcement.orEmpty()
            FlareGroupDetailEditKind.Nickname -> model.myNickname.orEmpty()
        },
        placeholder = if (kind == FlareGroupDetailEditKind.Nickname) labels.nicknamePlaceholder else title,
        maxLength = when (kind) {
            FlareGroupDetailEditKind.Name -> 30
            FlareGroupDetailEditKind.Announcement -> 200
            FlareGroupDetailEditKind.Nickname -> 20
        },
        multiline = kind == FlareGroupDetailEditKind.Announcement,
        allowEmpty = kind != FlareGroupDetailEditKind.Name,
        confirmText = labels.save,
        cancelText = labels.cancel,
        submit = save,
    )
}

/**
 * Where a confirmed edit goes: the host's [submitEdit] when it passes one (awaited; a throw keeps the editor open),
 * otherwise the update callback of [kind], after which the editor closes.
 */
internal suspend fun groupDetailSaveEdit(
    kind: FlareGroupDetailEditKind,
    value: String,
    submitEdit: (suspend (FlareGroupDetailEditKind, String) -> Unit)?,
    onUpdateName: (String) -> Unit,
    onUpdateAnnouncement: (String) -> Unit,
    onUpdateMyNickname: (String) -> Unit,
) {
    if (submitEdit != null) return submitEdit(kind, value)
    when (kind) {
        FlareGroupDetailEditKind.Name -> onUpdateName(value)
        FlareGroupDetailEditKind.Announcement -> onUpdateAnnouncement(value)
        FlareGroupDetailEditKind.Nickname -> onUpdateMyNickname(value)
    }
}

/** The admin state the member's role action asks for — the one its label offers: admin unless already one. */
internal fun groupMemberAdminTarget(model: FlareGroupDetailModel, userId: String): Boolean = userId !in model.adminIds

/** The mute state the member's mute action asks for — the one its label offers: muted unless already muted. */
internal fun groupMemberMuteTarget(model: FlareGroupDetailModel, userId: String): Boolean = userId !in model.mutedIds

/**
 * Group detail / management — a full presentational screen: header, hero, member grid,
 * and Feishu-style settings (群信息 / 我在本群 / 群管理 / 群权限, owner-admin gated), plus the
 * member action sheet, join-request approval, invite picker and invite link. The grid previews the
 * first 20 cells (19 members and the add tile when the viewer manages); the 群成员 row opens a sheet of
 * every member with a search field, where choosing a member opens the same member actions. It owns its
 * editing dialogs / sheets and reuses the kit [GroupMemberGrid] and [SettingsRow]. Purely
 * presentational — NO SDK / session: it renders [model] and emits intents.
 *
 * The name, announcement and nickname rows open an editor on the current value. With [submitEdit] the editor waits
 * for the host's write: busy while it runs, open with the draft and the error when it throws, closed when it returns.
 * Without it the matching update callback fires and the editor closes, as before.
 *
 * Member intents carry the state the user asked for ([onPromoteMember] `admin`, [onMuteMember]
 * `muted`), read from [model] when the action is tapped. Removing a member and leaving /
 * dissolving are emitted as tapped: the host confirms them (e.g. with [DangerConfirm]) because it
 * owns the busy and error states of the write. [headerActions] fills the end of the header row.
 *
 * Two slots place host content on the page: [afterInfo] after the group information section and
 * [footer] after the message and leave buttons. Both scroll with the page and keep its horizontal
 * inset; nothing is drawn for a null slot. The message button is drawn only when [onOpenChat] is set.
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
    labels: FlareGroupDetailLabels = flareGroupDetailLabels(flareStrings()),
    /** Shows the back control, which system back also runs; null for an embedded pane with no way back. */
    onBack: (() -> Unit)? = null,
    /** Host controls at the end of the header row (e.g. an overflow menu). */
    headerActions: (@Composable RowScope.() -> Unit)? = null,
    /** Host content after the group information section (e.g. the announcement read bar). */
    afterInfo: (@Composable () -> Unit)? = null,
    /** Host content after the message and leave buttons (e.g. a report entry). */
    footer: (@Composable () -> Unit)? = null,
    /**
     * Opens a chat with the group's members; the message button is drawn only when this is set.
     * Carries the member ids and the group name so the host does not have to re-derive them;
     * Vue emits `openChat({ userIds, name })` and Flutter passes `(List<String>, String)` — this
     * matches them.
     */
    onOpenChat: ((List<String>, String) -> Unit)? = null,
    /** Awaits the host's write of an edit before the editor closes; a throw keeps the editor open with its draft and the error. */
    submitEdit: (suspend (kind: FlareGroupDetailEditKind, value: String) -> Unit)? = null,
    onUpdateName: (String) -> Unit = {},
    onUpdateAnnouncement: (String) -> Unit = {},
    onUpdateMyNickname: (String) -> Unit = {},
    /** Sets how people join; the join policy row opens its picker only when this is set. */
    onSetJoinPolicy: ((FlareGroupJoinPolicy) -> Unit)? = null,
    onToggleMuteAll: (Boolean) -> Unit = {},
    /** key ∈ {"onlyAdminCanAtAll", "onlyAdminCanPin", "shareCardPermission"}. */
    onSetFlag: (String, Boolean) -> Unit = { _, _ -> },
    onToggleMyMuted: (Boolean) -> Unit = {},
    onToggleMyPinned: (Boolean) -> Unit = {},
    onLoadJoinRequests: () -> Unit = {},
    onRespondRequest: (String, Boolean) -> Unit = { _, _ -> },
    onEnsureInviteLink: () -> Unit = {},
    /** `admin` true makes the member an admin, false revokes it; the action shows only with this callback. */
    onPromoteMember: ((userId: String, admin: Boolean) -> Unit)? = null,
    /** `muted` true mutes the member, false lifts it; the action shows only with this callback. */
    onMuteMember: ((userId: String, muted: Boolean) -> Unit)? = null,
    onTransferOwner: (String) -> Unit = {},
    onRemoveMember: (String) -> Unit = {},
    onLoadContacts: () -> Unit = {},
    onInviteMembers: (List<String>) -> Unit = {},
    /**
     * Optional host-backed member search. When set, the members sheet delegates non-empty queries
     * to the host (for `social.group.search_members`) instead of filtering the loaded preview/list.
     */
    onSearchMembers: (suspend (String) -> List<Contact>)? = null,
    onLeave: () -> Unit = {},
    /** 宿主自己的操作，画在「退出群聊」上方（FR-046）。 */
    extraActions: List<FlareDetailExtraAction> = emptyList(),
    onExtraAction: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    FlareNativeBackEffect(enabled = onBack != null) { onBack?.invoke() }

    // The name, announcement and nickname editors: the kit prompt presenter, owned by the page so it needs no host presenter.
    val editor = rememberFlareDialogState()
    val scope = rememberCoroutineScope()
    val latestSubmitEdit by rememberUpdatedState(submitEdit)
    val latestUpdateName by rememberUpdatedState(onUpdateName)
    val latestUpdateAnnouncement by rememberUpdatedState(onUpdateAnnouncement)
    val latestUpdateMyNickname by rememberUpdatedState(onUpdateMyNickname)
    fun edit(kind: FlareGroupDetailEditKind) {
        val current = model ?: return
        scope.launch {
            editor.prompt(groupDetailEditPrompt(kind, current, labels) { value ->
                groupDetailSaveEdit(kind, value, latestSubmitEdit, latestUpdateName, latestUpdateAnnouncement, latestUpdateMyNickname)
            })
        }
    }
    // Governance sheets / dialogs
    var joinModeOpen by remember { mutableStateOf(false) }
    var joinRequestsOpen by remember { mutableStateOf(false) }
    var inviteLinkOpen by remember { mutableStateOf(false) }
    var inviteMembersOpen by remember { mutableStateOf(false) }
    // Per-member management: selected member id
    var memberSheet by remember { mutableStateOf<String?>(null) }
    var membersOpen by remember { mutableStateOf(false) }
    var transferTarget by remember { mutableStateOf<String?>(null) }
    val memberSheetState = rememberModalBottomSheetState()

    Column(modifier.fillMaxSize().background(colors.bgSecondary)) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (onBack != null) {
                IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, labels.back, tint = colors.textPrimary) }
            } else {
                Spacer(Modifier.width(FlareSizes.spacingMd))
            }
            Text(
                model?.name ?: labels.fallbackTitle, color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSize3xl.value.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f),
            )
            headerActions?.invoke(this)
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
                members = groupPreviewMembers(m.members, m.canManage),
                total = m.memberCount,
                ownerId = m.ownerId,
                adminIds = m.adminIds,
                showAdd = m.canManage,
                onSelect = { id -> if (m.canManage && id != m.ownerId) memberSheet = id },
                onAddMember = { onLoadContacts(); inviteMembersOpen = true },
            )

            // Settings sections — each is one elevated grouped card (Feishu-style), the same
            // [FlareGroupedCard] the kit's SettingsList draws, so the two surfaces can't drift.

            // 群信息
            SectionTitle(labels.infoSection)
            FlareGroupedCard {
                SettingsRow(
                    // A row the viewer can change opens its editor and carries a chevron; the rest read as values.
                    item = SettingsItem("name", labels.name, icon = "tag", kind = if (m.canManage) FlareSettingKind.Navigation else FlareSettingKind.Value, detail = m.name.ifEmpty { "-" }),
                    onSelect = { if (m.canManage) edit(FlareGroupDetailEditKind.Name) },
                )
                FlareGroupedCardDivider()
                SettingsRow(
                    item = SettingsItem("announcement", labels.announcement, icon = "announcement", kind = if (m.canManage) FlareSettingKind.Navigation else FlareSettingKind.Value, detail = m.announcement?.ifEmpty { null } ?: labels.notSet),
                    onSelect = { if (m.canManage) edit(FlareGroupDetailEditKind.Announcement) },
                )
                FlareGroupedCardDivider()
                SettingsRow(
                    item = SettingsItem("members", labels.members, icon = "people", kind = FlareSettingKind.Navigation, detail = "${m.memberCount}"),
                    onSelect = { membersOpen = true },
                )
            }
            afterInfo?.let { slot ->
                Box(Modifier.fillMaxWidth().padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingSm)) {
                    slot()
                }
            }

            // 我在本群
            SectionTitle(labels.myInGroupSection)
            FlareGroupedCard {
                SettingsRow(
                    item = SettingsItem("myNickname", labels.myNickname, icon = "edit", kind = FlareSettingKind.Navigation, detail = m.myNickname?.ifEmpty { null } ?: labels.notSet),
                    onSelect = { edit(FlareGroupDetailEditKind.Nickname) },
                )
                FlareGroupedCardDivider()
                // A setting that could not be read claims neither state: it reads as unavailable.
                SettingsRow(
                    item = m.myMuted?.let { SettingsItem("myMuted", labels.muteNotif, icon = "mute", kind = FlareSettingKind.Toggle, value = it) }
                        ?: SettingsItem("myMuted", labels.muteNotif, icon = "mute", kind = FlareSettingKind.Value, detail = labels.settingUnavailable),
                    onToggle = { _, v -> onToggleMyMuted(v) },
                )
                FlareGroupedCardDivider()
                SettingsRow(
                    item = m.myPinned?.let { SettingsItem("myPinned", labels.pinGroup, icon = "pin", kind = FlareSettingKind.Toggle, value = it) }
                        ?: SettingsItem("myPinned", labels.pinGroup, icon = "pin", kind = FlareSettingKind.Value, detail = labels.settingUnavailable),
                    onToggle = { _, v -> onToggleMyPinned(v) },
                )
            }

            // 群管理 (owner/admin only)
            if (m.canManage) {
                SectionTitle(labels.manageSection)
                FlareGroupedCard {
                    SettingsRow(
                        item = SettingsItem("joinPolicy", labels.joinMode, icon = "lock", kind = if (onSetJoinPolicy != null) FlareSettingKind.Navigation else FlareSettingKind.Value, detail = groupJoinPolicyLabel(m.joinPolicy, labels)),
                        onSelect = if (onSetJoinPolicy != null) ({ joinModeOpen = true }) else null,
                    )
                    FlareGroupedCardDivider()
                    SettingsRow(
                        item = SettingsItem("joinRequests", labels.joinRequests, icon = "join-request", kind = FlareSettingKind.Navigation, detail = joinRequests.size.takeIf { it > 0 }?.toString()),
                        onSelect = { onLoadJoinRequests(); joinRequestsOpen = true },
                    )
                    FlareGroupedCardDivider()
                    SettingsRow(
                        item = SettingsItem("muteAll", labels.muteAll, icon = "silence", kind = FlareSettingKind.Toggle, value = m.muteAll),
                        onToggle = { _, v -> onToggleMuteAll(v) },
                    )
                    FlareGroupedCardDivider()
                    SettingsRow(
                        item = SettingsItem("inviteLink", labels.inviteLink, icon = "link", kind = FlareSettingKind.Navigation),
                        onSelect = { onEnsureInviteLink(); inviteLinkOpen = true },
                    )
                }

                // 群权限 (owner/admin only)
                SectionTitle(labels.permsSection)
                FlareGroupedCard {
                    SettingsRow(
                        item = SettingsItem("onlyAdminAtAll", labels.onlyAdminAtAll, icon = "mention", kind = FlareSettingKind.Toggle, value = m.onlyAdminCanAtAll),
                        onToggle = { _, v -> onSetFlag("onlyAdminCanAtAll", v) },
                    )
                    FlareGroupedCardDivider()
                    SettingsRow(
                        item = SettingsItem("onlyAdminPin", labels.onlyAdminPin, icon = "pin", kind = FlareSettingKind.Toggle, value = m.onlyAdminCanPin),
                        onToggle = { _, v -> onSetFlag("onlyAdminCanPin", v) },
                    )
                    FlareGroupedCardDivider()
                    SettingsRow(
                        item = SettingsItem("shareCard", labels.shareCard, icon = "share", kind = FlareSettingKind.Toggle, value = m.shareCardPermission),
                        onToggle = { _, v -> onSetFlag("shareCardPermission", v) },
                    )
                }
            }

            // Footer — 发消息 (only when the host opens chats) + 退出/解散, then the host footer slot
            Spacer(Modifier.height(FlareSizes.spacingLg))
            Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                onOpenChat?.let { openChat ->
                    Button(
                        label = labels.message,
                        size = FlareControlSize.Lg,
                        block = true,
                        onClick = { openChat(m.members.map { it.id }, m.name) },
                    )
                }
                for (action in extraActions) {
                    if (action.danger) {
                        DangerBlockButton(text = action.label, onClick = { onExtraAction?.invoke(action.id) })
                    } else {
                        Button(
                            label = action.label,
                            variant = FlareButtonVariant.Secondary,
                            size = FlareControlSize.Lg,
                            block = true,
                            onClick = { onExtraAction?.invoke(action.id) },
                        )
                    }
                }
                DangerBlockButton(text = if (m.isOwner) labels.dissolve else labels.leave, onClick = onLeave)
                footer?.invoke()
            }
        }
    }

    // ── Edit name / announcement / nickname ─────────────────────────────────────
    FlareDialogPresenter(editor)

    // ── All members ─────────────────────────────────────────────────────────────
    if (membersOpen && model != null) {
        val m = model
        val strings = flareStrings()
        var query by remember { mutableStateOf("") }
        var remoteMembers by remember(m.groupId) { mutableStateOf<List<Contact>?>(null) }
        var searchingMembers by remember { mutableStateOf(false) }
        var memberSearchError by remember { mutableStateOf<String?>(null) }
        LaunchedEffect(query, onSearchMembers, m.members) {
            val search = onSearchMembers
            val trimmed = query.trim()
            memberSearchError = null
            if (search == null || trimmed.isEmpty()) {
                remoteMembers = null
                searchingMembers = false
                return@LaunchedEffect
            }
            delay(250)
            searchingMembers = true
            runCatching { search(trimmed) }
                .onSuccess { remoteMembers = it }
                .onFailure { remoteMembers = emptyList(); memberSearchError = it.message ?: strings.groupDetailNoMatchingMembers }
            searchingMembers = false
        }
        val matching = remember(m.members, query, remoteMembers, onSearchMembers) {
            visibleGroupMembers(m.members, query, remoteMembers, onSearchMembers != null)
        }
        BottomSheet(onClose = { membersOpen = false }, title = strings.groupDetailMembersTitle(m.memberCount)) {
            Box(Modifier.padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm)) {
                SearchBar(value = query, onValueChange = { query = it }, placeholder = strings.groupDetailSearchMembers, loading = searchingMembers)
            }
            if (memberSearchError != null) {
                Text(
                    memberSearchError ?: strings.groupDetailNoMatchingMembers, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = Modifier.fillMaxWidth().padding(FlareSizes.spacing2xl),
                )
            } else if (matching.isEmpty()) {
                Text(
                    strings.groupDetailNoMatchingMembers, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = Modifier.fillMaxWidth().padding(FlareSizes.spacing2xl),
                )
            } else {
                Box(Modifier.weight(1f, fill = false)) {
                    ContactList(
                        items = matching,
                        indexed = false,
                        // The same member actions as the grid: managers act on anyone but the owner.
                        onSelect = if (m.canManage) ({ member -> if (member.id != m.ownerId) { membersOpen = false; memberSheet = member.id } }) else null,
                    )
                }
            }
        }
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
                onPromoteMember?.let { promote ->
                    SecondaryBlockButton(text = if (isAdmin) labels.unsetAdmin else labels.setAdmin) {
                        memberSheet = null
                        promote(selected, groupMemberAdminTarget(m, selected))
                    }
                }
                onMuteMember?.let { mute ->
                    SecondaryBlockButton(text = if (isMuted) labels.unmute else labels.mute) {
                        memberSheet = null
                        mute(selected, groupMemberMuteTarget(m, selected))
                    }
                }
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
            confirmButton = { TextButton(onClick = { transferTarget = null; onTransferOwner(target) }) { Text(labels.confirmTransfer, color = colors.errorText) } },
            dismissButton = { TextButton(onClick = { transferTarget = null }) { Text(labels.cancel) } },
        )
    }

    // ── Join policy ─────────────────────────────────────────────────────────────
    val setJoinPolicy = onSetJoinPolicy
    if (joinModeOpen && model != null && setJoinPolicy != null) {
        // An unknown policy opens with nothing selected; saving waits for a choice.
        var draft by remember(model.joinPolicy) { mutableStateOf(model.joinPolicy) }
        AlertDialog(
            onDismissRequest = { joinModeOpen = false },
            title = { Text(labels.joinMode) },
            text = {
                RadioGroup(
                    options = FlareGroupJoinPolicy.entries.map { FlareSelectOption(it.name, groupJoinPolicyLabel(it, labels)) },
                    value = draft?.name.orEmpty(), vertical = true,
                    onSelect = { name -> draft = FlareGroupJoinPolicy.entries.firstOrNull { it.name == name } },
                )
            },
            confirmButton = {
                TextButton(
                    enabled = draft != null,
                    onClick = { draft?.let { policy -> joinModeOpen = false; setJoinPolicy(policy) } },
                ) { Text(labels.save) }
            },
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
                            Button(label = labels.approve, onClick = { onRespondRequest(req.requestId, true) })
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
