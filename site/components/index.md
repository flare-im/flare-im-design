# 组件总览

一套契约，四端原生实现。共 **51** 个组件、**9** 大类。

## 通用

- [**Avatar**](/components/avatar) — 用户 / 群组头像 —— 图片、首字母兜底、可选在线状态点。
- [**TimeStamp**](/components/time-stamp) — 消息或会话行的相对 / 绝对时间标签。
- [**MessageStatus**](/components/message-status) — 送达状态指示 —— 发送中转圈、已发送 / 已读勾、失败可重试。
- [**SearchBar**](/components/search-bar) — 统一搜索框 —— 会话 / 联系人 / 消息的入口，带清除与提交。
- [**Input**](/components/input) — 通用文本输入框 —— 单 / 多行、字数限制、可清除、禁用 / 只读，撑起表单与搜索。
- [**EmptyState**](/components/empty-state) — 空状态占位 —— 图标 + 标题 + 说明 + 可选操作，用于空会话 / 空搜索 / 空联系人。

## 会话

- [**ConversationList**](/components/conversation-list) — 会话收件箱 —— 虚拟化的会话行（头像、标题、预览、未读、时间）。
- [**ConversationRow**](/components/conversation-row) — 单个会话行 —— 头像、标题、末条 / 草稿预览、未读角标、时间、免打扰 / 置顶标记。
- [**ConversationDetails**](/components/conversation-details) — 会话信息 / 设置面板 —— 统计、连接状态，以及单会话操作（免打扰 / 置顶 / 归档 / 清空 / 删除 / 同步）。
- [**StartConversationDialog**](/components/start-conversation-dialog) — 发起会话入口 —— 选联系人或建群。

## 消息

- [**MessageBubble**](/components/message-bubble) — 线程里的一条消息 —— 内容、发送者、分组、送达状态。正文按内容类型委派给对应视图。
- [**MessageList**](/components/message-list) — 虚拟化消息线程 —— 分组、加载更早、多选、逐条操作、媒体状态。
- [**ChatHeader**](/components/chat-header) — 当前会话头部 —— 标题、副标题 / 在线态，以及头部操作（搜索 / 通话 / 详情）。
- [**PinnedMessageBar**](/components/pinned-message-bar) — 线程上方的置顶消息吸顶条；点按定位到被置顶的消息。
- [**MessageContentView**](/components/message-content-view) — 内容类型分发器 —— 经内容类型注册表按类型渲染消息正文（文本 / 图片 / 视频 / 名片 / 投票 / 任务 / …）。产品扩展点。
- [**TextMessage**](/components/text-message) — 文本消息体 —— 自动识别链接；self 切换为己方品牌气泡。
- [**ImageMessage**](/components/image-message) — 图片消息体 —— 圆角缩略图。
- [**VideoMessage**](/components/video-message) — 视频消息体 —— 封面 + 播放叠层 + 时长角标。
- [**VoiceMessage**](/components/voice-message) — 语音消息体 —— 波形 + 时长。
- [**FileMessage**](/components/file-message) — 文件消息体 —— 图标、名称 / 大小 / 类型、下载。
- [**LocationMessage**](/components/location-message) — 位置消息体 —— 地图占位 + 标题 / 地址。
- [**ContactMessage**](/components/contact-message) — 名片消息体 —— pastel 头像 + 名称 / ID。
- [**LinkCardMessage**](/components/link-card-message) — 链接卡片 —— 缩略图 + 标题 + 域名。
- [**VoteMessage**](/components/vote-message) — 投票消息体 —— 标题 + 带进度条的选项。
- [**TaskMessage**](/components/task-message) — 任务消息体 —— 勾选框 + 标题（完成划线）+ 附注。
- [**StickerMessage**](/components/sticker-message) — 贴纸消息体 —— 裸的大图 / emoji（无气泡）。
- [**EmojiMessage**](/components/emoji-message) — 大 emoji 消息体 —— 裸，无气泡。
- [**SystemMessage**](/components/system-message) — 系统 / 通知消息体 —— 居中 pill。
- [**MessageActionSheet**](/components/message-action-sheet) — 消息长按操作面板 —— 表情条、快捷操作（回复 / 转发 / 撤回）、分组操作（多选 / 标记 / 置顶 / 复制 / 编辑 / 删除）。删除为红色。

