package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

// Android Studio canvas demos for every com.flare.im.ui component — the Android
// equivalent of the web docs demos. Each renders the REAL composable with mock data.

private fun demoMsg(id: String, name: String, text: String, self: Boolean = false,
                    status: FlareMessageDeliveryStatus = FlareMessageDeliveryStatus.Read) =
    FlareMessageData(id = id, senderId = if (self) "me" else id, senderName = name,
        content = FlareTextContent(text), timeLabel = "14:30", status = status)

@Preview(showBackground = true)
@Composable
private fun AvatarPreview() = Row(Modifier.padding(12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
    Avatar(userId = "u1", displayName = "Ivy Chen", presence = FlarePresence.Online)
    Avatar(userId = "u2", displayName = "Henry Ford", presence = FlarePresence.Busy)
    Avatar(userId = "u3", displayName = "Kai")
}

@Preview(showBackground = true)
@Composable
private fun DatePillPreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
    DatePill("今天"); DatePill("昨天"); DatePill("7月15日", floating = true)
}

@Preview(showBackground = true)
@Composable
private fun MessageStatusPreview() = Row(Modifier.padding(12.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
    MessageStatus(FlareMessageDeliveryStatus.Pending)
    MessageStatus(FlareMessageDeliveryStatus.Sending)
    MessageStatus(FlareMessageDeliveryStatus.Sent)
    MessageStatus(FlareMessageDeliveryStatus.Delivered)
    MessageStatus(FlareMessageDeliveryStatus.Read)
    MessageStatus(FlareMessageDeliveryStatus.Failed)
    MessageStatus(FlareMessageDeliveryStatus.Retrying)
}

@Preview(showBackground = true)
@Composable
private fun MessageMetaPreview() = MessageMeta(
    timestamp = "14:32",
    edited = true,
    status = FlareMessageDeliveryStatus.Read,
    ephemeral = FlareMessageEphemeralState.BurnAfterRead,
    modifier = Modifier.padding(12.dp),
)

@Preview(showBackground = true)
@Composable
private fun EmptyStatePreview() =
    EmptyState(title = "还没有会话", description = "发起一个聊天，或从通讯录里找人开始对话。", actionText = "发起聊天")

@Preview(showBackground = true)
@Composable
private fun SearchBarPreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
    SearchBar(value = "", onValueChange = {}, placeholder = "搜索联系人、群组、消息")
    SearchBar(value = "", onValueChange = {}, placeholder = "搜索联系人、群组、消息", readOnly = true, onActivate = {})
}

@Preview(showBackground = true)
@Composable
private fun InputPreview() = Input(value = "Flare IM 组件库", onValueChange = {}, placeholder = "请输入…", maxLength = 40, clearable = true)

@Preview(showBackground = true)
@Composable
private fun MarkdownPreviewPreview() =
    MarkdownPreview(content = "## 新版设计稿\n\n- **加粗** / *斜体* / `代码`\n- [链接](https://flare.im)", showStats = true)

@Preview(showBackground = true)
@Composable
private fun ConversationRowPreview() = Column(Modifier.padding(12.dp)) {
    ConversationRow(ConversationRowData(id = "c1", title = "Ivy Chen", preview = "好的，那明天上午同步一下 👍", timestampLabel = "14:32", unreadCount = 3, pinned = true, tags = listOf(ConversationRowTag("Official", FlareTagTone.Warning))))
    ConversationRow(ConversationRowData(id = "c2", title = "设计评审组", preview = "Kai: 新稿已上传", timestampLabel = "13:05", tags = listOf(ConversationRowTag("Group", FlareTagTone.Info))))
}

@Preview(showBackground = true)
@Composable
private fun ConversationListPreview() = ConversationList(items = listOf(
    ConversationRowData(id = "c1", title = "Ivy Chen", preview = "好的 👍", timestampLabel = "14:32", unreadCount = 3, pinned = true),
    ConversationRowData(id = "c2", title = "设计评审组", preview = "Kai: 新稿已上传", timestampLabel = "13:05"),
), activeId = "c1")

