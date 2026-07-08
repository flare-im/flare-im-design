#!/usr/bin/env node
// One-shot migration: turn components.json into a bilingual (en/zh) source.
//  - summary / dataSource / notes  →  { en, zh }
//  - every prop gains  description: { en, zh }
// The CONTENT map below is the authored source for every string. The script
// asserts full coverage (every component, every prop) and refuses to write a
// partial result — so a spec that grows a prop without a description fails here.
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const specPath = join(here, "components.json");
const spec = JSON.parse(readFileSync(specPath, "utf8"));

// Category labels (used by the generator's locale dictionary too).
const CATEGORIES = {
  General: { en: "General", zh: "通用" },
  Conversation: { en: "Conversation", zh: "会话" },
  Message: { en: "Message", zh: "消息" },
  Composer: { en: "Composer", zh: "输入" },
  Media: { en: "Media", zh: "媒体" },
  Contacts: { en: "Contacts", zh: "通讯录" },
  Profile: { en: "Profile", zh: "个人中心" },
  Call: { en: "Call", zh: "音视频通话" },
  Layout: { en: "Layout", zh: "布局" },
};

const CONTENT = {
  Avatar: {
    summary: {
      en: "User or group avatar — image, initials fallback, optional presence dot.",
      zh: "用户 / 群组头像 —— 图片、首字母兜底、可选在线状态点。",
    },
    dataSource: {
      en: "identity fields from the conversation/message view (displayName, avatarUrl); presence from client.views presence",
      zh: "取会话 / 消息视图的身份字段（displayName、avatarUrl）；在线状态来自 client.views 的 presence",
    },
    props: {
      userId: { en: "Stable id, used to derive the fallback color when no image loads.", zh: "稳定 id，无图片时据此派生兜底底色。" },
      displayName: { en: "Name to render; its initials become the fallback.", zh: "展示名；其首字母作为兜底。" },
      avatarUrl: { en: "Image URL; on load failure it falls back to initials.", zh: "头像图 URL；加载失败回退到首字母。" },
      size: { en: "Diameter in px.", zh: "直径（px）。" },
      presence: { en: "Presence ring/dot; omit to hide.", zh: "在线状态圈点；不传则隐藏。" },
    },
  },
  TimeStamp: {
    summary: {
      en: "Relative/absolute time label for a message or conversation row.",
      zh: "消息或会话行的相对 / 绝对时间标签。",
    },
    dataSource: {
      en: "message.createdAt / conversation.lastMessageAt from the view",
      zh: "取视图的 message.createdAt / conversation.lastMessageAt",
    },
    props: {
      label: { en: "Preformatted time string; formatting lives in core so all platforms agree.", zh: "已格式化的时间串；格式化在 core 完成，各端一致。" },
    },
  },
  MessageStatus: {
    summary: {
      en: "Delivery status indicator — sending spinner, sent/read ticks, failed with retry.",
      zh: "送达状态指示 —— 发送中转圈、已发送 / 已读勾、失败可重试。",
    },
    dataSource: {
      en: "message.status from the timeline view (optimistic, reconciled by send-ack)",
      zh: "取时间线视图的 message.status（乐观显示，由 send-ack 校正）",
    },
    props: {
      status: { en: "Current delivery state; drives icon and color.", zh: "当前送达态；决定图标与颜色。" },
      variant: { en: "`tick` shows ticks; `compact` shows a minimal dot.", zh: "`tick` 显示勾；`compact` 显示极简圆点。" },
    },
  },
  ConversationList: {
    summary: {
      en: "The inbox — virtualised rows of conversations (avatar, title, preview, unread, timestamp).",
      zh: "会话收件箱 —— 虚拟化的会话行（头像、标题、预览、未读、时间）。",
    },
    dataSource: {
      en: "client.views.openConversationList(); one observable list, reorders + updates unread live",
      zh: "client.views.openConversationList()；一份可观察列表，实时重排并更新未读",
    },
    notes: {
      en: "Must virtualise (native list per platform); O(visible), no full re-layout on update.",
      zh: "必须虚拟化（各端用原生列表）；O(visible)，更新不整表重排。",
    },
    props: {
      items: { en: "Ordered conversation rows from the view.", zh: "视图给出的有序会话行。" },
      activeId: { en: "Currently open conversation, highlighted in the list.", zh: "当前打开的会话，在列表中高亮。" },
      loading: { en: "Shows a skeleton/spinner while the first page loads.", zh: "首屏加载时显示骨架 / 转圈。" },
    },
  },
  ConversationRow: {
    summary: {
      en: "A single inbox row — avatar, title, last-message/draft preview, unread badge, time, mute/pin markers.",
      zh: "单个会话行 —— 头像、标题、末条 / 草稿预览、未读角标、时间、免打扰 / 置顶标记。",
    },
    dataSource: {
      en: "one ConversationRow item from the conversation-list view",
      zh: "会话列表视图里的一条 ConversationRow",
    },
    props: {
      item: { en: "The row's data (title, preview, unread, time, flags).", zh: "该行数据（标题、预览、未读、时间、标记）。" },
      active: { en: "Renders the selected/open state.", zh: "渲染选中 / 打开态。" },
      draftPreview: { en: "Unsent draft text; shown in place of the last message.", zh: "未发送的草稿文本；替代末条消息显示。" },
    },
  },
  ConversationDetails: {
    summary: {
      en: "The conversation info/settings panel — counts, connection state, and per-conversation actions (mute/pin/archive/clear/delete/sync).",
      zh: "会话信息 / 设置面板 —— 统计、连接状态，以及单会话操作（免打扰 / 置顶 / 归档 / 清空 / 删除 / 同步）。",
    },
    dataSource: {
      en: "conversation summary from the view + connection state from the client",
      zh: "取视图的会话摘要 + client 的连接状态",
    },
    props: {
      conversation: { en: "The conversation summary to describe.", zh: "要展示的会话摘要。" },
      connectionText: { en: "Human-readable connection label (e.g. connected/reconnecting).", zh: "可读的连接文案（如已连接 / 重连中）。" },
      connectionTone: { en: "Severity of the connection label — drives its color.", zh: "连接文案的语义级别 —— 决定其颜色。" },
      messageCount: { en: "Total messages, shown in the stats row.", zh: "消息总数，显示在统计行。" },
      latestMessageId: { en: "Id of the newest message, for diagnostics/jump.", zh: "最新消息 id，用于诊断 / 跳转。" },
    },
  },
  StartConversationDialog: {
    summary: {
      en: "New-conversation entry — pick a contact or create a group.",
      zh: "发起会话入口 —— 选联系人或建群。",
    },
    dataSource: {
      en: "contacts/directory from the product; confirm creates/opens a conversation via the client",
      zh: "联系人 / 通讯录由产品提供；确认经 client 创建 / 打开会话",
    },
    props: {
      busy: { en: "Disables confirm and shows a spinner while creating.", zh: "创建中禁用确认并转圈。" },
    },
  },
  MessageBubble: {
    summary: {
      en: "One message in a thread — content, sender, grouping, delivery status. Delegates body to a per-content-type view.",
      zh: "线程里的一条消息 —— 内容、发送者、分组、送达状态。正文按内容类型委派给对应视图。",
    },
    dataSource: {
      en: "one item from client.views.openTimeline(conversationId); status drives state",
      zh: "取 client.views.openTimeline(conversationId) 的一条；status 驱动状态",
    },
    notes: {
      en: "Optimistic: status from the core view, never a network wait.",
      zh: "乐观：status 来自 core 视图，绝不等网络。",
    },
    props: {
      message: { en: "The message to render.", zh: "要渲染的消息。" },
      currentUserId: { en: "Viewer's id; decides self vs. other side.", zh: "当前用户 id；判定自己 / 对方。" },
      self: { en: "Force the outgoing side; defaults from sender == current user.", zh: "强制发送方；默认由 sender==当前用户 推导。" },
      conversationType: { en: "Single/group/AI — affects sender name & grouping.", zh: "单聊 / 群 / AI —— 影响发送者名与分组。" },
      groupStart: { en: "First bubble of a same-sender run (shows avatar/name).", zh: "同发送者连发的首条（显示头像 / 名）。" },
      groupEnd: { en: "Last bubble of a run (carries the tail & time).", zh: "连发的末条（带尾角与时间）。" },
      multiSelectMode: { en: "Renders the selection checkbox.", zh: "渲染多选勾选框。" },
      selected: { en: "Whether this bubble is checked in multi-select.", zh: "多选态下是否被选中。" },
      menuConfig: { en: "Which long-press actions are enabled for this message.", zh: "该消息长按可用的操作集合。" },
      mediaDownloadState: { en: "Progress/state for media bodies (image/video/file).", zh: "媒体正文（图 / 视频 / 文件）的下载进度 / 状态。" },
    },
  },
  MessageList: {
    summary: {
      en: "The virtualised message thread — grouping, load-older, multi-select, per-message actions, media state.",
      zh: "虚拟化消息线程 —— 分组、加载更早、多选、逐条操作、媒体状态。",
    },
    dataSource: {
      en: "client.views.openTimeline(conversationId); windowed, load-older via view.loadOlder()",
      zh: "client.views.openTimeline(conversationId)；窗口化，加载更早经 view.loadOlder()",
    },
    notes: {
      en: "60fps virtualised; O(visible); scroll anchoring on append/prepend.",
      zh: "60fps 虚拟化；O(visible)；追加 / 前插时锚定滚动位。",
    },
    props: {
      conversationId: { en: "Which timeline to open.", zh: "打开哪条时间线。" },
      conversationType: { en: "Single/group/AI — affects bubble layout.", zh: "单聊 / 群 / AI —— 影响气泡版式。" },
      messages: { en: "Windowed message slice from the view.", zh: "视图给出的窗口化消息片段。" },
      currentUserId: { en: "Viewer's id, for self/other resolution.", zh: "当前用户 id，用于自 / 他判定。" },
      multiSelectMode: { en: "Turns on per-bubble selection.", zh: "开启逐条多选。" },
      selectedIds: { en: "Ids currently checked in multi-select.", zh: "多选态下已勾选的 id。" },
      loadingOlder: { en: "Shows the load-older spinner at the top.", zh: "顶部显示加载更早的转圈。" },
      hasOlder: { en: "Whether more history exists to page in.", zh: "是否还有更早历史可翻。" },
      bottomInset: { en: "Extra bottom padding (e.g. above the composer).", zh: "底部额外内边距（如让开输入框）。" },
      menuConfig: { en: "Enabled long-press actions across the list.", zh: "整表可用的长按操作集合。" },
      mediaDownloadStates: { en: "Map of messageId → media download state.", zh: "messageId → 媒体下载状态 的映射。" },
    },
  },
  ChatHeader: {
    summary: {
      en: "The active conversation's header — title, subtitle/presence, and header actions (search/call/details).",
      zh: "当前会话头部 —— 标题、副标题 / 在线态，以及头部操作（搜索 / 通话 / 详情）。",
    },
    dataSource: {
      en: "active conversation summary + peer presence from the view",
      zh: "取视图的当前会话摘要 + 对端在线态",
    },
    props: {
      title: { en: "Conversation name shown in the header.", zh: "头部显示的会话名。" },
      subtitle: { en: "Secondary line (member count, typing, last-seen…).", zh: "副标题行（成员数、正在输入、最后在线…）。" },
      presence: { en: "Peer presence for a 1:1 chat; drives the status dot.", zh: "单聊对端在线态；驱动状态点。" },
    },
  },
  PinnedMessageBar: {
    summary: {
      en: "Sticky bar showing pinned messages above the thread; tap to focus the pinned message.",
      zh: "线程上方的置顶消息吸顶条；点按定位到被置顶的消息。",
    },
    dataSource: {
      en: "pinned messages from the timeline view",
      zh: "取时间线视图的置顶消息",
    },
    props: {
      items: { en: "Pinned messages; if several, the bar cycles through them.", zh: "置顶消息集；多条时条内轮播。" },
    },
  },
  MessageContentView: {
    summary: {
      en: "Content-type dispatcher — renders a message body by type via the content-type registry (text/image/video/card/vote/task/…). Extension point for products.",
      zh: "内容类型分发器 —— 经内容类型注册表按类型渲染消息正文（文本 / 图片 / 视频 / 名片 / 投票 / 任务 / …）。产品扩展点。",
    },
    dataSource: {
      en: "message.content from the timeline view",
      zh: "取时间线视图的 message.content",
    },
    notes: {
      en: "See contentTypes.registered for the built-in set; register new types for product content.",
      zh: "内建集见 contentTypes.registered；产品内容可注册新类型。",
    },
    props: {
      content: { en: "The typed message body to dispatch on.", zh: "要分发的带类型消息正文。" },
      self: { en: "Outgoing side — some bodies restyle (e.g. text color).", zh: "发送方 —— 部分正文据此换样式（如文字色）。" },
      previewMode: { en: "Compact render for quotes/reply strips/search hits.", zh: "紧凑渲染，用于引用 / 回复条 / 搜索命中。" },
      messageId: { en: "Id, for media actions and locate-message.", zh: "消息 id，用于媒体操作与定位。" },
      messageExtra: { en: "Type-specific extra payload passed to the renderer.", zh: "按类型透传给渲染器的额外载荷。" },
      senderName: { en: "Sender name, used by some content types (e.g. cards).", zh: "发送者名，部分内容类型会用（如名片）。" },
      mediaState: { en: "Download/progress state for media bodies.", zh: "媒体正文的下载 / 进度状态。" },
    },
  },
  Composer: {
    summary: {
      en: "The input — rich or plain text, emoji, format bar, attachments, reply strip. Emits built content; send is optimistic.",
      zh: "输入框 —— 富文本 / 纯文本、表情、格式条、附件、回复条。产出内容；发送为乐观。",
    },
    dataSource: {
      en: "writes through client.messages.send(...); local echo < 16 ms, status via the view",
      zh: "经 client.messages.send(...) 写入；本地回显 < 16ms，状态经视图",
    },
    props: {
      conversationId: { en: "Target conversation for sends and the draft.", zh: "发送与草稿归属的目标会话。" },
      replyTo: { en: "Message being replied to; shows the reply strip.", zh: "被回复的消息；显示回复条。" },
      rich: { en: "Enable rich (Markdown/RichDoc) editing vs. plain text.", zh: "启用富文本（Markdown/RichDoc）编辑，否则纯文本。" },
      placeholder: { en: "Empty-field hint text.", zh: "空输入时的占位提示。" },
    },
  },
  RichMarkdownInput: {
    summary: {
      en: "The rich (RichDoc/Markdown) text field with formatting preview and length limit — used inside Composer.",
      zh: "富文本（RichDoc/Markdown）编辑域，带格式预览与字数限制 —— Composer 内部使用。",
    },
    dataSource: {
      en: "produces normalized RichDoc/Markdown content (normalized by core)",
      zh: "产出规范化的 RichDoc/Markdown 内容（由 core 归一化）",
    },
    props: {
      disabled: { en: "Read-only, non-editable state.", zh: "只读、不可编辑态。" },
      formattingPreview: { en: "Render inline formatting live while typing.", zh: "输入时实时渲染内联格式。" },
      maxLength: { en: "Character cap; over-limit blocks input and warns.", zh: "字数上限；超限拦截输入并告警。" },
      placeholder: { en: "Empty-field hint text.", zh: "空输入时的占位提示。" },
    },
  },
  MessageActionSheet: {
    summary: {
      en: "The attachment/plus action sheet — image, file, card, vote, etc.; builds a content message.",
      zh: "附件 / 加号操作面板 —— 图片、文件、名片、投票等；构建内容消息。",
    },
    dataSource: {
      en: "builds a message via client message builders",
      zh: "经 client 的消息构建器产出消息",
    },
    props: {
      open: { en: "Whether the sheet is expanded.", zh: "面板是否展开。" },
    },
  },
  ImagePreviewModal: {
    summary: {
      en: "Full-screen image viewer — zoom/pan, download with progress.",
      zh: "全屏图片查看器 —— 缩放 / 拖动，带进度下载。",
    },
    dataSource: {
      en: "media resolved via client.media (off-thread, progressive)",
      zh: "图源经 client.media 解析（离主线程、渐进）",
    },
    props: {
      show: { en: "Controls open/close of the viewer.", zh: "控制查看器开 / 关。" },
      imageSrc: { en: "Resolved image source to display.", zh: "已解析、待展示的图源。" },
      loading: { en: "Full-res still resolving.", zh: "原图仍在解析中。" },
      alt: { en: "Accessible description of the image.", zh: "图片的无障碍描述。" },
      downloading: { en: "A save is in progress.", zh: "正在保存中。" },
      progressPct: { en: "Download progress, 0–100.", zh: "下载进度，0–100。" },
      zoomMin: { en: "Minimum zoom factor.", zh: "最小缩放倍数。" },
      zoomMax: { en: "Maximum zoom factor.", zh: "最大缩放倍数。" },
    },
  },
  VideoPlayerModal: {
    summary: {
      en: "Full-screen video player with poster and title.",
      zh: "全屏视频播放器，带封面与标题。",
    },
    dataSource: {
      en: "media resolved via client.media (off-thread streaming)",
      zh: "视频经 client.media 解析（离主线程流式）",
    },
    props: {
      show: { en: "Controls open/close of the player.", zh: "控制播放器开 / 关。" },
      videoSrc: { en: "Resolved video source to play.", zh: "已解析、待播放的视频源。" },
      poster: { en: "Still shown before playback starts.", zh: "开播前展示的封面图。" },
      title: { en: "Title shown in the player chrome.", zh: "播放器顶部显示的标题。" },
    },
  },
  MarkdownPreview: {
    summary: {
      en: "Rendered read-only Markdown/RichDoc content with optional stats.",
      zh: "只读渲染的 Markdown/RichDoc 内容，可选字数统计。",
    },
    dataSource: {
      en: "normalized Markdown/RichDoc content (from core)",
      zh: "规范化的 Markdown/RichDoc 内容（来自 core）",
    },
    props: {
      content: { en: "Markdown/RichDoc string to render read-only.", zh: "只读渲染的 Markdown/RichDoc 串。" },
      showStats: { en: "Show word/char counts under the content.", zh: "在内容下方显示字 / 词数。" },
    },
  },
  SearchBar: {
    summary: {
      en: "Unified search field — the entry to conversation/contact/message search, with clear and submit.",
      zh: "统一搜索框 —— 会话 / 联系人 / 消息的入口，带清除与提交。",
    },
    dataSource: {
      en: "controlled input; results are queried by the product (local view or server)",
      zh: "受控输入；结果由产品侧查询（本地视图或服务端）",
    },
    props: {
      modelValue: { en: "Two-way bound query text.", zh: "双向绑定的查询文本。" },
      placeholder: { en: "Empty-field hint text.", zh: "空输入时的占位提示。" },
      loading: { en: "Shows a spinner while a query is running.", zh: "查询进行中显示转圈。" },
    },
  },
  Input: {
    summary: {
      en: "General text input — single/multi-line, char limit, clearable, disabled/read-only; the backbone of forms and search.",
      zh: "通用文本输入框 —— 单 / 多行、字数限制、可清除、禁用 / 只读，撑起表单与搜索。",
    },
    dataSource: {
      en: "controlled value; the product owns validation and submit",
      zh: "受控值；产品决定校验与提交",
    },
    props: {
      modelValue: { en: "Two-way bound value.", zh: "双向绑定的值。" },
      placeholder: { en: "Empty-field hint text.", zh: "空输入时的占位提示。" },
      multiline: { en: "Grow into a textarea instead of a single line.", zh: "变为多行文本域而非单行。" },
      maxLength: { en: "Character cap; shows a counter.", zh: "字数上限；显示计数。" },
      disabled: { en: "Non-editable, dimmed state.", zh: "不可编辑、置灰态。" },
      clearable: { en: "Show a clear (×) button when non-empty.", zh: "非空时显示清除（×）按钮。" },
    },
  },
  EmptyState: {
    summary: {
      en: "Empty-state placeholder — icon + title + description + optional action; for empty inbox/search/contacts.",
      zh: "空状态占位 —— 图标 + 标题 + 说明 + 可选操作，用于空会话 / 空搜索 / 空联系人。",
    },
    dataSource: { en: "presentational only", zh: "纯展示" },
    props: {
      title: { en: "Primary line explaining the emptiness.", zh: "说明空状态的主标题。" },
      description: { en: "Secondary help text.", zh: "次级说明文字。" },
      actionText: { en: "Label for the optional call-to-action button.", zh: "可选行动按钮的文案。" },
    },
  },
  ContactList: {
    summary: {
      en: "The address book — contacts grouped A–Z by pinyin/letter, with a side index bar and quick jump.",
      zh: "通讯录 —— 按拼音 / 字母 A–Z 分组的联系人列表，带侧边索引条与快速跳转。",
    },
    dataSource: {
      en: "client.views contacts/friends view; grouping and index in the presentation layer",
      zh: "client.views 联系人 / 好友视图；分组与索引在展示层",
    },
    notes: {
      en: "Virtualised + sticky group headers; A–Z side index jumps.",
      zh: "虚拟化 + 分组吸顶 header；侧边 A–Z 索引跳转。",
    },
    props: {
      items: { en: "Contacts to group and render.", zh: "要分组渲染的联系人。" },
      indexed: { en: "Show the A–Z side index bar.", zh: "显示 A–Z 侧边索引条。" },
      loading: { en: "First-load skeleton/spinner.", zh: "首屏骨架 / 转圈。" },
    },
  },
  ContactItem: {
    summary: {
      en: "A contact row — avatar, name, signature/department, presence.",
      zh: "通讯录行 —— 头像、名称、签名 / 部门、在线状态。",
    },
    dataSource: { en: "one Contact", zh: "一个 Contact" },
    props: {
      item: { en: "The contact's data.", zh: "该联系人的数据。" },
      showPresence: { en: "Render the presence dot.", zh: "渲染在线状态点。" },
    },
  },
  ContactDetail: {
    summary: {
      en: "Contact card — avatar/name/signature + profile fields + message/voice/video/more actions.",
      zh: "联系人名片 —— 头像 / 名称 / 签名 + 资料字段 + 发消息 / 语音 / 视频 / 更多操作。",
    },
    dataSource: {
      en: "one Contact's detail; actions open a conversation / start a call via the client",
      zh: "一个 Contact 详情；操作经 client 打开会话 / 发起通话",
    },
    props: {
      contact: { en: "The contact to profile.", zh: "要展示的联系人。" },
    },
  },
  NewFriendRequests: {
    summary: {
      en: "New friends — friend-request list with accept/reject and request notes.",
      zh: "新的朋友 —— 好友申请列表，接受 / 拒绝，带申请附言。",
    },
    dataSource: { en: "friend-request view", zh: "好友申请视图" },
    props: {
      items: { en: "Pending and resolved requests to list.", zh: "待处理与已处理的申请列表。" },
    },
  },
  GroupList: {
    summary: {
      en: "My groups — group avatar, name, member count.",
      zh: "我的群组 —— 群头像、名称、成员数。",
    },
    dataSource: { en: "groups view", zh: "群组视图" },
    props: {
      items: { en: "Group summaries to list.", zh: "要列出的群摘要。" },
    },
  },
  ProfilePanel: {
    summary: {
      en: "Personal center — avatar/name/id/QR + entry list (favorites/settings/about), with logout.",
      zh: "个人中心 —— 头像 / 名称 / ID / 二维码 + 入口列表（我的收藏 / 设置 / 关于），支持退出。",
    },
    dataSource: {
      en: "current user profile + app entry configuration",
      zh: "当前用户资料 + 应用入口配置",
    },
    props: {
      user: { en: "The signed-in user's profile.", zh: "已登录用户的资料。" },
    },
  },
  ProfileEditor: {
    summary: {
      en: "Profile editor — edit and save avatar, nickname, signature and similar fields.",
      zh: "资料编辑 —— 头像、昵称、签名等字段编辑与保存。",
    },
    dataSource: {
      en: "controlled draft; save is submitted via the client",
      zh: "受控草稿；保存经 client 提交",
    },
    props: {
      user: { en: "Initial profile the draft starts from.", zh: "草稿初始的资料。" },
      busy: { en: "Disables save and shows a spinner while submitting.", zh: "提交中禁用保存并转圈。" },
    },
  },
  SettingsList: {
    summary: {
      en: "Settings list — grouped toggles/navigation/choice rows; a general settings container.",
      zh: "设置列表 —— 分组的开关 / 跳转 / 选择项，通用设置容器。",
    },
    dataSource: {
      en: "product-defined settings sections",
      zh: "产品定义的设置项分组",
    },
    props: {
      sections: { en: "Grouped settings rows to render.", zh: "要渲染的分组设置行。" },
    },
  },
  CallView: {
    summary: {
      en: "In-call surface — peer video/avatar, state, duration, with an overlaid control bar. Video render is host-injected.",
      zh: "音视频通话中界面 —— 对端画面 / 头像、状态、时长，叠加控制条。视频渲染由宿主注入。",
    },
    dataSource: {
      en: "RTC session state (core/media layer); video track rendered by the host",
      zh: "RTC 会话状态（core / 媒体层）；画面轨道由宿主渲染",
    },
    notes: {
      en: "Video track uses a host-injected render slot; the control bar is CallControls.",
      zh: "视频轨道用宿主注入的渲染 slot；控制条为 CallControls。",
    },
    props: {
      peerName: { en: "Name of the person on the call.", zh: "通话对端的名称。" },
      mode: { en: "Audio or video — changes the layout.", zh: "音频或视频 —— 改变版式。" },
      state: { en: "Calling / ringing / connected.", zh: "呼叫中 / 响铃中 / 已接通。" },
      durationLabel: { en: "Preformatted elapsed time (mm:ss).", zh: "已格式化的通话时长（mm:ss）。" },
      peerAvatarUrl: { en: "Peer avatar, shown for audio calls.", zh: "对端头像，音频通话时显示。" },
    },
  },
  IncomingCall: {
    summary: {
      en: "Incoming call / invite — caller avatar/name, audio/video kind, accept & reject.",
      zh: "来电 / 通话邀请 —— 来电人头像 / 名称、音视频类型，接听 / 拒绝。",
    },
    dataSource: { en: "RTC incoming-call signaling", zh: "RTC 来电信令" },
    props: {
      callerName: { en: "Name of the caller.", zh: "来电人的名称。" },
      mode: { en: "Audio or video invite.", zh: "音频或视频邀请。" },
      callerAvatarUrl: { en: "Caller's avatar.", zh: "来电人的头像。" },
    },
  },
  CallControls: {
    summary: {
      en: "Call control bar — mute, camera, speaker, flip camera, hang up (adapts to audio/video).",
      zh: "通话控制条 —— 静音、摄像头、扬声器、翻转摄像头、挂断（音 / 视频自适应）。",
    },
    dataSource: { en: "local RTC device state", zh: "本地 RTC 设备状态" },
    props: {
      muted: { en: "Mic is muted.", zh: "麦克风已静音。" },
      cameraOn: { en: "Camera is on (video mode).", zh: "摄像头已开（视频模式）。" },
      speakerOn: { en: "Speaker is on (audio mode).", zh: "扬声器已开（音频模式）。" },
      mode: { en: "Audio hides camera/flip; video hides speaker.", zh: "音频隐藏摄像头 / 翻转；视频隐藏扬声器。" },
    },
  },
  AppShell: {
    summary: {
      en: "App shell — responsive navigation (mobile bottom tab / tablet-desktop side rail) + content area; the skeleton of the whole IM app.",
      zh: "应用外壳 —— 自适应导航（手机底部 Tab / 平板·PC 侧栏）+ 内容区，撑起整个 IM 应用骨架。",
    },
    dataSource: {
      en: "nav item configuration + current route",
      zh: "导航项配置 + 当前路由",
    },
    notes: {
      en: "Breakpoint-adaptive: mobile = bottom nav; tablet/desktop = side rail.",
      zh: "断点自适应：手机=底部导航；平板 / PC=侧边导航。",
    },
    props: {
      items: { en: "Navigation destinations, with icon/label/badge.", zh: "导航目的地，含图标 / 文案 / 角标。" },
      activeKey: { en: "Currently selected nav key.", zh: "当前选中的导航 key。" },
    },
  },
  ResponsiveLayout: {
    summary: {
      en: "Responsive conversation layout — mobile single column (list↔chat), tablet two columns (list+chat), desktop three columns (list+chat+detail).",
      zh: "自适应会话布局 —— 手机单栏（列表↔聊天切换）、平板双栏（列表+聊天）、PC 三栏（列表+聊天+详情）。",
    },
    dataSource: {
      en: "layout only; the three slots (list/chat/detail) are filled by the product",
      zh: "纯布局；三个 slot（list/chat/detail）由产品填充",
    },
    props: {
      hasDetail: { en: "Whether a detail pane exists (enables 3-column).", zh: "是否存在详情栏（启用三栏）。" },
      activePane: { en: "Which pane is foregrounded on mobile.", zh: "手机端前置显示哪个栏。" },
    },
  },
};

