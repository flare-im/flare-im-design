// Curated, richer usage scenarios per component, merged into the generated
// docs by name. Kept out of the spec (which stays contract-only) and out of
// JSON (template literals avoid escaping). Add freely.
//
// Avoid `${` inside the code strings (would interpolate); use plain values.

export const curatedExamples = {

  InviteCodeField: [
    {
      title: { en: "Registration form, host-run pre-check", zh: "注册表单，宿主执行预检" },
      description: { en: "The tenant's invite mode decides whether the field exists. The field normalizes input and emits `check` once for a complete code; the host runs the request and feeds `checking` / `checkResult` back. A stale result is cleared by the host when the code changes.", zh: "租户邀请模式决定字段是否存在。字段归一化输入，码完整后只触发一次 `check`；宿主发请求并把 `checking` / `checkResult` 回填。码变化时宿主清掉旧结果。" },
      vue: `<FlareInviteCodeField
  v-model="inviteCode"
  :mode="features.inviteMode"
  :prefill="route.query.code"
  :checking="checking"
  :check-result="checkResult"
  :error="errors.inviteCode"
  @update:model-value="checkResult = null"
  @check="preCheck"
/>`,
      flutter: `FlareInviteCodeField(
  controller: inviteCode,
  mode: features.inviteMode,
  prefill: deepLinkCode,
  checking: checking,
  checkResult: checkResult,
  error: errors.inviteCode,
  onChanged: (_) => setState(() => checkResult = null),
  onCheck: preCheck,
)`,
      compose: `InviteCodeField(
  value = inviteCode,
  onValueChange = { inviteCode = it; checkResult = null },
  mode = features.inviteMode,
  prefill = deepLinkCode,
  checking = checking,
  checkResult = checkResult,
  error = errors.inviteCode,
  onCheck = ::preCheck,
)`,
      ios: `InviteCodeFieldView(
  text: $inviteCode,
  mode: features.inviteMode,
  prefill: deepLinkCode,
  checking: checking,
  checkResult: checkResult,
  error: errors.inviteCode,
  onCheck: preCheck
)`,
    },
  ],

  MyInvitePanel: [
    {
      title: { en: "My invite page", zh: "「我的邀请」页" },
      description: { en: "The host fetched the code, the share link, the referral stats and a keyset page of invitees; copy / share / regenerate / loadMore are intents it performs. `maxDepthShown` and `showProfiles` come from the tenant's referral visibility.", zh: "宿主取回码、分享链接、推荐统计与一页下级；copy / share / regenerate / loadMore 都是宿主执行的意图。`maxDepthShown` 与 `showProfiles` 来自租户的推荐可见性配置。" },
      vue: `<FlareMyInvitePanel
  :code="invite.code"
  :share-url="invite.shareUrl"
  :stats="stats"
  :max-depth-shown="visibility.depth"
  :invitees="invitees"
  :show-profiles="visibility.showProfiles"
  :has-more="hasMore"
  :can-regenerate="invite.canRegenerate"
  :regenerate-available-at="invite.regenerateAvailableAt"
  @copy="copyToClipboard"
  @share="openShareSheet"
  @regenerate="regenerate"
  @load-more="loadMore"
  @select="openProfile"
/>`,
      flutter: `FlareMyInvitePanel(
  code: invite.code,
  shareUrl: invite.shareUrl,
  stats: stats,
  maxDepthShown: visibility.depth,
  invitees: invitees,
  showProfiles: visibility.showProfiles,
  hasMore: hasMore,
  canRegenerate: invite.canRegenerate,
  regenerateAvailableAt: invite.regenerateAvailableAt,
  onCopy: copyToClipboard,
  onShare: openShareSheet,
  onRegenerate: regenerate,
  onLoadMore: loadMore,
  onSelect: openProfile,
)`,
      compose: `MyInvitePanel(
  code = invite.code,
  shareUrl = invite.shareUrl,
  stats = stats,
  maxDepthShown = visibility.depth,
  invitees = invitees,
  showProfiles = visibility.showProfiles,
  hasMore = hasMore,
  canRegenerate = invite.canRegenerate,
  regenerateAvailableAt = invite.regenerateAvailableAt,
  onCopy = ::copyToClipboard,
  onShare = ::openShareSheet,
  onRegenerate = ::regenerate,
  onLoadMore = ::loadMore,
  onSelect = ::openProfile,
)`,
      ios: `MyInvitePanelView(
  code: invite.code,
  shareURL: invite.shareURL,
  stats: stats,
  maxDepthShown: visibility.depth,
  invitees: invitees,
  showProfiles: visibility.showProfiles,
  hasMore: hasMore,
  canRegenerate: invite.canRegenerate,
  regenerateAvailableAt: invite.regenerateAvailableAt,
  onCopy: copyToClipboard,
  onShare: openShareSheet,
  onRegenerate: regenerate,
  onLoadMore: loadMore,
  onSelect: openProfile
)`,
    },
  ],
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

  ConversationHeader: [
    {
      title: { en: "Basic", zh: "基础" },
      description: { en: "Identity alone gives a useful header. The host receives semantic action intents and keeps all SDK work outside the component.", zh: "只传身份即可得到可用头部；宿主接收语义动作意图，所有 SDK 工作都留在组件之外。" },
      vue: `<FlareConversationHeader
  :identity="{ id: 'ivy', title: 'Ivy Chen', kind: 'direct', presence: 'online' }"
  @action="handleHeaderAction"
/>`,
      flutter: `FlareConversationHeader(
  identity: const FlareConversationIdentity(
    id: 'ivy', title: 'Ivy Chen', presence: FlarePresence.online,
  ),
  onAction: handleHeaderAction,
)`,
      compose: `ConversationHeader(
  identity = ConversationIdentity(
    id = "ivy", title = "Ivy Chen", presence = FlarePresence.Online,
  ),
  onAction = ::handleHeaderAction,
)`,
      ios: `ConversationHeaderView(
  identity: ConversationIdentity(
    id: "ivy", title: "Ivy Chen", presence: .online
  ),
  onAction: handleHeaderAction
)`,
    },
    {
      title: { en: "Direct Chat", zh: "单聊" },
      description: { en: "The direct preset shows the peer avatar and a single secondary status line, then resolves search/calls/share/details through capabilities.", zh: "单聊预设显示对方头像和一行次级状态，再通过 capabilities 解析搜索、通话、分享和详情。" },
    },
    {
      title: { en: "Group Chat", zh: "群聊" },
      description: { en: "The group preset accepts a host group avatar and member count, and adds member/share intents to the dedicated Plus menu.", zh: "群聊预设接收宿主群头像和成员数，并把添加成员/分享意图放入独立 Plus 菜单。" },
    },
    {
      title: { en: "Custom Actions", zh: "自定义动作" },
      description: { en: "Host actions merge by stable id, so a product can add a primary action without rebuilding the header.", zh: "宿主动作按稳定 id 合并，产品无需重建头部即可增加主动作。" },
    },
    {
      title: { en: "Custom Plus Menu", zh: "自定义 Plus 菜单" },
      description: { en: "Add Member, Create Task, and Order share one SDK-agnostic action model. Groups, ordering, disabled reasons, and intents remain host configuration.", zh: "添加成员、创建任务和订单共用一个 SDK 无关动作模型；分组、顺序、禁用原因和 intent 都由宿主配置。" },
      vue: `<FlareConversationHeader
  :identity="groupIdentity"
  :actions="[
    { id: 'task', label: 'Create task', icon: 'check', placement: 'add', group: 'work', order: 60 },
    { id: 'order', label: 'Order', icon: 'bookmark', placement: 'add', group: 'work', order: 70, intent: 'order.create' },
  ]"
  @action="dispatchIntent"
/>`,
      flutter: `FlareConversationHeader(
  identity: groupIdentity,
  actions: const [
    FlareConversationHeaderAction(
      id: 'task', label: 'Create task', icon: 'task',
      placement: FlareConversationHeaderActionPlacement.add, order: 60,
    ),
    FlareConversationHeaderAction(
      id: 'order', label: 'Order', icon: 'order',
      placement: FlareConversationHeaderActionPlacement.add,
      order: 70, intent: 'order.create',
    ),
  ],
  onAction: dispatchIntent,
)`,
      compose: `ConversationHeader(
  identity = groupIdentity,
  actions = listOf(
    ConversationHeaderAction(
      id = "task", label = "Create task", icon = "task",
      placement = ConversationHeaderActionPlacement.Add, order = 60,
    ),
    ConversationHeaderAction(
      id = "order", label = "Order", icon = "order",
      placement = ConversationHeaderActionPlacement.Add,
      order = 70, intent = "order.create",
    ),
  ),
  onAction = ::dispatchIntent,
)`,
      ios: `ConversationHeaderView(
  identity: groupIdentity,
  actions: [
    ConversationHeaderAction(
      id: "task", label: "Create task", icon: "checkmark",
      placement: .add, order: 60
    ),
    ConversationHeaderAction(
      id: "order", label: "Order", icon: "shippingbox",
      placement: .add, order: 70, intent: "order.create"
    ),
  ],
  onAction: dispatchIntent
)`,
    },
    {
      title: { en: "Minimal Header", zh: "极简头部" },
      description: { en: "replaceDefaults plus an empty action list leaves identity and back navigation only.", zh: "replaceDefaults 配合空动作列表，仅保留身份和返回导航。" },
    },
    {
      title: { en: "Read Only / Limited Capabilities", zh: "只读 / 有限能力" },
      description: { en: "Capability filtering removes unavailable actions; enabled=false retains a visible action with a localized disabled reason.", zh: "能力过滤移除不可用动作；enabled=false 则保留可见动作并提供本地化禁用原因。" },
    },
  ],

  ChatWorkspace: [
    {
      title: { en: "Complete active-chat surface", zh: "完整当前聊天表面" },
      description: { en: "Context is optional and outside the header. Timeline is the only flexible scrolling region; the composer remains attached to the bottom safe area.", zh: "Context 可选且位于 Header 外；Timeline 是唯一弹性滚动区域，Composer 贴合底部安全区。" },
      vue: `<FlareChatWorkspace label="Product room">
  <template #context><FlareStatusBanner v-bind="connection" /></template>
  <template #header><FlareConversationHeader :identity="identity" @action="act" /></template>
  <template #timeline><FlareMessageTimeline v-bind="timeline" /></template>
  <template #composer><FlareComposer v-model="draft" @send="send" /></template>
</FlareChatWorkspace>`,
      flutter: `FlareChatWorkspace(
  contextBanner: FlareStatusBanner(message: connectionText),
  header: FlareConversationHeader(identity: identity, onAction: act),
  timeline: FlareMessageList(messages: messages, currentUserId: me.id),
  composer: FlareComposer(controller: draft, onSend: send),
)`,
      compose: `ChatWorkspace(
  contextBanner = { StatusBanner(message = connectionText) },
  header = { ConversationHeader(identity = identity, onAction = ::act) },
  timeline = { MessageList(messages = messages, currentUserId = me.id) },
  composer = { Composer(onSend = ::send) },
)`,
      ios: `ChatWorkspaceView {
  ConversationHeaderView(identity: identity, onAction: act)
} context: {
  StatusBannerView(message: connectionText)
} timeline: {
  MessageListView(messages: messages, currentUserId: me.id)
} composer: {
  ComposerView(text: $draft, onSend: send)
}`,
    },
    {
      title: { en: "Without Context", zh: "无 Context" },
      description: { en: "Normal conversations omit the context region entirely; no blank band or placeholder remains.", zh: "普通会话可完全省略 Context 区域，不留下空白带或占位。" },
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
    { title: { en: "Direct Chat", zh: "单聊" }, description: { en: "Incoming identity is supplied by the conversation context; repeated sender labels stay hidden.", zh: "接收方身份由会话上下文提供，不重复显示发送者名称。" } },
    { title: { en: "Group Chat", zh: "群聊" }, description: { en: "The first incoming row in a run shows sender identity; outgoing rows remain compact by default.", zh: "连续消息组的首条接收消息显示发送者身份；发送方默认保持紧凑。" } },
    { title: { en: "Grouped Messages", zh: "连续消息" }, description: { en: "Sender, five-minute gap, message type, and system boundaries derive single/first/middle/last once in the timeline.", zh: "时间线统一根据发送者、五分钟间隔、消息类型和系统边界计算 single/first/middle/last。" } },
    { title: { en: "Reaction", zh: "Reaction" }, description: { en: "Reactions remain visually attached to their bubble with a quieter selected surface and count hierarchy.", zh: "Reaction 通过更克制的选中表面和数量层级依附于所属气泡。" } },
    { title: { en: "Failed", zh: "失败" }, description: { en: "A failed outgoing message keeps its place and exposes retry without changing the timeline geometry.", zh: "失败的发送消息保留原位并提供重试，不改变时间线几何。" } },
    { title: { en: "Long Content", zh: "长内容" }, description: { en: "Long text wraps inside the bubble max width while the timeline column remains constrained on large desktops.", zh: "长文本在气泡最大宽度内换行，时间线列在大桌面上保持约束。" } },
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
      title: { en: "Default", zh: "默认" },
      description: { en: "A draft binding and send callback are enough. The calm default toolbar keeps Emoji, Plus, and Send visible; Plus opens Image, Video, File, Voice, Contact card, and Poll.", zh: "只需草稿绑定和发送回调即可使用；克制的默认工具栏常驻表情、Plus 与发送，Plus 打开图片、视频、文件、语音、名片和投票。" },
      vue: "<FlareComposer v-model=\"draft\" @send=\"sendMessage\" @build=\"handleAction\" />",
      flutter: "FlareComposer(controller: controller, onSend: sendMessage, onAction: handleAction)",
      compose: "Composer(onSend = ::sendMessage, onAction = ::handleAction)",
      ios: "ComposerView(text: $draft, onSend: sendMessage, onAction: handleAction)",
    },
    {
      title: { en: "Expanded shortcuts", zh: "扩展快捷栏" },
      description: { en: "Choose the expanded presentation only when direct mention, voice, image, rich-text, and resize shortcuts are genuinely frequent.", zh: "仅在提及、语音、图片、富文本与扩展确属高频能力时选择 expanded 呈现。" },
      vue: "<FlareComposer v-model=\"draft\" toolbar-presentation=\"expanded\" @send=\"sendMessage\" />",
    },
    {
      title: { en: "Custom Actions", zh: "自定义动作" },
      description: { en: "An explicit actions list fully replaces defaults and may provide custom icons, labels, groups, badges, and intents.", zh: "显式 actions 列表完整替换默认值，并可提供自定义图标、文案、分组、badge 和 intent。" },
    },
    {
      title: { en: "Hide Actions", zh: "隐藏动作" },
      description: { en: "Set visible to false for temporary policy filtering, or omit the item to remove it permanently.", zh: "临时策略过滤使用 visible=false；永久移除则不把该项放入宿主列表。" },
    },
    {
      title: { en: "Reorder Actions", zh: "动作重排" },
      description: { en: "Use order for stable product priority; equal values retain host list order.", zh: "使用 order 表达稳定业务优先级；相同值保持宿主数组顺序。" },
    },
    {
      title: { en: "Disabled Action", zh: "禁用动作" },
      description: { en: "enabled=false keeps context visible and exposes disabledReason to assistive technology.", zh: "enabled=false 保留上下文，并把 disabledReason 暴露给辅助技术。" },
    },
    {
      title: { en: "Custom Business Action", zh: "自定义业务动作" },
      description: { en: "Order is a host ID and intent. The component library does not know or execute the business flow.", zh: "Order 只是宿主 ID 和 intent；组件库不认识也不执行业务流程。" },
    },
    {
      title: { en: "Reply", zh: "回复" },
      description: { en: "replyTo adds a compact preview strip and cancel intent without changing send ownership.", zh: "replyTo 增加紧凑预览条和取消意图，不改变发送状态归属。" },
    },
    {
      title: { en: "Editing", zh: "编辑" },
      description: { en: "Editing state preserves the draft and makes the active task explicit.", zh: "编辑状态保留草稿，并明确当前任务。" },
    },
    {
      title: { en: "Offline", zh: "离线" },
      description: { en: "The draft remains editable while send is blocked and recovery guidance stays visible.", zh: "草稿保持可编辑，发送被阻断，同时显示恢复说明。" },
    },
    {
      title: { en: "Uploading", zh: "上传中" },
      description: { en: "Transfer progress is composed above the input without locking unrelated conversation actions.", zh: "传输进度组合在输入区上方，不锁死无关会话操作。" },
    },
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
  FlareComposerIconButton(icon: 'mic', label: FlareStrings.of(context).composerVoiceInput, onTap: toggleVoice),
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

  MetricTile: [
    {
      title: { en: "A row of dashboard numbers", zh: "仪表盘上的一排数字" },
      description: { en: "One tile per number, in a grid. The host passes the reading and the change since the last period, and says which direction is good news; a reading that was not collected is `null`, never 0.", zh: "一个数字一张卡，放进网格。宿主传读数和与上期相比的变化，并说明哪个方向是好消息；没采集到的读数传 `null`，不要传 0。" },
      vue: `<div class="overview">
  <FlareMetricTile :label="t('users.total')" :value="stats.users" :caption="quotaText" :delta="stats.usersDeltaPct" delta-unit="%" polarity="higher-is-better" />
  <FlareMetricTile :label="t('users.frozen')" :value="stats.frozen" :delta="stats.frozenDelta" polarity="lower-is-better" />
  <FlareMetricTile :label="t('messages.today')" :value="stats.messagesToday ?? null" :loading="pending" compact />
</div>`,
    },
  ],

  DataTable: [
    {
      title: { en: "A server-paged list with selection and a column chooser", zh: "服务端分页的列表，带多选与列设置" },
      description: { en: "The host owns the page: it fetches on every `update:pagination` / `update:sort`, passes the rows of that page back, keeps the selection across pages and persists the chosen columns. Cells render through `cell-<key>` slots; `batch` sits in the toolbar that appears with a selection.", zh: "页由宿主持有：每次 `update:pagination` / `update:sort` 都去取数，把那一页的行传回来，跨页保留选中项，并持久化选中的列。单元格用 `cell-<key>` 插槽渲染；`batch` 放进选中后出现的工具条。" },
      vue: `<FlareDataTable
  :label="t('users.title')"
  :columns="columns"
  :rows="page.rows"
  :loading="pending"
  :pagination="page.pagination"
  :sort="query.sort"
  selectable
  column-chooser
  v-model:selected-keys="selected"
  v-model:visible-columns="prefs.userColumns"
  @update:pagination="(next) => load({ ...query, page: next.page, pageSize: next.pageSize })"
  @update:sort="(sort) => load({ ...query, sort, page: 1 })"
  @row-click="(row) => router.push({ name: 'user', params: { id: row.id } })"
>
  <template #toolbar><FlareSearchBar v-model="keyword" @search="load" /></template>
  <template #cell-status="{ value }">{{ t(\`users.status.\${value}\`) }}</template>
  <template #row-actions="{ row }"><FlareButton variant="text" size="sm" :label="t('users.edit')" @click="edit(row)" /></template>
  <template #batch="{ selectedKeys, clear }"><FlareButton variant="danger" size="sm" :label="t('users.freeze')" @click="freeze(selectedKeys).then(clear)" /></template>
</FlareDataTable>`,
    },
    {
      title: { en: "A cursor-paged source that cannot count", zh: "游标分页、无法计数的数据源" },
      description: { en: "Leave out `total` and pass the server's `has_more` as `hasNext`. The table asks for page n ± 1; the host keeps the cursor of every page it visited, so going back needs no second query plan.", zh: "不传 `total`，把服务端的 `has_more` 作为 `hasNext`。表格只会请求第 n ± 1 页；宿主记住访问过的每一页的游标，返回上一页无需另一套查询。" },
      vue: `<FlareDataTable
  :label="t('messages.title')"
  :columns="columns"
  :rows="page.messages"
  :loading="pending"
  :pagination="{ page: cursors.length + 1, pageSize: 20, hasNext: page.has_more }"
  @update:pagination="(next) => (next.page > cursors.length + 1 ? forward(page.next_cursor) : back())"
/>`,
    },
  ],

  FilterBar: [
    {
      title: { en: "The query bar of a message search", zh: "消息检索的查询栏" },
      description: { en: "Every value lives in the host; the bar reports `search` (the key, or Enter in a one-line field) and `reset`. Rarely used conditions go in `more`; `moreActiveCount` tells the person how many of them hold a value while they are folded.", zh: "所有字段值都在宿主里；查询栏只上报 `search`（按键，或在单行文本框里回车）与 `reset`。不常用的条件放进 `more`；收起时 `moreActiveCount` 告诉对方其中几项已填。" },
      vue: `<FlareFilterBar
  :hint="t('messages.hint')"
  :loading="pending"
  :more-active-count="[query.senderId, query.channelId].filter(Boolean).length"
  v-model:expanded="moreOpen"
  @search="runSearch"
  @reset="resetQuery"
>
  <FlareFormField :label="t('messages.conversation')"><FlareInput v-model="query.conversationId" monospace clearable /></FlareFormField>
  <FlareFormField :label="t('messages.messageId')"><FlareInput v-model="query.messageId" monospace clearable /></FlareFormField>
  <template #more>
    <FlareFormField :label="t('messages.sender')"><FlareInput v-model="query.senderId" monospace clearable /></FlareFormField>
    <FlareFormField :label="t('messages.channel')"><FlareInput v-model="query.channelId" monospace clearable /></FlareFormField>
  </template>
  <template #actions><FlareButton variant="secondary" :label="t('common.export')" @click="exportRows" /></template>
</FlareFilterBar>`,
    },
  ],

  DescriptionList: [
    {
      title: { en: "A message's facts in a detail drawer", zh: "详情抽屉里一条消息的各项事实" },
      description: { en: "The host formats each value (dates, enums) and leaves an unknown one empty — the list says \"not set\". Identifiers copy; the host toasts the result. A line that is more than text renders through its `item-<key>` slot.", zh: "宿主格式化每个值（日期、枚举），未知的留空 —— 列表会显示「未设置」。标识符可复制，结果提示由宿主给。不只是文字的行用 `item-<key>` 插槽渲染。" },
      vue: `<FlareDrawer :open="Boolean(detail)" :title="t('messages.detail')" width="min(760px, 100vw)" @close="detail = null">
  <FlareDescriptionList
    :items="[
      { key: 'serverId', label: t('messages.serverId'), value: detail.server_id, monospace: true, copyable: true },
      { key: 'conversation', label: t('messages.conversation'), value: detail.conversation_id, monospace: true, copyable: true },
      { key: 'seq', label: t('messages.seq'), value: detail.conversation_seq },
      { key: 'sender', label: t('messages.sender'), value: detail.sender_name },
      { key: 'kind', label: t('messages.kind'), value: detail.content_kind },
      { key: 'createdAt', label: t('messages.createdAt'), value: dateTime(detail.created_at) },
    ]"
    @copy="(key, copied) => toast(copied ? t('common.copied') : t('common.copyFailed'))"
  >
    <template #item-kind="{ value }"><FlareTag :label="String(value)" /></template>
  </FlareDescriptionList>
</FlareDrawer>`,
    },
  ],

  CodeBlock: [
    {
      title: { en: "A raw payload, and the quick-start snippet", zh: "原始报文，以及快速开始代码" },
      description: { en: "The host formats the text and decides what may be shown; the block keeps it exactly as written, scrolls inside its own box and copies the whole text.", zh: "文本由宿主格式化，能展示什么也由宿主决定；代码块原样保留文本、在自己的框里滚动，并复制全文。" },
      vue: `<FlareCodeBlock language="JSON" :code="JSON.stringify(detail, null, 2)" @copy="(copied) => toast(copied ? t('common.copied') : t('common.copyFailed'))" />
<FlareCodeBlock language="TypeScript" :label="t('quickStart.init')" :code="initSnippet" wrap />`,
    },
  ],

  Tag: [
    {
      title: { en: "A status the host maps to a tone", zh: "宿主把状态映射成色调" },
      description: { en: "The words carry the meaning; the tone only repeats it. Map each server state to one tone in the host, and keep identifiers in the monospaced face.", zh: "含义由文字承载，色调只是重复它。在宿主里把每个服务端状态映射到一个色调；标识符用等宽字体。" },
      vue: `<FlareTag :label="t('users.status.' + user.status)" :tone="{ active: 'success', frozen: 'danger', pending: 'warning' }[user.status] ?? 'neutral'" />
<FlareTag :label="t('apps.online')" tone="success" dot />
<FlareTag :label="app.version" monospace />`,
    },
  ],

  DangerConfirm: [
    {
      title: { en: "A recorded console write: audit reason and typed name", zh: "被审计的控制台写操作：审计原因与输入名称" },
      description: { en: "`reason` holds the confirm key until a reason is given (within the server's UTF-8 limit); `confirmPhrase` until the target's code is typed. The presenter hands the reason to `action` and keeps it if the write fails.", zh: "`reason` 在填好原因（不超过服务端的 UTF-8 上限）之前锁住确认键；`confirmPhrase` 在输入目标代码之前锁住确认键。呈现器把原因交给 `action`，写入失败时保留已填内容。" },
      vue: `const confirm = useFlareConfirm();
await confirm({
  title: t('apps.delete.title'),
  description: t('apps.delete.consequence'),
  target: app.name,
  confirmText: t('apps.delete.action'),
  reason: { label: t('audit.reason'), placeholder: t('audit.reasonPlaceholder'), maxBytes: 512 },
  confirmPhrase: app.code,
  action: ({ reason }) => deleteApp(app.id, { auditReason: reason }),
});`,
    },
  ],

  PermissionTree: [
    {
      title: { en: "Editing a role's permissions", zh: "编辑一个角色的权限" },
      description: { en: "The catalogue comes from the host; the model is the leaf codes only — parents are derived — so what the tree holds is exactly what the role grants. Codes the current person may not grant are `disabledCodes`; a viewer gets `readonly`.", zh: "权限目录来自宿主；模型只有叶子权限码（父节点推导），树里的就是角色真正授予的。当前人无权授予的权限码放 `disabledCodes`；只读查看传 `readonly`。" },
      vue: `<FlarePermissionTree
  :label="t('roles.permissions')"
  :nodes="catalogue"
  v-model:checked-codes="draft.permissions"
  :disabled-codes="notGrantable"
  :readonly="!canEdit"
/>`,
    },
  ],

  ChartCard: [
    {
      title: { en: "Daily usage, bars or a line", zh: "每日用量，柱状或折线" },
      description: { en: "Map the host's rows to `{ label, value }` (format the dates yourself; a day that failed to collect is `null`, a gap). Controls go in `extra`, a note in `footer`; the plot's height is `--flare-chart-card-plot-height`.", zh: "把宿主的数据行映射成 `{ label, value }`（日期自己格式化；采集失败的那天传 `null`，画成缺口）。控件放 `extra`，说明放 `footer`；图表高度用 `--flare-chart-card-plot-height` 调。" },
      vue: `<FlareChartCard
  :title="t('usage.newUsers')"
  :description="t('usage.lastDays', { days: 30 })"
  :points="usage.series.map((row) => ({ label: shortDate(row.day), value: row.new_users }))"
  :kind="kind"
  :loading="pending"
>
  <template #extra><FlareSegmentedControl v-model="kindIndex" :options="kindLabels" /></template>
  <template #footer>{{ t('usage.collectedAt') }} {{ collectedAt }}</template>
</FlareChartCard>`,
    },
  ],
};