@Preview(showBackground = true)
@Composable
private fun ConversationDetailsPreview() = ConversationDetails(
    conversation = FlareConversationSummary(id = "c1", title = "设计评审组", kind = FlareConversationKind.Group, memberCount = 12),
    connectionText = "已连接", connectionTone = FlareConnectionTone.Ok, messageCount = 128)

@Preview(showBackground = true)
@Composable
private fun ContactItemPreview() = Column(Modifier.padding(12.dp)) {
    ContactItem(Contact(id = "u1", name = "Henry Ford", signature = "Keep it simple.", presence = FlarePresence.Online))
    ContactItem(Contact(id = "u2", name = "Ivy Chen", signature = "设计即沟通", presence = FlarePresence.Busy))
    ContactItem(Contact(id = "u3", name = "Kai", signature = "已选中"), selectable = true, selected = true, onToggleSelect = {})
    ContactItem(Contact(id = "u4", name = "Luna"), showPresence = false, trailing = { Button(label = "移出", size = FlareControlSize.Sm, onClick = {}) })
}

@Preview(showBackground = true)
@Composable
private fun ContactListPreview() = ContactList(items = listOf(
    Contact(id = "u1", name = "Henry Ford", presence = FlarePresence.Online),
    Contact(id = "u2", name = "Ivy Chen", presence = FlarePresence.Busy),
    Contact(id = "u3", name = "Kai"),
))

@Preview(showBackground = true)
@Composable
private fun ContactDetailPreview() = ContactDetail(Contact(id = "u2", name = "Ivy Chen", signature = "设计即沟通", presence = FlarePresence.Online))

@Preview(showBackground = true)
@Composable
private fun GroupListPreview() = GroupList(items = listOf(
    GroupSummary(id = "g1", name = "设计评审组", memberCount = 12),
    GroupSummary(id = "g2", name = "Flare 前端", memberCount = 34),
))

@Preview(showBackground = true)
@Composable
private fun NewFriendRequestsPreview() = NewFriendRequests(items = listOf(
    FriendRequest(id = "r1", name = "Ivy Chen", message = "一起做设计～"),
    FriendRequest(id = "r2", name = "Kai", message = "加个好友"),
    FriendRequest(id = "r3", name = "Luna", message = "你好", direction = FriendRequestDirection.Outgoing),
), onAccept = {}, onReject = {}, onWithdraw = {})

@Preview(showBackground = true)
@Composable
private fun ProfilePanelPreview() = ProfilePanel(user = UserProfile(id = "me", name = "Ivy Chen", signature = "设计即沟通", flareId = "ivy_chen"))

@Preview(showBackground = true)
@Composable
private fun ProfileEditorPreview() = ProfileEditor(user = UserProfile(id = "me", name = "Ivy Chen", signature = "设计即沟通", flareId = "ivy_chen"))

@Preview(showBackground = true)
@Composable
private fun SettingsListPreview() = SettingsList(sections = listOf(
    SettingsSection(title = "通用", items = listOf(
        SettingsItem(key = "notify", label = "新消息通知", kind = FlareSettingKind.Toggle, value = true),
        SettingsItem(key = "lang", label = "语言", detail = "简体中文"),
    )),
))

@Preview(showBackground = true)
@Composable
private fun TextMessagePreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
    MessageBubble(message = demoMsg("text-out", "Me", "收到，我下午过一遍给你反馈 👍", self = true), currentUserId = "me")
    MessageBubble(message = demoMsg("text-in", "Ivy Chen", "新版设计稿已经上传啦，帮忙看下～"), currentUserId = "me")
}

