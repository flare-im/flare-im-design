// Curated, richer usage scenarios per component, merged into the generated
// docs by name. Kept out of the spec (which stays contract-only) and out of
// JSON (template literals avoid escaping). Add freely.
//
// Avoid `${` inside the code strings (would interpolate); use plain values.

export const curatedExamples = {
  Avatar: [
    {
      title: { en: "Size & presence", zh: "尺寸与在线状态" },
      description: { en: "The avatar derives its fallback color from userId and its initials from displayName; presence shows a bottom-right dot.", zh: "头像自动从 userId 生成兜底底色，displayName 生成首字母；presence 显示右下角圆点。" },
      vue: `<FlareAvatar user-id="u1" display-name="Henry Ford" :size="48" presence="online" />`,
      flutter: `FlareAvatar(userId: 'u1', displayName: 'Henry Ford', size: 48, presence: FlarePresence.online)`,
      ios: `AvatarView(userId: "u1", displayName: "Henry Ford", size: 48, presence: .online)`,
      compose: `Avatar(userId = "u1", displayName = "Henry Ford", size = 48.dp, presence = FlarePresence.Online)`,
    },
  ],

  MessageList: [
    {
      title: { en: "Wiring up a timeline", zh: "接入一个会话时间线" },
      description: { en: "messages come from core's timeline view; long-press actions, media taps and resend are handled by the host — the component only renders and virtualises.", zh: "messages 来自 core 的时间线视图；长按弹出操作、点击媒体、失败重发都由宿主处理，组件只做展示与虚拟化。" },
      vue: `<FlareMessageList
  :messages="messages"
  :current-user-id="me.id"
  conversation-kind="group"
  @message-long-press="showActions"
  @media-action="openMedia"
  @resend="resend"
/>`,
      flutter: `FlareMessageList(
  messages: timeline,                 // List<FlareMessageData>
  currentUserId: me.id,
  conversationKind: FlareConversationKind.group,
  mediaDownloadStates: mediaStates,
  onMessageLongPress: showActions,
  onMediaAction: (m, content) => openMedia(content),
  onResend: (m) => resend(m.id),
)`,
      ios: `MessageListView(
  messages: timeline,
  currentUserId: me.id,
  conversationKind: .group,
  onMessageLongPress: showActions,
  onResend: resend
)`,
      compose: `MessageList(
  messages = timeline,
  currentUserId = me.id,
  conversationKind = FlareConversationKind.Group,
  onMessageLongPress = ::showActions,
  onResend = ::resend,
)`,
    },
  ],

  MessageContentView: [
    {
      title: { en: "Each type is its own component", zh: "每个类型都是独立组件" },
      description: { en: "MessageContentView just dispatches by type — but every per-type body is exported as a standalone component with clean props, so you can drop any single one into your own layout.", zh: "MessageContentView 只按类型分派 —— 但每种消息体都作为独立组件导出（props 简洁），你可以把任意一个单独放进自己的布局里自由组合。" },
      vue: `<!-- use any single message body on its own -->
<FlareFileMessage name="设计规范 v2.pdf" size="2.4 MB" ext="PDF" />
<FlareVoteMessage title="周会时间投票" :options="[{ text: '周四 15:00', pct: 62 }]" />
<FlareLocationMessage title="三里屯" address="北京市朝阳区" />

<!-- or let the dispatcher pick by content.type -->
<FlareMessageContentView :content="message.content" :self="isSelf" />`,
      flutter: `// each body is a widget; the dispatcher picks by type
FlareFileMessage(name: '设计规范 v2.pdf', size: '2.4 MB', ext: 'PDF');
FlareVoteMessage(title: '周会时间投票', options: options);
// or:
FlareMessageContentView(content: message.content, self: isSelf);`,
      ios: `FileMessageView(name: "设计规范 v2.pdf", size: "2.4 MB", ext: "PDF")
VoteMessageView(title: "周会时间投票", options: options)
// or: MessageContentView(content: message.content, isSelf: isSelf)`,
      compose: `FileMessage(name = "设计规范 v2.pdf", size = "2.4 MB", ext = "PDF")
VoteMessage(title = "周会时间投票", options = options)
// or: MessageContentView(content = message.content, self = isSelf)`,
    },
    {
      title: { en: "Registering a custom content type", zh: "注册自定义内容类型" },
      description: { en: "17 content types are built in; register your own (vote/task/…) in the content registry and MessageBubble / MessageContentView dispatch to it automatically.", zh: "内建 17 种内容类型；产品把 vote / task 等注册到内容注册表，MessageBubble 与 MessageContentView 会自动分派。" },
      vue: `registerContentType("vote", VotePanel);`,
      flutter: `FlareContentRegistry.register("vote", (ctx, content, c) => VotePanel(content));`,
      ios: `FlareContentRegistry.register("vote") { content, ctx in AnyView(VotePanel(content)) }`,
      compose: `FlareContentRegistry.register("vote") { content, ctx -> VotePanel(content) }`,
    },
  ],

  VoteMessage: [
    {
      title: { en: "Options as { text, pct }", zh: "选项即 { text, pct }" },
      description: { en: "Each option is a text label and a percentage; the bar width tracks pct. The option type is `FlareVoteOption` on every platform.", zh: "每个选项是文案 + 百分比，进度条宽度跟随 pct。选项类型在各端都是 `FlareVoteOption`。" },
      vue: `<FlareVoteMessage
  title="周会时间投票"
  :options="[{ text: '周四 15:00', pct: 62 }, { text: '周五 10:00', pct: 38 }]"
/>`,
      flutter: `FlareVoteMessage(
  title: '周会时间投票',
  options: const [
    FlareVoteOption('周四 15:00', 62),
    FlareVoteOption('周五 10:00', 38),
  ],
)`,
      ios: `VoteMessageView(title: "周会时间投票", options: [
  FlareVoteOption("周四 15:00", 62),
  FlareVoteOption("周五 10:00", 38),
])`,
      compose: `VoteMessage(
  title = "周会时间投票",
  options = listOf(
    FlareVoteOption("周四 15:00", 62),
    FlareVoteOption("周五 10:00", 38),
  ),
)`,
    },
  ],

  Composer: [
    {
      title: { en: "Optimistic send + reply", zh: "乐观发送 + 回复" },
      description: { en: "onSend fires immediately (local echo next frame, < 16 ms); the host writes to core asynchronously. replyTo shows the reply strip.", zh: "onSend 立即触发（下一帧本地回显，< 16ms），宿主再异步写入 core；replyTo 显示回复条。" },
      vue: `<FlareComposer :rich="false" :reply-to="replyTo" @send="sendOptimistic" @attach="openSheet" @cancel-reply="clearReply" />`,
      flutter: `FlareComposer(
  rich: false,
  replyTo: replyTo,
  onSend: (text) => sendOptimistic(text),
  onAttach: () => FlareMessageActionSheet.show(context),
)`,
      ios: `ComposerView(rich: false, replyTo: replyTo) { text in sendOptimistic(text) }`,
      compose: `Composer(rich = false, replyTo = replyTo, onSend = ::sendOptimistic)`,
    },
    {
      title: { en: "Voice + action panel (complete, ready to use)", zh: "语音 + 下方功能区（完整可直接用）" },
      description: { en: "enableVoice adds the hold-to-talk toggle; passing actions makes + expand an inline action grid (image/file/card/vote/…) that resolves through onAction. The host just wires the voice/action callbacks.", zh: "开启 enableVoice 显示「按住说话」切换；传 actions 时「＋」展开内联功能区网格（图片/文件/名片/投票…），选择回 onAction。宿主拿到语音/动作回调即可。" },
      vue: `<!-- Vue 完整 composer 见 FlareComposer；语音/功能区为独立可组合 parts -->
<FlareVoiceHoldButton @start="startRec" @end="sendVoice" @cancel="cancelRec" />
<FlareComposerActionPanel @action="build($event.key)" />`,
      flutter: `FlareComposer(
  enableVoice: true,
  actions: FlareMessageActionSheet.defaultActions,   // 下方功能区
  onSend: sendOptimistic,
  onAction: (a) => build(a.key),
  onVoiceStart: startRec, onVoiceEnd: sendVoice, onVoiceCancel: cancelRec,
)`,
      ios: `ComposerView(
  enableVoice: true,
  actions: MessageActionSheetView.defaultActions,
  onSend: sendOptimistic,
  onAction: { build($0.id) },
  onVoiceStart: startRec, onVoiceEnd: sendVoice
)`,
      compose: `Composer(
  enableVoice = true,
  actions = defaultComposerActions,
  onSend = ::sendOptimistic,
  onAction = { build(it.key) },
  onVoiceStart = ::startRec, onVoiceEnd = ::sendVoice,
)`,
    },
    {
      title: { en: "Free composition: build your own composer", zh: "自由组合：用 parts 自己拼输入栏" },
      description: { en: "Every part is exported on its own — voice button, icon button, send button, reply strip, action panel — so you can assemble a composer to fit your product instead of using the complete default.", zh: "所有小组件都单独导出——语音按钮、图标按钮、发送按钮、回复条、下方功能区——产品可自由组合出自己的输入栏，而不用完整默认装配。" },
      vue: `<FlareComposerActionPanel :actions="myActions" @action="pick" />
<FlareVoiceHoldButton @end="sendVoice" />`,
      flutter: `Row(children: [
  FlareComposerIconButton(icon: Icons.mic_none_rounded, onTap: toggleVoice),
  Expanded(child: myTextField),
  FlareComposerSendButton(active: canSend, onTap: send),
]);
// 需要时展开：FlareComposerActionPanel(actions: myActions, onAction: pick)`,
      ios: `HStack {
  FlareComposerActionPanel(actions: myActions) { pick($0) }
}
FlareVoiceHoldButton(onEnd: sendVoice)`,
      compose: `Row {
  FlareVoiceHoldButton(onEnd = ::sendVoice)
}
FlareComposerActionPanel(actions = myActions, onAction = ::pick)`,
    },
  ],

  ConversationList: [
    {
      title: { en: "The inbox", zh: "收件箱" },
      description: { en: "items come from client.views.openConversationList(), reordering and updating unread live; the active conversation is highlighted.", zh: "items 来自 client.views.openConversationList()，实时重排与未读更新；活动会话高亮。" },
      vue: `<FlareConversationList :items="rows" :active-id="openId" @select="open" @long-press="rowMenu" />`,
      flutter: `FlareConversationList(items: rows, activeId: openId, onSelect: (r) => open(r.id), onLongPress: rowMenu)`,
      ios: `ConversationListView(items: rows, activeId: openId) { row in open(row.id) }`,
      compose: `ConversationList(items = rows, activeId = openId, onSelect = { open(it.id) })`,
    },
  ],

  ContactList: [
    {
      title: { en: "Address book (A–Z index)", zh: "通讯录（A-Z 索引）" },
      description: { en: "Grouped by pinyin/letter with a tappable side index; an empty list shows a placeholder automatically.", zh: "按拼音/字母分组，侧边索引条点击跳转；空列表自动显示占位。" },
      vue: `<FlareContactList :items="contacts" indexed @select="openContact" />`,
      flutter: `FlareContactList(items: contacts, indexed: true, onSelect: openContact)`,
      ios: `ContactListView(items: contacts, indexed: true) { openContact($0) }`,
      compose: `ContactList(items = contacts, indexed = true, onSelect = ::openContact)`,
    },
  ],

  CallView: [
    {
      title: { en: "In an active call", zh: "音视频通话中" },
      description: { en: "The video surface is host-injected (video slot / AnyView / videoContent); the control bar is built in and driven by RTC session state and duration.", zh: "视频画面由宿主注入（video 插槽 / AnyView / videoContent）；控制条内建，状态与时长由 RTC 会话驱动。" },
      vue: `<FlareCallView peer-name="Henry" mode="video" state="connected" duration-label="02:14" @hangup="hangup" @toggle-mute="toggleMute">
  <template #video><RtcRenderer :track="remoteTrack" /></template>
</FlareCallView>`,
      flutter: `FlareCallView(
  peerName: 'Henry', mode: FlareCallMode.video, state: FlareCallState.connected,
  durationLabel: '02:14', videoContent: RtcRenderer(track: remoteTrack),
  onHangup: hangup, onToggleMute: toggleMute,
)`,
      ios: `CallView(peerName: "Henry", mode: .video, state: .connected, durationLabel: "02:14",
        video: AnyView(RtcRenderer(track: remoteTrack)), onHangup: hangup)`,
      compose: `CallView(peerName = "Henry", mode = FlareCallMode.Video, state = FlareCallState.Connected,
     durationLabel = "02:14", videoContent = { RtcRenderer(remoteTrack) }, onHangup = ::hangup)`,
    },
  ],

  ProfilePanel: [
    {
      title: { en: "Personal center", zh: "个人中心" },
      description: { en: "Avatar / name / Flare ID + entry list (entries are customizable); tap the header to edit.", zh: "头像/名称/Flare ID + 入口列表（可自定义 entries）；点头部进编辑。" },
      vue: `<FlareProfilePanel :user="me" @edit="editProfile" @action="openEntry" />`,
      flutter: `FlareProfilePanel(user: me, onEdit: editProfile, onEntry: openEntry)`,
      ios: `ProfilePanelView(user: me, onEdit: editProfile, onEntry: openEntry)`,
      compose: `ProfilePanel(user = me, onEdit = ::editProfile, onEntry = ::openEntry)`,
    },
  ],

  Input: [
    {
      title: { en: "Multi-line + length limit", zh: "多行 + 字数限制" },
      description: { en: "A general input: single/multi-line, a maxLength counter, and one-tap clearable.", zh: "通用输入框：单/多行、maxLength 计数、clearable 一键清除。" },
      vue: `<FlareInput v-model="text" placeholder="介绍一下自己" multiline :max-length="60" />`,
      flutter: `FlareInput(controller: controller, placeholder: '介绍一下自己', multiline: true, maxLength: 60)`,
      ios: `InputView(text: $text, placeholder: "介绍一下自己", multiline: true, maxLength: 60)`,
      compose: `Input(value = text, onValueChange = { text = it }, placeholder = "介绍一下自己", multiline = true, maxLength = 60)`,
    },
  ],

  ResponsiveLayout: [
    {
      title: { en: "Responsive three-pane", zh: "自适应三栏" },
      description: { en: "Three columns on desktop (list+chat+detail), two on tablet, one on mobile — switching by activePane with a back affordance.", zh: "PC 三栏（列表+聊天+详情），平板双栏，手机单栏按 activePane 切换并显示返回。" },
      vue: `<FlareResponsiveLayout :has-detail="true" :active-pane="pane" @pane-change="p => pane = p">
  <template #list><FlareConversationList :items="rows" /></template>
  <template #chat><FlareMessageList v-bind="thread" /></template>
  <template #detail><FlareConversationDetails :conversation="conv" /></template>
</FlareResponsiveLayout>`,
      flutter: `FlareResponsiveLayout(
  activePane: pane,
  onPaneChange: (p) => setState(() => pane = p),
  list: FlareConversationList(items: rows),
  chat: FlareMessageList(messages: timeline, currentUserId: me.id),
  detail: FlareConversationDetails(conversation: conv),
)`,
      ios: `ResponsiveLayoutView(
  activePane: pane, onPaneChange: { pane = $0 },
  list: AnyView(ConversationListView(items: rows)),
  chat: AnyView(MessageListView(messages: timeline, currentUserId: me.id)),
  detail: AnyView(ConversationDetailsView(conversation: conv))
)`,
      compose: `ResponsiveLayout(
  activePane = pane,
  onPaneChange = { pane = it },
  list = { ConversationList(items = rows) },
  chat = { MessageList(messages = timeline, currentUserId = me.id) },
  detail = { ConversationDetails(conversation = conv) },
)`,
    },
  ],
};