## 输入

- [**Composer**](/components/composer) — 输入框 —— 富文本 / 纯文本、表情、格式条、附件、回复条。产出内容；发送为乐观。
- [**VoiceHoldButton**](/components/voice-hold-button) — 按住说话的语音按钮 —— 按住录音、上滑取消。可自由组合的 Composer 部件。
- [**ComposerActionPanel**](/components/composer-action-panel) — 下方功能区 —— 附件动作网格（图片 / 文件 / 名片 / 投票 / …），Composer「＋」展开的面板。
- [**ComposerSendButton**](/components/composer-send-button) — 发送按钮 —— active 时品牌紫、否则禁用。可自由组合的 Composer 部件。
- [**ComposerReplyStrip**](/components/composer-reply-strip) — 回复条 —— 回复时显示在输入框上方：左侧品牌竖条 + 发送者 / 摘要 + 取消。
- [**RichMarkdownInput**](/components/rich-markdown-input) — 富文本（RichDoc/Markdown）编辑域，带格式预览与字数限制 —— Composer 内部使用。

## 媒体

- [**ImagePreviewModal**](/components/image-preview-modal) — 全屏图片查看器 —— 缩放 / 拖动，带进度下载。
- [**VideoPlayerModal**](/components/video-player-modal) — 全屏视频播放器，带封面与标题。
- [**MarkdownPreview**](/components/markdown-preview) — 只读渲染的 Markdown/RichDoc 内容，可选字数统计。

## 通讯录

- [**ContactList**](/components/contact-list) — 通讯录 —— 按拼音 / 字母 A–Z 分组的联系人列表，带侧边索引条与快速跳转。
- [**ContactItem**](/components/contact-item) — 通讯录行 —— 头像、名称、签名 / 部门、在线状态。
- [**ContactDetail**](/components/contact-detail) — 联系人名片 —— 头像 / 名称 / 签名 + 资料字段 + 发消息 / 语音 / 视频 / 更多操作。
- [**NewFriendRequests**](/components/new-friend-requests) — 新的朋友 —— 好友申请列表，接受 / 拒绝，带申请附言。
- [**GroupList**](/components/group-list) — 我的群组 —— 群头像、名称、成员数。

## 个人中心

- [**ProfilePanel**](/components/profile-panel) — 个人中心 —— 头像 / 名称 / ID / 二维码 + 入口列表（我的收藏 / 设置 / 关于），支持退出。
- [**ProfileEditor**](/components/profile-editor) — 资料编辑 —— 头像、昵称、签名等字段编辑与保存。
- [**SettingsList**](/components/settings-list) — 设置列表 —— 分组的开关 / 跳转 / 选择项，通用设置容器。

## 音视频通话

- [**CallView**](/components/call-view) — 音视频通话中界面 —— 对端画面 / 头像、状态、时长，叠加控制条。视频渲染由宿主注入。
- [**IncomingCall**](/components/incoming-call) — 来电 / 通话邀请 —— 来电人头像 / 名称、音视频类型，接听 / 拒绝。
- [**CallControls**](/components/call-controls) — 通话控制条 —— 静音、摄像头、扬声器、翻转摄像头、挂断（音 / 视频自适应）。

## 布局

- [**AppShell**](/components/app-shell) — 应用外壳 —— 自适应导航（手机底部 Tab / 平板·PC 侧栏）+ 内容区，撑起整个 IM 应用骨架。
- [**ResponsiveLayout**](/components/responsive-layout) — 自适应会话布局 —— 手机单栏（列表↔聊天切换）、平板双栏（列表+聊天）、PC 三栏（列表+聊天+详情）。