@Preview(showBackground = true)
@Composable
private fun MessageBodiesPreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
    ImageMessage(alt = "示例图片")
    VideoMessage()
    VoiceMessage(seconds = 12)
    FileMessage(name = "设计规范.pdf", size = "2.4 MB", ext = "pdf")
    LocationMessage(title = "深圳湾科技生态园", address = "科技南路 · 3 栋")
    ContactMessage(name = "Ivy Chen", subtitle = "设计师")
    LinkCardMessage(title = "Flare IM Design", domain = "flare.im", description = "一套契约，四端原生实现")
    TaskMessage(title = "提交本周周报", meta = "周五 18:00")
    VoteMessage(title = "周会时间", options = listOf(FlareVoteOption("周三上午", 60), FlareVoteOption("周四下午", 40)))
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) { StickerMessage(); EmojiMessage() }
    SystemMessage(text = "Ivy 加入了群聊")
}

@Preview(showBackground = true)
@Composable
private fun MessageBubblePreview() = Column(Modifier.padding(12.dp)) {
    MessageBubble(message = demoMsg("2", "Ivy Chen", "新版设计稿已经上传啦，帮忙看下～"), currentUserId = "me", conversationKind = FlareConversationKind.Group)
    MessageBubble(message = demoMsg("3", "Me", "收到，我下午过一遍给你反馈 👍", self = true), currentUserId = "me", conversationKind = FlareConversationKind.Group)
    MessageBubble(
        message = demoMsg("4", "Me", "好的，重点看会话列表", self = true)
            .copy(replyTo = FlareReplyTarget("Ivy Chen", "新版设计稿已经上传啦，帮忙看下～", messageId = "2")),
        currentUserId = "me", conversationKind = FlareConversationKind.Group, onLocateMessage = {},
    )
}

@Preview(showBackground = true)
@Composable
private fun MessageListPreview() = MessageList(messages = listOf(
    demoMsg("1", "Ivy Chen", "新版设计稿已经上传啦～"),
    demoMsg("2", "Me", "收到，下午看", self = true),
    demoMsg("3", "Ivy Chen", "辛苦～重点看会话列表"),
), currentUserId = "me", conversationKind = FlareConversationKind.Group)

@Preview(showBackground = true)
@Composable
private fun PinnedMessageBarPreview() = PinnedMessageBar(items = listOf(FlarePinnedMessage(id = "1", summary = "周五 15:00 设计评审", senderName = "Ivy Chen")))

@Preview(showBackground = true)
@Composable
private fun ComposerPartsPreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
    FlareVoiceHoldButton()
    FlareComposerActionPanel()
    FlareComposerSendButton(active = true)
    FlareComposerReplyStrip(senderName = "Ivy Chen", summary = "新版设计稿已经上传啦")
}

@Preview(showBackground = true)
@Composable
private fun ComposerPreview() = Composer(placeholder = "发送给 Ivy Chen")

@Preview(showBackground = true)
@Composable
private fun RichMarkdownInputPreview() = RichMarkdownInput(value = "支持 **加粗** / *斜体* / 链接", onValueChange = {})

@Preview(showBackground = true)
@Composable
private fun MessageActionSheetPreview() = MessageActionSheet()

@Preview(showBackground = true)
@Composable
private fun ConversationHeaderPreview() = ConversationHeader(
    identity = ConversationIdentity(id = "u2", title = "Ivy Chen", subtitle = "在线", presence = FlarePresence.Online,
        action = ConversationHeaderAction("details", "会话详情")),
    configuration = ConversationHeaderConfiguration(replaceDefaults = true),
    actions = listOf(ConversationHeaderAction("mute", "免打扰", pressed = true)),
    showBack = true, onBack = {}, onAction = {},
)

@Preview(showBackground = true)
@Composable
private fun CallPreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
    CallControls(cameraOn = true, mode = FlareCallMode.Video)
    IncomingCall(callerName = "Ivy Chen", mode = FlareCallMode.Video)
}

@Preview(showBackground = true)
@Composable
private fun CallViewPreview() = CallView(peerName = "Ivy Chen", mode = FlareCallMode.Video, state = FlareCallState.Connected, durationLabel = "03:24")

@Preview(showBackground = true)
@Composable
private fun ResponsiveLayoutPreview() = ResponsiveLayout(list = { Text("会话列表") }, chat = { Text("聊天窗口") })