// ---- apply with full-coverage assertions ----
const errors = [];
const box = (v) => (v && typeof v === "object" && "en" in v ? v : v);

for (const c of spec.components) {
  const src = CONTENT[c.name];
  if (!src) { errors.push(`missing CONTENT for component ${c.name}`); continue; }
  for (const key of ["summary", "dataSource"]) {
    if (!src[key]?.en || !src[key]?.zh) errors.push(`${c.name}.${key}: missing en/zh`);
    else c[key] = { en: src[key].en, zh: src[key].zh };
  }
  if (c.notes !== undefined) {
    if (!src.notes?.en || !src.notes?.zh) errors.push(`${c.name}.notes: missing en/zh`);
    else c.notes = { en: src.notes.en, zh: src.notes.zh };
  }
  for (const p of c.props ?? []) {
    const d = src.props?.[p.name];
    if (!d?.en || !d?.zh) { errors.push(`${c.name}.props.${p.name}: missing description en/zh`); continue; }
    p.description = { en: d.en, zh: d.zh };
  }
}

if (errors.length) {
  console.error(`✗ migration incomplete (${errors.length}):`);
  for (const e of errors) console.error("  - " + e);
  process.exit(1);
}

// carry category labels onto the spec for the generator/config to consume
spec.categoryLabels = CATEGORIES;

writeFileSync(specPath, JSON.stringify(spec, null, 2) + "\n");
console.log(`✓ migrated ${spec.components.length} components to bilingual (en/zh); category labels attached`);
void box;
