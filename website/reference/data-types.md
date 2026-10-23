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
| `tail` | `boolean` | ✓ | 画气泡尾角：bubble 表面且是本组最后一条（spec/message-grouping-vectors.json）。 |

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
| `source` | `string` |  | 申请来源，宿主已组织好文案（如「通过名片添加，由 X 推荐」）；在验证消息下方单独一行，用次要文本显示。 |
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

### ComposerCapabilities {#composer-capabilities}

`FlareComposerCapabilities`

> 宿主持有的输入栏「+」动作与工具条工具可用性；只管展示，能否发送仍以服务端为准。

**被使用于：**[Composer](/components/composer) · [ComposerActionPanel](/components/composer-action-panel)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `availableActionIds` | `string[]` |  | 保留的「+」面板 id；不传时全部保留。 |
| `availableToolIds` | [`ComposerToolId[]`](/reference/data-types#composer-tool-id) |  | 要显示的工具条工具（emoji、mention、voice、image、richText、attachments 即「+」按钮）；不传时全部显示，传了只显示列出的工具。SwiftUI 写作 availableToolIDs。 |
| `mentions` | `boolean` |  | 会话是否支持 @（单聊为 false）；Flutter、SwiftUI、Compose 用输入框自己的提及开关。 |

### InviteCodeCheckResult {#invite-code-check-result}

`FlareInviteCodeCheckResult`

> 宿主邀请码预检的结果。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `valid` | `boolean` | ✓ | 该码可用于注册。 |
| `inviterDisplayName` | `string` |  | 该码对应邀请人的脱敏显示名。 |

### ReferralStats {#referral-stats}

`FlareReferralStats`

> 当前用户各深度的推荐人数。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `direct` | `number` | ✓ | 用本人邀请码注册的人数。 |
| `l2` | `number` | ✓ | 二级推荐人数。 |
| `l3` | `number` | ✓ | 三级推荐人数。 |
| `total` | `number` | ✓ | 服务端统计的团队总人数。 |

### Invitee {#invitee}

`FlareInvitee`

> 当前用户直接邀请的一个人。

**被使用于：**[MyInvitePanel](/components/my-invite-panel)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `userId` | `string` | ✓ | 稳定标识；`select` 回传它，也用作头像种子。 |
| `displayName` | `string` | ✓ | 显示名。 |
| `avatarUrl` | `string` |  | 宿主有头像时的地址。 |
| `joinedAt` | `number` | ✓ | 注册时间，毫秒时间戳。 |

### ChartPoint {#chart-point}

`FlareChartPoint`

> ChartCard 序列中的一个读数。

**被使用于：**[ChartCard](/components/chart-card)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `label` | `string` | ✓ | 读数对应的标签 —— 日期、周期、名称，由宿主格式化好。 |
| `value` | `number \| null` | ✓ | 读数。该标签没有读数时传 `null`（缺口），不得用 0 代替。 |

### DataTableColumn {#data-table-column}

`FlareDataTableColumn`

> DataTable 的一列。

**被使用于：**[DataTable](/components/data-table)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `key` | `string` | ✓ | 这一列读取的行字段；也是 `cell-<key>` 插槽的名字。 |
| `title` | `string` | ✓ | 表头文字；窄容器下成为每个堆叠单元格的标签。 |
| `width` | `number \| string` |  | 固定宽度（数字按 px）。 |
| `minWidth` | `number \| string` |  | 表格分配空间时的下限。 |
| `sortable` | `boolean` |  | 表头画出排序控件；排序由宿主执行并回传 `sort`。 |
| `align` | `'start' \| 'center' \| 'end'` |  | 表头与单元格的水平对齐。默认 `start`。 |
| `ellipsis` | `boolean` |  | 单元格保持单行，超出用省略号截断；完整文本放在 `title` 里。 |
| `slot` | `string` |  | 渲染这一列单元格的插槽。默认 `cell-<key>`。 |
| `hideable` | `boolean` |  | 为 false 时不进入列设置，始终可见。默认 true。 |

### DataTableSort {#data-table-sort}

`FlareDataTableSort`

> DataTable 当前显示并上报的排序。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `key` | `string` | ✓ | 列的 key。 |
| `order` | `'asc' \| 'desc'` | ✓ | 方向。 |

### DataTablePagination {#data-table-pagination}

`FlareDataTablePagination`

> DataTable 的服务端分页：当前在第几页，以及总共有多少行；游标数据源则是后面是否还有一页。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `page` | `number` | ✓ | 当前页，从 1 起。 |
| `pageSize` | `number` | ✓ | 每页行数。 |
| `total` | `number` |  | 服务端总行数，不是本页行数。游标分页、无法计数的数据源不传。 |
| `hasNext` | `boolean` |  | 游标数据源：服务端在本页之后是否还有一页（即 `has_more`）。传了 `total` 时忽略。 |
| `pageSizes` | `number[]` |  | 可选的每页行数；省略则不画每页条数控件。 |

### PermissionNode {#permission-node}

`FlarePermissionNode`

> PermissionTree 的一个节点：一个权限码，或一组权限。

**被使用于：**[PermissionTree](/components/permission-tree)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `code` | `string` | ✓ | 叶子代表的权限码；父节点的 code 只用于分组。 |
| `name` | `string` | ✓ | 显示名称。 |
| `description` | `string` |  | 名称下的一行说明。 |
| `children` | [`FlarePermissionNode[]`](/reference/data-types#permission-node) |  | 子节点；有子节点的是分组。 |

### DescriptionItem {#description-item}

`FlareDescriptionItem`

> DescriptionList 的一行「标签 / 值」。

**被使用于：**[DescriptionList](/components/description-list)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `key` | `string` | ✓ | 这一行的稳定 id；也是 `item-<key>` 插槽的名字。 |
| `label` | `string` | ✓ | 值是什么。 |
| `value` | `string \| number \| null` |  | 值的文字，由宿主格式化。`null`、`undefined` 与空串表示「未设置」。 |
| `span` | `number` |  | 这一行跨的列数，不超过列表的列数。默认 1。 |
| `monospace` | `boolean` |  | 用等宽字体显示 —— id、代码、密钥。 |
| `copyable` | `boolean` |  | 在值后画一个复制键。 |

### ConfirmReason {#confirm-reason}

`FlareConfirmReason`

> DangerConfirm 在被审计的变更前要求填写的原因（审计原因）。

**被使用于：**[DangerConfirm](/components/danger-confirm)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `label` | `string` | ✓ | 字段标签，例如「审计原因」。 |
| `placeholder` | `string` |  | 字段占位文字。 |
| `hint` | `string` |  | 字段下的一行说明：谁会看到原因、记在哪里。 |
| `maxLength` | `number` |  | 字段最多接受的字符数。 |
| `maxBytes` | `number` |  | 去掉首尾空白后的原因最多占用的 UTF-8 字节数；超出时标记字段并锁住确认键。 |
| `optional` | `boolean` |  | 原因可以不填。默认 false。 |

### RedPacketClaim {#red-packet-claim}

`FlareRedPacketClaim`

> 红包领取列表的一行：名字和头像由宿主解析，金额与时间由 Kit 格式化。

**被使用于：**[RedPacketDetail](/components/red-packet-detail)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 领取人 id，也是头像种子。 |
| `name` | `string` | ✓ | 显示名。 |
| `avatar` | `string` |  | 头像 URL 或媒体 id。 |
| `amountMinor` | `string` | ✓ | 领取金额，最小单位。 |
| `claimedAtMs` | `number` | ✓ | 领取时间。 |
| `best` | `boolean` | ✓ | 服务端判定的手气最佳。 |

### LocationCoordinate {#location-coordinate}

`FlareLocationCoordinate`

> WGS-84 坐标（requestCurrentLocation 的返回）。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `latitude` | `number` | ✓ | 纬度，-90..90。 |
| `longitude` | `number` | ✓ | 经度，-180..180。 |

### LocationAddress {#location-address}

`FlareLocationAddress`

> 逆地址解析的结果。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `title` | `string` | ✓ | 地点名。 |
| `address` | `string` | ✓ | 地址。 |

### LocationPlace {#location-place}

`FlareLocationPlace`

> 选点页列出并发送的地点：附近 POI、搜索结果或当前位置（id 为 "current"）。

**被使用于：**[LocationPicker](/components/location-picker)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 稳定的地点 id；"current" 表示设备位置。 |
| `title` | `string` | ✓ | 地点名。 |
| `address` | `string` | ✓ | 地址。 |
| `latitude` | `number` | ✓ | WGS-84 纬度。 |
| `longitude` | `number` | ✓ | WGS-84 经度。 |
| `distanceM` | `number` |  | 距搜索中心的米数（宿主知道时）；显示为「120m」/「1.2km」。 |

### LocationValue {#location-value}

`FlareLocationValue`

> Vue 时间线在 locationOpen 里回传的位置消息；Flutter、SwiftUI、Compose 回传各自的位置内容。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `latitude` | `number` | ✓ | WGS-84 纬度（没有时为 NaN）。 |
| `longitude` | `number` | ✓ | WGS-84 经度。 |
| `title` | `string` | ✓ | 地点名。 |
| `address` | `string` | ✓ | 地址。 |
| `snapshotUrl` | `string` |  | 静态图地址。 |
| `provider` | [`LocationProvider`](/reference/data-types#location-provider) |  | 载荷里的地图服务，没有时为 osm。 |

### ContactPickerEntry {#contact-picker-entry}

`FlareContactPickerEntry`

> 联系人选择器可以返回的一个人。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `userId` | `string` | ✓ | 用户 id；名片里带的就是它。 |
| `name` | `string` | ✓ | 显示名；参与搜索。 |
| `avatarUrl` | `string` |  | 头像地址。 |
| `subtitle` | `string` |  | 副标题（部门、用户名）；参与搜索。 |
| `isSelf` | `boolean` |  | 当前登录用户：显示「（我）」，仍可选择。 |

### ContactPickerGroup {#contact-picker-group}

`FlareContactPickerGroup`

> 联系人选择器的一个标签页。

**被使用于：**[ContactPicker](/components/contact-picker)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | friends、groupMembers 或宿主自己的 id。 |
| `label` | `string` |  | 标签文案；friends、groupMembers 由 Kit 提供。 |
| `entries` | [`ContactPickerEntry[]`](/reference/data-types#contact-picker-entry) | ✓ | 该标签下的人，按显示顺序。 |

### PluginViewModel {#plugin-view-model}

`FlarePluginViewModel`

> 解析后的插件视图（核心 SDK 的 ResolvedPluginView）。

**被使用于：**[PluginView](/components/plugin-view) · [PluginDetailSheet](/components/plugin-detail-sheet)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `available` | `boolean` | ✓ | 为假时只显示标题（插件停用、历史卡片）。 |
| `title` | `string` | ✓ | 卡片标题。 |
| `fields` | `{label, value}[]` | ✓ | 键值行（v1）。 |
| `actions` | [`PluginAction[]`](/reference/data-types#plugin-action) | ✓ | 底部动作，文案已翻译；块持有的动作不在这里。 |
| `blocks` | [`PluginBlock[]`](/reference/data-types#plugin-block) |  | 展示块，按顺序；不认识的 kind 跳过。 |
| `inputs` | [`PluginInput[]`](/reference/data-types#plugin-input) |  | 文档的全部输入；动作的 form 列出它要收集的。 |
| `detail` | `boolean` |  | 贡献声明了 detail 视图（「查看全部」）。 |
| `nextCursor` | `string` |  | 详情与页面视图：下一页的游标（核心 SDK 分页，非空标量，至多 256 字节）。有值时 PluginDetailSheet 与 PluginPage 提供「加载更多」；宿主取下一页并把合并好的视图传回。 |
| `menuActions` | [`PluginAction[]`](/reference/data-types#plugin-action) |  | 卡片 ⋯ 菜单里的动作（placement menu），按顺序；为空时不出现。 |
| `unavailableReason` | `'disabled' \| 'not_installed' \| 'no_permission' \| 'unsupported_platform' \| 'incompatible_version' \| 'catalog_unreachable' \| 'unbound_copy'` |  | 视图不可用或只读的原因。 |

### PluginAction {#plugin-action}

`FlarePluginAction`

> 解析后的动作；target 和 input 对 Kit 不透明。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | 不透明 id，在 action(id, payload) 里回传。 |
| `label` | `string` | ✓ | 按钮文案。 |
| `style` | [`PluginActionStyle`](/reference/data-types#plugin-action-style) |  | primary 或 danger；不传为次要。 |
| `confirm` | `string` |  | 先在 Kit 的 DangerConfirm 里确认的文案。 |
| `form` | `string[]` |  | 先用 PluginForm 收集的输入 id。 |

### PluginBlock {#plugin-block}

`FlarePluginBlock`

> 一个展示块，按 kind 区分（各自形状见 spec/plugin-view-vectors.json）。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `kind` | `'text' \| 'fields' \| 'choices' \| 'entries' \| 'people' \| 'status' \| 'progress' \| 'time' \| 'divider' \| 'note' \| 'rows'` | ✓ | 块类型；rows 用于插件页面（四端都是列表）和 Vue 控制台（表格）。 |
| `text` | `{text, maxLines?, style: 'body' \| 'title' \| 'secondary'}` |  | 可折叠文本，带「展开」。 |
| `fields` | `{fields: {label, value}[]}` |  | 键值行。 |
| `choices` | `{options: PluginChoice[], multiple, voted, closed, showResults, total?, inputName, maxSelections?, action?: PluginAction}` |  | 选项列表；action 是块持有的提交动作。maxSelections（只在多选，1..=选项数）限制草稿：选满后草稿以外的选项禁用。 |
| `entries` | `{items: {index, text, name?, userId?, group?: {key, label, count?, total?, percent?}, badge?: PluginBadge}[], numbered, grouped?, total, more, emptyText?}` |  | 名单（接龙、投票人、账单）；分组名单在带 group 的条目前插组头；条目的 badge 画在正文之前。 |
| `people` | `{groups: {label, userIds, count, tone?}[]}` |  | 每组一行头像叠加计数。 |
| `status` | `{label?, text, tone}` |  | 徽标。 |
| `progress` | `{label?, value, total, percent}` |  | 进度条加 value/total。 |
| `time` | `{label?, atMs, endMs?, countdown}` |  | 时间点或区间，可倒计时。 |
| `note` | `{text, tone?}` |  | 带色调的提示。 |
| `rows` | `{source, columns: {label, format}[], rows: {key, cells: {text, timeMs?}[], actions: {id, input}[], detailInput?, badge?: PluginBadge}[], nextCursor?, actions: PluginAction[], emptyText?, filters?: string[]}` |  | 插件页面的行（四端都是列表：徽标与第一格、其余单元格、动作键；同一 key 只画一次；随页分页）或 Vue 控制台表格的行。filters 列出作为页面筛选项的输入 id（不带时为全部输入）；其余输入归动作表单（flarePluginFilterInputs）。 |

### PluginChoice {#plugin-choice}

`FlarePluginChoice`

> choices 块的一个选项。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `index` | `number` | ✓ | 下标，作为 selection 提交。 |
| `label` | `string` | ✓ | 选项文字。 |
| `selected` | `boolean` | ✓ | 当前用户选了它。 |
| `count` | `number` |  | 票数（显示结果时）。 |
| `percent` | `number` |  | 0..100（显示结果时）。 |

### PluginInput {#plugin-input}

`FlarePluginInput`

> 解析后的表单输入（UiInput）。

**被使用于：**[PluginForm](/components/plugin-form)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `id` | `string` | ✓ | formValues 里的键。 |
| `kind` | [`PluginInputKind`](/reference/data-types#plugin-input-kind) | ✓ | 控件类型。 |
| `label` | `string` | ✓ | 字段名。 |
| `required` | `boolean` |  | 必填。 |
| `placeholder` | `string` |  | 占位文字。 |
| `maxLength` | `number` |  | 字数上限（默认 text 256、textarea 2000、options 每项 100）。 |
| `min` | `number` |  | number 的最小值；options、members 的最少条数。 |
| `max` | `number` |  | number 的最大值；options、members 的最多条数（members 为 1 时单选）。 |
| `default` | `unknown` |  | 初值。 |
| `choices` | `{value, label}[]` |  | 仅 select。 |

### PluginFormError {#plugin-form-error}

`FlarePluginFormError`

> 提交值的一个问题（UiFormError）。

**被使用于：**[PluginView](/components/plugin-view) · [PluginForm](/components/plugin-form) · [PluginDetailSheet](/components/plugin-detail-sheet) · [PluginPage](/components/plugin-page)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `input` | `string` | ✓ | 输入 id。 |
| `issue` | [`PluginFormIssue`](/reference/data-types#plugin-form-issue) | ✓ | 问题类型。 |

### PluginUser {#plugin-user}

`FlarePluginUser`

> resolveUser 对一个 userId 的回答。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `name` | `string` | ✓ | 显示名。 |
| `avatarUrl` | `string` |  | 头像；没有或加载失败时显示首字母。 |

### PluginMember {#plugin-member}

`FlarePluginMember`

> members 输入的候选成员。

**被使用于：**[PluginView](/components/plugin-view) · [PluginForm](/components/plugin-form) · [PluginDetailSheet](/components/plugin-detail-sheet) · [PluginPage](/components/plugin-page)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `userId` | `string` | ✓ | 提交的 id。 |
| `name` | `string` | ✓ | 显示名。 |
| `avatarUrl` | `string` |  | 头像。 |

### PluginActionPayload {#plugin-action-payload}

`FlarePluginActionPayload`

> action(id, payload) 携带的内容。

**原生符号：**

- Flutter: `FlarePluginActionPayload` — row 为 FlarePluginRowInput，record typedef ({String key, Object? input})。
- SwiftUI: `PluginActionPayload` — row 为 PluginRowRef {key, input: [String: PluginJSONValue]}。
- Compose: `PluginActionPayload` — row 为 PluginActionRow(key, input)。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `selection` | `number[]` |  | 选中的选项下标（choices），升序。 |
| `formValues` | `Record<string, unknown>` |  | 按输入 id 的表单提交值。 |
| `row` | `{key, input}` |  | 行动作所在的行。 |

### PluginBadge {#plugin-badge}

`FlarePluginBadge`

> 条目或行的枚举值对应的文字与语义色（插件的 valueLabels），如账单行的类型。

**原生符号：**

- Flutter: `FlarePluginBadge`
- SwiftUI: `PluginBadge`
- Compose: `PluginBadge`

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `text` | `string` | ✓ | 文字，已翻译；未映射的值原样显示。 |
| `tone` | [`PluginTone`](/reference/data-types#plugin-tone) | ✓ | Kit 标签的语义色；未知值按 neutral 画。 |

### PluginPageRef {#plugin-page-ref}

`FlarePluginPageRef`

> PluginPage 显示的页面，与 invokePageAction 的写法一致。

**被使用于：**[PluginPage](/components/plugin-page)

**原生符号：**

- Flutter: `FlarePluginPageRef`
- SwiftUI: `PluginPageRef`
- Compose: `PluginPageRef`

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `pluginId` | `string` | ✓ | 插件 id。 |
| `page` | `string` | ✓ | page 贡献的 id。 |

### PluginPageViewModel {#plugin-page-view-model}

`FlarePluginPageViewModel`

> 解析后的插件页面（核心 SDK pluginPage 的结果）：PluginViewModel 的全部字段（nextCursor 是页面的下一页，rows 与 entries 随页分页）加 data。不可用的页面为 {available: false, title: "", unavailableReason}。

**被使用于：**[PluginPage](/components/plugin-page)

**原生符号：**

- Flutter: `FlarePluginPageViewModel` — 继承 FlarePluginViewModel，多一个 data。
- SwiftUI: `PluginPageViewModel` — 包装形 {view: PluginViewModel, data: PluginJSONValue?}；@dynamicMemberLookup 直接读视图字段。
- Compose: `PluginPageViewModel` — 包装形 data class {view: PluginViewModel, data: Map<String, Any?>?}，带 fromJson / fromMap（Kotlin data class 不能继承）。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `data` | `Record<string, unknown>` |  | 页面解析所依据的数据（第一页的数据源结果，没有数据源时为页面参数）；只在可用时有。页面动作原样带回。 |

### PluginPageActionPayload {#plugin-page-action-payload}

`FlarePluginPageActionPayload`

> PluginPage 的 action(id, payload) 携带的内容：即 invokePageAction 的请求，不含平台与手势。

**原生符号：**

- Flutter: `FlarePluginPageActionPayload` — 继承 FlarePluginActionPayload；toJson() 即请求。
- SwiftUI: `PluginPageActionPayload` — 编码结果即请求；有 init(page:view:payload:)。
- Compose: `PluginPageActionPayload` — toJson() 即请求；有 of(page, view, payload)。

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `page` | [`PluginPageRef`](/reference/data-types#plugin-page-ref) | ✓ | 页面，来自 page 属性。 |
| `data` | `Record<string, unknown>` |  | view.data（视图有时）。 |
| `row` | `{key, input}` |  | 行动作所在的行：key 与视图为该动作绑定的入参（rows[].actions[].input）。 |
| `selection` | `number[]` |  | choices 提交的选项下标，升序。 |
| `formValues` | `Record<string, unknown>` |  | 动作表单收集到的值（有表单时）。 |

### MessageReadSummary {#message-read-summary}

`FlareMessageReadSummary`

> SDK 给出的本人群消息已读摘要（MessageReceiptView.readSummary）。

**被使用于：**[MessageMeta](/components/message-meta)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `readCount` | `number` | ✓ | 已读人数。 |
| `unreadCount` | `number` | ✓ | 未读人数。 |
| `total` | `number` | ✓ | 发送对象人数。 |

### RedPacketDetailsView {#red-packet-details-view}

`FlareRedPacketDetailsView`

> 插件 details 对某个查看者的结果；无权看的金额不出现。

**被使用于：**[RedPacketDetail](/components/red-packet-detail)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `viewerRole` | [`RedPacketViewerRole`](/reference/data-types#red-packet-viewer-role) | ✓ | 查看者角色。 |
| `status` | [`RedPacketStatus`](/reference/data-types#red-packet-status) | ✓ | 红包状态。 |
| `kind` | [`RedPacketKind`](/reference/data-types#red-packet-kind) | ✓ | 红包种类。 |
| `greeting` | `string` | ✓ | 祝福语。 |
| `currency` | `string` | ✓ | ISO 4217 币种代码。 |
| `currencyExponent` | `number` | ✓ | 币种小数位。 |
| `totalMinor` | `string` |  | 总额，最小单位（仅发送人）。 |
| `claimedMinor` | `string` |  | 已领额，最小单位（仅发送人）。 |
| `refundedMinor` | `string` |  | 退回额，最小单位（仅发送人）。 |
| `myAmountMinor` | `string` |  | 本人领到的金额，最小单位。 |
| `claimedCount` | `number` | ✓ | 已领份数。 |
| `shareCount` | `number` | ✓ | 总份数。 |
| `createdAtMs` | `number` | ✓ | 创建时间。 |
| `completedAtMs` | `number` |  | 领完时间。 |
| `expiresAtMs` | `number` | ✓ | 过期时间。 |
| `refundedAtMs` | `number` |  | 退回时间。 |
| `claimsListed` | `boolean` | ✓ | 查看者可以看领取记录。 |

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

### ComposerActionKind {#composer-action-kind}

`FlareComposerActionKind`

> 「+」项的来源：内置功能，或已授权插件声明的输入栏入口；宿主自己的项可以不传。

`feature` · `plugin`

### ComposerToolId {#composer-tool-id}

`FlareComposerToolId`

> 输入栏工具条工具 id，四端相同；attachments 即「+」按钮。

`emoji` · `mention` · `voice` · `image` · `richText` · `attachments`

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

### RedPacketOpenState {#red-packet-open-state}

`FlareRedPacketOpenState`

> 开红包浮层的阶段。

**被使用于：**[RedPacketOpenSheet](/components/red-packet-open-sheet)

`ready` · `opening` · `finished` · `expired` · `notEligible` · `error`

### RedPacketKind {#red-packet-kind}

`FlareRedPacketKind`

> 发红包表单可提供的种类。

**被使用于：**[RedPacketCard](/components/red-packet-card) · [RedPacketComposer](/components/red-packet-composer)

`lucky` · `normal` · `exclusive`

### LocationProvider {#location-provider}

`FlareLocationProvider`

> 租户配置的地图服务，决定位置卡片打开哪个网页地图。

**被使用于：**[LocationMessage](/components/location-message) · [LocationPicker](/components/location-picker)

`osm` · `amap`

### PluginActionStyle {#plugin-action-style}

`FlarePluginActionStyle`

> 动作按钮的样式。

`primary` · `danger`

### PluginTone {#plugin-tone}

`FlarePluginTone`

> 状态、提示和人员分组的语义色，用 *Text 系列令牌着色。

`neutral` · `info` · `success` · `warning` · `danger`

### PluginInputKind {#plugin-input-kind}

`FlarePluginInputKind`

> 表单输入类型。

`text` · `textarea` · `number` · `toggle` · `select` · `datetime` · `options` · `members`

### PluginFormIssue {#plugin-form-issue}

`FlarePluginFormIssue`

> 表单错误类型（UiFormIssue）。

`required` · `unknown` · `invalidType` · `tooLong` · `outOfRange` · `notAChoice` · `tooFewItems` · `tooManyItems` · `invalidItem` · `duplicateItem`

### PluginViewInset {#plugin-view-inset}

`FlarePluginViewInset`

> PluginView 所在位置的内边距：none；sheet —— 直接放进 Kit 面板（md / lg / xl）；sheetTop —— 放在面板顶部、下面还有内容（如 PluginForm 上方的前言）（md / lg / 0）。

**被使用于：**[PluginView](/components/plugin-view)

`none` · `sheet` · `sheetTop`

### PluginRowsLayout {#plugin-rows-layout}

`FlarePluginRowsLayout`

> Vue PluginView 画 rows 块的方式：table（Kit DataTable，控制台管理列表）或 list（每行一项，插件页面）。

**被使用于：**[PluginView](/components/plugin-view)

**原生符号：**

- Flutter: 无 — 不需要：rows 一律画成列表。
- SwiftUI: 无 — 不需要：rows 一律画成列表。
- Compose: 无 — 不需要：rows 一律画成列表。

`table` · `list`

### MessageSurface {#message-surface}

`FlareMessageSurface`

> 消息行内容所在的表面（spec/message-surface-vectors.json）。

**被使用于：**[MessageBubble](/components/message-bubble)

`bubble` · `bareMedia` · `card` · `centered`

### MessageMetaPlacement {#message-meta-placement}

`FlareMessageMetaPlacement`

> 消息时间与回执所在的位置（spec/message-meta-placement-vectors.json）。

**被使用于：**[MessageMeta](/components/message-meta)

`inline` · `bubbleFooter` · `below` · `none`

### RedPacketCardState {#red-packet-card-state}

`FlareRedPacketCardState`

> 红包卡片显示的状态（spec/red-packet-vectors.json cardState）。

**被使用于：**[RedPacketCard](/components/red-packet-card)

`unopened` · `viewable` · `claimed` · `finished` · `expired` · `refunded`

### RedPacketStatus {#red-packet-status}

`FlareRedPacketStatus`

> 插件给出的红包状态（公开层）。

`open` · `completed` · `expired` · `refunded`

### RedPacketViewerRole {#red-packet-viewer-role}

`FlareRedPacketViewerRole`

> 服务端判定的详情查看者角色。

`sender` · `claimer` · `eligible` · `ineligible`
