---
title: 数据类型
---

# 数据类型

> 组件 props 里用到的共享数据结构。从你自己的数据源把这些对象喂给组件即可——组件不耦合 SDK。

## 接口

### Contact {#contact}

`FlareContact`

> 通讯录联系人。

**被使用于：**[ContactList](/components/contact-list) · [ContactItem](/components/contact-item) · [ContactDetail](/components/contact-detail)

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

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `key` | `string` | ✓ | 稳定行键，交互时回传。 |
| `label` | `string` | ✓ | 行标题。 |
| `icon` | `string` |  | 前置图标名。 |
| `kind` | [`FlareSettingKind`](/reference/data-types#setting-kind) |  | 行类型——导航 / 开关 / 取值。 |
| `value` | `boolean` |  | 开关状态（`kind: "toggle"` 时）。 |
| `detail` | `string` |  | 尾部详情文本（`kind: "value"` 时）。 |

### SettingsSection {#settings-section}

`FlareSettingsSection`

> 带标题的设置分组。

**被使用于：**[SettingsList](/components/settings-list)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `title` | `string` |  | 分组标题（可选）。 |
| `items` | [`FlareSettingsItem[]`](/reference/data-types#settings-item) | ✓ | 分组内的行。 |

### NavItem {#nav-item}

`FlareNavItem`

> 主导航项。

**被使用于：**[AppShell](/components/app-shell)

| 名称 | 类型 | 必填 | 说明 |
|---|---|:---:|---|
| `key` | `string` | ✓ | 路由/标签键。 |
| `label` | `string` | ✓ | 导航文案。 |
| `icon` | `string` |  | 图标名。 |
| `badge` | `number` |  | 未读/通知徽标数。 |

### ConversationRowModel {#conversation-row-model}

`FlareConversationRowModel`

> 包自有的会话行视图状态（不耦合 SDK）。

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
| `draft` | `string` |  | 未发送草稿；带草稿标签显示。 |
| `lastMessage` | `{ text?; time?; content? } \| null` |  | 结构化最后消息（预览的替代来源）。 |
| `pinned` | `boolean` |  | 置顶。 |
| `muted` | `boolean` |  | 已免打扰。 |
| `archived` | `boolean` |  | 已归档。 |

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
| `pct` | `number` | ✓ | 结果百分比（0–100），用于进度条。 |

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

### SettingKind {#setting-kind}

`FlareSettingKind`

> 设置行的渲染与行为方式。

`navigation` · `toggle` · `value`

### ConversationAction {#conversation-action}

`FlareConversationAction`

> 会话行/详情抛出的操作。

`open` · `mark_read` · `mark_unread` · `pin` · `unpin` · `mute` · `unmute` · `archive` · `unarchive` · `clear_history` · `delete`

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

`auto` · `pc` · `ipad` · `h5`

### DensityMode {#density-mode}

`FlareDensityMode`

> 界面密度。

`comfortable` · `compact`