@Preview(showBackground = true)
@Composable
private fun ScreenHeaderPreview() = ScreenHeader(title = "消息")

@Preview(showBackground = true)
@Composable
private fun BlockButtonPreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
    Button(label = "登录", size = FlareControlSize.Lg, block = true, onClick = {})
    Button(label = "连接中…", size = FlareControlSize.Lg, block = true, loading = true, onClick = {})
}

@Preview(showBackground = true)
@Composable
private fun SegmentedControlPreview() =
    SegmentedControl(options = listOf("联系人", "群组", "新的联系人"), selectedIndex = 0, onSelect = {},
        modifier = Modifier.padding(12.dp))

@Preview(showBackground = true)
@Composable
private fun FormControlsPreview() {
    var text by remember { mutableStateOf("这一刻的想法…") }
    var qty by remember { mutableStateOf(2) }
    var vol by remember { mutableStateOf(40f) }
    var stars by remember { mutableStateOf(3) }
    var sel by remember { mutableStateOf("a") }
    var time by remember { mutableStateOf("09:30") }
    var date by remember { mutableStateOf("2026-07-16") }
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Textarea(value = text, showCount = true, maxlength = 120, maxRows = 6, onChange = { text = it })
        Stepper(value = qty, min = 0, max = 9, onChange = { qty = it })
        Slider(value = vol, showValue = true, onChange = { vol = it })
        Rating(value = stars, clearable = true, onChange = { stars = it })
        Select(
            options = listOf(FlareSelectOption("a", "选项 A"), FlareSelectOption("b", "选项 B")),
            value = sel, placeholder = "请选择", onChange = { sel = it },
        )
        TimePicker(value = time, placeholder = "选择时间", title = "选择时间", onChange = { time = it })
        DatePicker(value = date, placeholder = "选择日期", title = "选择日期", onChange = { date = it })
    }
}

@Preview(showBackground = true)
@Composable
private fun StatusBannerPreview() = Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
    StatusBanner(text = "已连接", tone = FlareStatusTone.Success)
    StatusBanner(text = "正在同步…", tone = FlareStatusTone.Info, pulse = true)
    StatusBanner(text = "连接已断开", tone = FlareStatusTone.Danger, actionText = "重试", onAction = {})
    StatusBanner(text = "离线草稿", tone = FlareStatusTone.Neutral, dot = false)
}

@Preview(showBackground = true)
@Composable
private fun FilterTabsPreview() {
    var selected by remember { mutableStateOf("all") }
    FilterTabs(
        options = listOf(
            FlareFilterTabOption("all", "全部"),
            FlareFilterTabOption("unread", "未读", badge = 8),
            FlareFilterTabOption("groups", "群聊"),
            FlareFilterTabOption("at", "@我", badge = 2),
        ),
        selected = selected,
        onSelect = { selected = it },
    )
}

@Preview(showBackground = true, widthDp = 700, heightDp = 620)
@Composable
private fun CommandPalettePreview() {
    var query by remember { mutableStateOf("") }
    var selected by remember { mutableStateOf("new-message") }
    CommandPalette(
        open = true,
        query = query,
        groups = listOf(
            FlareCommandPaletteGroup(
                id = "workspace",
                label = "工作区",
                commands = listOf(
                    FlareCommandPaletteCommand("new-message", "发起新会话", "选择联系人或群组", shortcut = "Ctrl+N"),
                    FlareCommandPaletteCommand("search", "搜索消息", "在当前工作区中查找", shortcut = "Ctrl+F"),
                    FlareCommandPaletteCommand("settings", "打开设置", shortcut = "Ctrl+,"),
                ),
            ),
        ),
        label = "工作区命令",
        placeholder = "搜索命令",
        emptyText = "没有匹配的命令",
        selectedId = selected,
        onQueryChange = { query = it },
        onSelectedIdChange = { selected = it },
        onInvoke = {},
        onClose = {},
    )
}
