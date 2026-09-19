---
title: 数据类型
---

# 数据类型

> 组件 props 里用到的共享数据结构。从你自己的数据源把这些对象喂给组件即可——组件不耦合 SDK。

## 接口

### ConversationIdentity {#conversation-identity}

`FlareConversationIdentity`

> 由宿主持有的当前单聊、群聊、频道、机器人或系统会话身份。

**被使用于：**[ConversationHeader](/components/conversation-header)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 稳定会话标识和头像兜底种子。 |
| `title` | `string` | ✓ | 会话主标题。 |
| `kind` | `'direct' \| 'group' \| 'channel' \| 'bot' \| 'system'` |  | 用于选择默认预设的会话语义。 |
| `subtitle` | `string` |  | 由宿主格式化的稳定副标题。 |
| `avatarUrl` | `string` |  | 单聊或群聊头像 URL。 |
| `presence` | `'online' \| 'offline' \| 'busy' \| 'away'` |  | 由宿主提供的在线态。 |
| `memberCount` | `number` |  | 未传副标题时使用的群成员摘要。 |
| `typingText` | `string` |  | 优先于副标题的临时输入状态文案。 |
| `accessibilityLabel` | `string` |  | 供辅助技术使用的本地化头部标签。 |
| `action` | [`ConversationHeaderAction`](/reference/data-types#conversation-header-action) |  | 从整个身份区（头像、标题、副标题）触发的可选、受能力过滤的宿主意图，例如打开会话详情。 |

### ConversationHeaderAction {#conversation-header-action}

`FlareConversationHeaderAction`

> 会话头部中的一个 SDK 无关宿主意图。

**被使用于：**[ConversationHeader](/components/conversation-header)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 稳定动作 id。 |
| `label` | `string` | ✓ | 可见且可读屏的动作名称。 |
| `icon` | `string` |  | 跨端语义图标名。 |
| `placement` | `'primary' \| 'add' \| 'overflow'` |  | 主工具栏、专用 Plus 菜单或更多菜单。 |
| `group` | `string` |  | 可选菜单分组键。 |
| `order` | `number` |  | 稳定宿主优先级。 |
| `visible` | `boolean` |  | 临时策略可见性。 |
| `enabled` | `boolean` |  | 保留上下文时的可用性。 |
| `badge` | `string` |  | 可选紧凑徽标。 |
| `intent` | `string` |  | 宿主定义的意图载荷键。 |
| `capability` | `string` |  | 显示所需能力 id。 |
| `accessibilityLabel` | `string` |  | 本地化无障碍标签覆盖。 |
| `disabledReason` | `string` |  | 禁用时宣布的原因。 |
| `pressed` | `boolean` |  | 使动作成为开关；为 true 时显示为按下（搜索已打开、详情已显示）。 |

### ActionItem {#action-item}

`FlareActionItem`

> 共享的操作描述：输入框与头部操作都扩展它，ActionMenu 绘制它。

**被使用于：**[ActionMenu](/components/action-menu)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 稳定 id，被选中时回报。 |
| `label` | `string` | ✓ | 可见文案。 |
| `icon` | `string` |  | 组件库语义图标名（Vue 也接受图标组件）。 |
| `group` | `string` |  | 分组变化处菜单画分隔线。 |
| `order` | `number` |  | 供排序方使用的优先级；菜单保持宿主顺序。 |
| `visible` | `boolean` |  | 为 false 时不显示。 |
| `enabled` | `boolean` |  | 为 false 时保留显示但不可用。 |
| `badge` | `string` |  | 紧凑的尾部文字。 |
| `intent` | `string` |  | 宿主定义的意图载荷键。 |
| `accessibilityLabel` | `string` |  | 本地化无障碍名称覆盖。 |
| `disabledReason` | `string` |  | 不可用的原因；随条目显示并播报。 |
| `pressed` | `boolean` |  | 设置后操作为开关；true 表示开启（按下的按钮、勾选的菜单项）。 |
| `danger` | `boolean` |  | 破坏性操作：用错误文字色绘制。 |

### ConversationHeaderCapabilities {#conversation-header-capabilities}

`FlareConversationHeaderCapabilities`

> 宿主为一个会话上下文声明的动作能力。

**被使用于：**[ConversationHeader](/components/conversation-header)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `availableActionIds` | `string[]` |  | 允许的语义动作或能力 id；省略时保留预设动作。 |

### ConversationHeaderConfiguration {#conversation-header-configuration}

`FlareConversationHeaderConfiguration`

> 覆盖在单聊或群聊头部预设上的宿主策略，不使用布尔功能开关。

**被使用于：**[ConversationHeader](/components/conversation-header)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `replaceDefaults` | `boolean` |  | 不使用任何预设动作作为起点。 |
| `removeActionIds` | `string[]` |  | 按 id 永久移除预设或宿主动作。 |
| `actionOverrides` | [`ConversationHeaderAction[]`](/reference/data-types#conversation-header-action) |  | 按稳定 id 覆盖文案、图标、位置、状态或顺序。 |
| `maxPrimaryActions` | `number` |  | 桌面进入 More 前的主工具栏上限。 |
| `compactMaxPrimaryActions` | `number` |  | 紧凑模式进入 More 前的主工具栏上限。 |

### MessageIdentity {#message-identity}

`MessageIdentity`

> 一行消息认的两个 id。定位一条消息（点引用、置顶栏、搜索命中）两个都算命中。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 列表画这一行用的 id，也是所有消息意图携带的 id。Vue 由 `clientMsgId \|\| serverId` 推出，三个原生 kit 就是 `FlareMessageData.id`。 |
| `serverId` | `string?` |  | 同一条消息在核心里的 id（有的话）。引用用它指向被引用消息——那是别的客户端唯一认得的 id；还在路上的消息没有。 |

### MessageRowPresentation {#message-row-presentation}

`FlareMessageRowPresentation`

> 由时间线推导、供消息气泡消费的呈现上下文。

**被使用于：**[MessageBubble](/components/message-bubble)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `showAvatar` | `boolean` | ✓ | 为当前行渲染发送者头像。 |
| `reserveAvatarSpace` | `boolean` | ✓ | 头像隐藏时仍保持消息组边槽稳定。 |
| `showSenderName` | `boolean` | ✓ | 为当前行渲染群聊发送者名称。 |
| `avatarPlacement` | `'leading' \| 'trailing'` | ✓ | 接收方或可选本人头像的逻辑侧。 |

### Contact {#contact}

`FlareContact`

> 通讯录联系人。

**被使用于：**[ContactList](/components/contact-list) · [ContactItem](/components/contact-item) · [ContactDetail](/components/contact-detail) · [GroupDetail](/components/group-detail) · [ProfileCard](/components/profile-card) · [GroupMemberGrid](/components/group-member-grid) · [ReadReceiptSheet](/components/read-receipt-sheet)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 稳定唯一 id。 |
| `name` | `string` | ✓ | 显示名。 |
| `avatarUrl` | `string` |  | 头像图 URL；缺省时回退首字母。 |
| `signature` | `string` |  | 个性签名。 |
| `presence` | `"online" \| "offline" \| "busy" \| "away"` |  | 在线状态，显示为状态圆点。 |
| `indexKey` | `string` |  | 显式 A–Z 索引字母；缺省时由名字推导。 |

### FriendRequest {#friend-request}

`FlareFriendRequest`

> 收到的好友申请。

**被使用于：**[NewFriendRequests](/components/new-friend-requests)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 申请 id。 |
| `name` | `string` | ✓ | 申请人显示名。 |
| `avatarUrl` | `string` |  | 申请人头像 URL。 |
| `message` | `string` |  | 申请附言（可选）。 |
| `direction` | `'incoming' \| 'outgoing'` |  | 申请是收到的还是发出的；默认收到。 |

### GroupSummary {#group-summary}

`FlareGroupSummary`

> 群组列表中的群摘要。

**被使用于：**[GroupList](/components/group-list)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 群 id。 |
| `name` | `string` | ✓ | 群名。 |
| `avatarUrl` | `string` |  | 群头像 URL。 |
| `memberCount` | `number` |  | 成员数，作为副标题显示。 |

### UserProfile {#user-profile}

`FlareUserProfile`

> 当前登录用户的资料。

**被使用于：**[ProfilePanel](/components/profile-panel) · [ProfileEditor](/components/profile-editor)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 用户 id。 |
| `name` | `string` | ✓ | 显示名。 |
| `avatarUrl` | `string` |  | 头像 URL。 |
| `signature` | `string` |  | 个性签名。 |
| `flareId` | `string` |  | 可选的外部/业务号，展示在资料页。 |

### SettingsItem {#settings-item}

`FlareSettingsItem`

> 设置分组中的一行。

**被使用于：**[SettingsRow](/components/settings-row)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `key` | `string` | ✓ | 稳定行键，交互时回传。 |
| `label` | `string` | ✓ | 行标题。 |
| `icon` | `string` |  | 前置图标：共享注册表里的语义名（未知名画注册表的兜底字形）。 |
| `kind` | [`FlareSettingKind`](/reference/data-types#setting-kind) |  | 行类型：navigation 打开页面或选择器（带箭头），toggle 是开关，action 原地执行（无箭头），value 是只读信息、不是控件。 |
| `value` | `boolean` |  | 开关状态（`kind: "toggle"` 时）。 |
| `detail` | `string` |  | 尾部详情文本：navigation 行的当前值，或 value 行的信息。过长时换到标签下方。 |

### SettingsSection {#settings-section}

`FlareSettingsSection`

> 带标题的设置分组。

**被使用于：**[SettingsList](/components/settings-list)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `title` | `string` |  | 分组标题（可选）。 |
| `items` | [`FlareSettingsItem[]`](/reference/data-types#settings-item) | ✓ | 分组内的行。 |

### ConversationRowModel {#conversation-row-model}

`FlareConversationRowModel`

> 包自有的会话行视图状态（不耦合运行时）。

**被使用于：**[ConversationList](/components/conversation-list) · [ConversationRow](/components/conversation-row)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 会话 id。 |
| `displayName` | `string` |  | 会话标题。 |
| `avatarUrl` | `string` |  | 会话头像 URL。 |
| `updatedAt` | `number \| string` |  | 最后活跃时间，用于排序/时间显示。 |
| `unreadCount` | `number` |  | 未读徽标数。 |
| `lastMessagePreview` | `string` |  | 已渲染的最后一条消息预览文本。 |
| `previewPending` | `boolean` |  | 预览仍在同步中。 |
| `draft` | `string` |  | 未发送草稿，显示为摘要前缀。 |
| `lastMessage` | `{ text?; time?; content? } \| null` |  | 结构化最后消息（预览的替代来源）。 |
| `pinned` | `boolean` |  | 置顶。 |
| `muted` | `boolean` |  | 已免打扰。 |
| `archived` | `boolean` |  | 已归档。 |
| `timestampLabel` | `string` |  | Host 格式化的时间。 |
| `mentioned` | `boolean` |  | 有未读提及。 |
| `typing` | `boolean` |  | 输入中，优先级低于失败和草稿。 |
| `failed` | `boolean` |  | 最后消息发送失败，摘要最高优先级。 |

### PinnedMessageItem {#pinned-message-item}

`PinnedMessageItem`

> 置顶栏中的置顶消息。

**被使用于：**[PinnedMessageBar](/components/pinned-message-bar)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `serverId` | `string` | ✓ | 服务端消息 id。 |
| `clientMsgId` | `string` | ✓ | 客户端消息 id。 |
| `senderDisplayName` | `string` | ✓ | 置顶上显示的发送者名。 |
| `content` | `{ contentType?; data? }` |  | 用于渲染预览的消息内容。 |

### VoteOption {#vote-option}

`FlareVoteOption`

> 投票消息中的一个选项。

**被使用于：**[VoteMessage](/components/vote-message)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `text` | `string` | ✓ | 选项文案。 |
| `pct` | `number \| null` |  | 已知的结果百分比（0–100）。没有结果时省略或传 null，不得伪造为零。 |

### MediaResolveRequest {#media-resolve-request}

`FlareMediaResolveRequest`

> `MediaResolver` 收到的、用于产出可显示 URL 的请求。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `kind` | [`FlareMediaKind`](/reference/data-types#media-kind) | ✓ | 要解析的媒体类型。 |
| `messageId` | `string` |  | 所属消息 id。 |
| `fileId` | `string` |  | 后端文件 id。 |
| `url` | `string` |  | 已知 URL（若有）。 |
| `localPath` | `string` |  | 本地缓存路径（若有）。 |
| `mimeType` | `string` |  | MIME 类型提示。 |
| `fileName` | `string` |  | 原始文件名。 |

## 枚举 / 联合类型

### MessageGroupPosition {#message-group-position}

`FlareMessageGroupPosition`

> 由时间线计算的同发送者消息组位置。

**被使用于：**[MessageBubble](/components/message-bubble)

`single` · `first` · `middle` · `last`

### SettingKind {#setting-kind}

`FlareSettingKind`

> 设置行的渲染与行为方式。

`navigation` · `toggle` · `value` · `action`

### ConversationAction {#conversation-action}

`FlareConversationAction`

> 会话行菜单、ConversationActionSheet 与动作载荷在各端共用的会话操作 id。

`pin` · `unpin` · `mute` · `unmute` · `markRead` · `markUnread` · `archive` · `unarchive` · `hide` · `clearHistory` · `delete`

### GroupJoinPolicy {#group-join-policy}

`FlareGroupJoinPolicy`

> 他人如何加入群。宿主把 SDK 码映射为这些值；null / nil 表示宿主不知道。

`open` · `approval` · `invite`

### ConversationFilter {#conversation-filter}

`FlareConversationFilter`

> 会话列表筛选标签。

`all` · `unread` · `mention` · `pinned` · `muted` · `archived` · `draft`

### ComposerState {#composer-state}

`FlareComposerState`

> 输入框状态，驱动提示与禁用。

`idle` · `typing` · `sending` · `failed` · `disabled` · `offline` · `permissionDenied` · `capabilityUnavailable` · `runtimeUnavailable`

### MediaKind {#media-kind}

`FlareMediaKind`

> 解析器被请求的媒体变体。

`image` · `imageThumbnail` · `imageGroupItem` · `video` · `videoCover` · `audio` · `file` · `string (custom)`

### ViewportKind {#viewport-kind}

`FlareViewportKind`

> 解析出的视口类别。

`pc` · `ipad` · `h5`

### LayoutMode {#layout-mode}

`FlareLayoutMode`

> 布局覆盖模式。

**被使用于：**[ConfigProvider](/components/config-provider)

`auto` · `pc` · `ipad` · `h5`

### DensityMode {#density-mode}

`FlareDensityMode`

> 界面密度。

`comfortable` · `compact`
