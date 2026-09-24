---
title: Data Types
---

# Data Types

> Shared data structures used by component props. Feed these objects to the components from your own data source — the components carry no SDK coupling.

## Interfaces

### ConversationIdentity {#conversation-identity}

`FlareConversationIdentity`

> Host-owned identity for an active direct, group, channel, bot, or system conversation.

**Used by: **[ConversationHeader](/en/components/conversation-header)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Stable conversation identity and avatar seed. |
| `title` | `string` | ✓ | Primary conversation title. |
| `kind` | `'direct' \| 'group' \| 'channel' \| 'bot' \| 'system'` |  | Conversation semantics used to choose the default preset. |
| `subtitle` | `string` |  | Host-formatted stable secondary line. |
| `avatarUrl` | `string` |  | Direct or group avatar URL. |
| `presence` | `'online' \| 'offline' \| 'busy' \| 'away'` |  | Presence supplied by the host. |
| `memberCount` | `number` |  | Group member summary when no subtitle is supplied. |
| `typingText` | `string` |  | Transient typing text with priority over subtitle. |
| `accessibilityLabel` | `string` |  | Localized header label for assistive technology. |
| `action` | [`ConversationHeaderAction`](/en/reference/data-types#conversation-header-action) |  | Optional capability-filtered host intent activated from the whole identity block (avatar, title and subtitle), e.g. open the conversation details. |

### ConversationHeaderAction {#conversation-header-action}

`FlareConversationHeaderAction`

> One SDK-agnostic host intent in the conversation header.

**Used by: **[ConversationHeader](/en/components/conversation-header)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Stable action id. |
| `label` | `string` | ✓ | Visible and accessible label. |
| `icon` | `string` |  | Cross-platform semantic icon name. |
| `placement` | `'primary' \| 'add' \| 'overflow'` |  | Primary toolbar, dedicated Plus menu, or overflow menu. |
| `group` | `string` |  | Optional menu grouping key. |
| `order` | `number` |  | Stable host priority. |
| `visible` | `boolean` |  | Temporary policy visibility. |
| `enabled` | `boolean` |  | Availability while retaining context. |
| `badge` | `string` |  | Optional compact badge. |
| `intent` | `string` |  | Host-defined intent payload key. |
| `capability` | `string` |  | Capability id required for display. |
| `accessibilityLabel` | `string` |  | Localized accessible label override. |
| `disabledReason` | `string` |  | Reason announced when disabled. |
| `pressed` | `boolean` |  | Makes the action a toggle; true renders it pressed (search open, details shown). |

### ActionItem {#action-item}

`FlareActionItem`

> The shared action descriptor: composer and header actions extend it, and ActionMenu draws it.

**Used by: **[ActionMenu](/en/components/action-menu)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Stable id, reported when selected. |
| `label` | `string` | ✓ | Visible label. |
| `icon` | `string` |  | Semantic kit icon name (Vue also accepts a glyph component). |
| `group` | `string` |  | Menus draw a separator where the group changes. |
| `order` | `number` |  | Priority used by producers that sort; menus keep host order. |
| `visible` | `boolean` |  | False hides the action. |
| `enabled` | `boolean` |  | False keeps the action visible but unavailable. |
| `badge` | `string` |  | Compact trailing text. |
| `intent` | `string` |  | Host-defined intent payload key. |
| `accessibilityLabel` | `string` |  | Localized accessible name override. |
| `disabledReason` | `string` |  | Why the action is unavailable; shown and announced with it. |
| `pressed` | `boolean` |  | Set to make the action a toggle; true draws it on (a pressed button, a checked menu item). |
| `danger` | `boolean` |  | Destructive: drawn in the error text colour. |

### ConversationHeaderCapabilities {#conversation-header-capabilities}

`FlareConversationHeaderCapabilities`

> The action capabilities declared by the host for one conversation context.

**Used by: **[ConversationHeader](/en/components/conversation-header)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `availableActionIds` | `string[]` |  | Allowed semantic action or capability ids; omitted means preset actions remain available. |

### ConversationHeaderConfiguration {#conversation-header-configuration}

`FlareConversationHeaderConfiguration`

> Host policy layered over the direct or group header preset without boolean feature flags.

**Used by: **[ConversationHeader](/en/components/conversation-header)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `replaceDefaults` | `boolean` |  | Start from no preset actions. |
| `removeActionIds` | `string[]` |  | Permanently remove preset or host actions by id. |
| `actionOverrides` | [`ConversationHeaderAction[]`](/en/reference/data-types#conversation-header-action) |  | Override labels, icons, placement, state, or order by stable id. |
| `maxPrimaryActions` | `number` |  | Desktop primary toolbar limit before More. |
| `compactMaxPrimaryActions` | `number` |  | Compact primary toolbar limit before More. |

### MessageIdentity {#message-identity}

`MessageIdentity`

> The two ids a message row answers to. Locating a message (a quote tap, a pinned bar, a search hit) matches either.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | The id the list draws the row with and every message intent carries. Vue derives it (`clientMsgId \|\| serverId`); the native kits take it as `FlareMessageData.id`. |
| `serverId` | `string?` |  | The core's id for the same message, when it has one. A quote names the message it quotes by this id, because it is the one every other client knows; a message still on its way has none. |

### MessageRowPresentation {#message-row-presentation}

`FlareMessageRowPresentation`

> Timeline-derived presentation context consumed by a message bubble.

**Used by: **[MessageBubble](/en/components/message-bubble)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `showAvatar` | `boolean` | ✓ | Render the sender avatar for this row. |
| `reserveAvatarSpace` | `boolean` | ✓ | Keep the group gutter stable when the avatar is hidden. |
| `showSenderName` | `boolean` | ✓ | Render the group sender name for this row. |
| `avatarPlacement` | `'leading' \| 'trailing'` | ✓ | Logical avatar side for incoming or optional self avatars. |

### Contact {#contact}

`FlareContact`

> A directory contact.

**Used by: **[ContactList](/en/components/contact-list) · [ContactItem](/en/components/contact-item) · [ContactDetail](/en/components/contact-detail) · [GroupDetail](/en/components/group-detail) · [ProfileCard](/en/components/profile-card) · [GroupMemberGrid](/en/components/group-member-grid) · [ReadReceiptSheet](/en/components/read-receipt-sheet)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Stable unique id. |
| `name` | `string` | ✓ | Display name. |
| `avatarUrl` | `string` |  | Avatar image URL; falls back to initials when absent. |
| `signature` | `string` |  | Personal bio / signature line. |
| `presence` | `"online" \| "offline" \| "busy" \| "away"` |  | Presence state shown as a status dot. |
| `indexKey` | `string` |  | Explicit A–Z index letter; derived from name when absent. |

### FriendRequest {#friend-request}

`FlareFriendRequest`

> An incoming friend/contact request.

**Used by: **[NewFriendRequests](/en/components/new-friend-requests)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Request id. |
| `name` | `string` | ✓ | Requester display name. |
| `avatarUrl` | `string` |  | Requester avatar URL. |
| `message` | `string` |  | Optional greeting attached to the request. |
| `direction` | `'incoming' \| 'outgoing'` |  | Whether the viewer received or sent the request; defaults to incoming. |

### GroupSummary {#group-summary}

`FlareGroupSummary`

> A group shown in a group list.

**Used by: **[GroupList](/en/components/group-list)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Group id. |
| `name` | `string` | ✓ | Group name. |
| `avatarUrl` | `string` |  | Group avatar URL. |
| `memberCount` | `number` |  | Member count shown as a subtitle. |

### UserProfile {#user-profile}

`FlareUserProfile`

> The signed-in user's profile.

**Used by: **[ProfilePanel](/en/components/profile-panel) · [ProfileEditor](/en/components/profile-editor)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | User id. |
| `name` | `string` | ✓ | Display name. |
| `avatarUrl` | `string` |  | Avatar URL. |
| `signature` | `string` |  | Bio / signature line. |
| `flareId` | `string` |  | Optional external/business id shown on the profile. |

### SettingsItem {#settings-item}

`FlareSettingsItem`

> One row in a settings section.

**Used by: **[SettingsRow](/en/components/settings-row)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `key` | `string` | ✓ | Stable row key emitted on interaction. |
| `label` | `string` | ✓ | Row label. |
| `icon` | `string` |  | Leading icon: a semantic name from the shared registry (an unknown name draws the registry's fallback glyph). |
| `kind` | [`FlareSettingKind`](/en/reference/data-types#setting-kind) |  | Row kind: navigation opens a page or picker (chevron), toggle is a switch, action runs in place (no chevron), value is read-only information and not a control. |
| `value` | `boolean` |  | Toggle state (for `kind: "toggle"`). |
| `detail` | `string` |  | Trailing detail text: the current value of a navigation row, or the information of a value row. Long text stacks under the label. |

### SettingsSection {#settings-section}

`FlareSettingsSection`

> A titled group of settings rows.

**Used by: **[SettingsList](/en/components/settings-list)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `title` | `string` |  | Optional section header. |
| `items` | [`FlareSettingsItem[]`](/en/reference/data-types#settings-item) | ✓ | Rows in this section. |

### ConversationRowModel {#conversation-row-model}

`FlareConversationRowModel`

> Package-owned conversation row view state (no runtime coupling).

**Used by: **[ConversationList](/en/components/conversation-list) · [ConversationRow](/en/components/conversation-row)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Conversation id. |
| `displayName` | `string` |  | Conversation title. |
| `avatarUrl` | `string` |  | Conversation avatar URL. |
| `updatedAt` | `number \| string` |  | Last-activity timestamp for ordering/time display. |
| `unreadCount` | `number` |  | Unread badge count. |
| `lastMessagePreview` | `string` |  | Rendered last-message preview text. |
| `previewPending` | `boolean` |  | Preview is still syncing. |
| `draft` | `string` |  | Unsent draft, rendered as a preview prefix. |
| `lastMessage` | `{ text?; time?; content? } \| null` |  | Structured last message (alternative to preview). |
| `pinned` | `boolean` |  | Pinned to the top. |
| `muted` | `boolean` |  | Notifications muted. |
| `archived` | `boolean` |  | Archived out of the main list. |
| `timestampLabel` | `string` |  | Host-formatted locale/timezone-aware timestamp. |
| `mentioned` | `boolean` |  | Unread mention. |
| `typing` | `boolean` |  | Typing, below draft and failure priority. |
| `failed` | `boolean` |  | Last send failed, highest preview priority. |

### PinnedMessageItem {#pinned-message-item}

`PinnedMessageItem`

> A pinned message shown in the pinned bar.

**Used by: **[PinnedMessageBar](/en/components/pinned-message-bar)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `serverId` | `string` | ✓ | Server message id. |
| `clientMsgId` | `string` | ✓ | Client message id. |
| `senderDisplayName` | `string` | ✓ | Sender name shown on the pin. |
| `content` | `{ contentType?; data? }` |  | Message content used to render the preview. |

### VoteOption {#vote-option}

`FlareVoteOption`

> One option in a vote/poll message.

**Used by: **[VoteMessage](/en/components/vote-message)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `text` | `string` | ✓ | Option label. |
| `pct` | `number \| null` |  | Known result percentage (0–100). Omit or pass null when results are unavailable; never fabricate zero. |

### MediaResolveRequest {#media-resolve-request}

`FlareMediaResolveRequest`

> What a `MediaResolver` receives to produce a displayable URL.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `kind` | [`FlareMediaKind`](/en/reference/data-types#media-kind) | ✓ | Media kind being resolved. |
| `messageId` | `string` |  | Owning message id. |
| `fileId` | `string` |  | Backend file id. |
| `url` | `string` |  | Pre-known URL, if any. |
| `localPath` | `string` |  | Local cached path, if any. |
| `mimeType` | `string` |  | MIME type hint. |
| `fileName` | `string` |  | Original file name. |

### InviteCodeCheckResult {#invite-code-check-result}

`FlareInviteCodeCheckResult`

> Result of the host's invite-code pre-check.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `valid` | `boolean` | ✓ | The code can be used to register. |
| `inviterDisplayName` | `string` |  | Masked display name of the inviter the code resolves to. |

### ReferralStats {#referral-stats}

`FlareReferralStats`

> Referral counts per depth for the current person.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `direct` | `number` | ✓ | People who registered with this person's code. |
| `l2` | `number` | ✓ | Second-level referrals. |
| `l3` | `number` | ✓ | Third-level referrals. |
| `total` | `number` | ✓ | Whole team size as the server counts it. |

### Invitee {#invitee}

`FlareInvitee`

> One person invited directly by the current person.

**Used by: **[MyInvitePanel](/en/components/my-invite-panel)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `userId` | `string` | ✓ | Stable identity; echoed by `select` and used as avatar seed. |
| `displayName` | `string` | ✓ | Display name. |
| `avatarUrl` | `string` |  | Avatar URL when the host has one. |
| `joinedAt` | `number` | ✓ | Registration time, epoch milliseconds. |

## Enums / unions

### MessageGroupPosition {#message-group-position}

`FlareMessageGroupPosition`

> A timeline-computed position in a same-sender message run.

**Used by: **[MessageBubble](/en/components/message-bubble)

`single` · `first` · `middle` · `last`

### SettingKind {#setting-kind}

`FlareSettingKind`

> How a settings row renders and behaves.

`navigation` · `toggle` · `value` · `action`

### ConversationAction {#conversation-action}

`FlareConversationAction`

> Conversation action ids shared by the row menu, ConversationActionSheet and the action payload on every platform.

`pin` · `unpin` · `mute` · `unmute` · `markRead` · `markUnread` · `archive` · `unarchive` · `hide` · `clearHistory` · `delete`

### GroupJoinPolicy {#group-join-policy}

`FlareGroupJoinPolicy`

> How people join a group. Hosts map their SDK codes to these values; null or nil means the host does not know.

`open` · `approval` · `invite`

### ConversationFilter {#conversation-filter}

`FlareConversationFilter`

> Conversation-list filter tabs.

`all` · `unread` · `mention` · `pinned` · `muted` · `archived` · `draft`

### ComposerState {#composer-state}

`FlareComposerState`

> Composer status driving hints and disabled state.

`idle` · `typing` · `sending` · `failed` · `disabled` · `offline` · `permissionDenied` · `capabilityUnavailable` · `runtimeUnavailable`

### MediaKind {#media-kind}

`FlareMediaKind`

> Media variant a resolver is asked for.

`image` · `imageThumbnail` · `imageGroupItem` · `video` · `videoCover` · `audio` · `file` · `string (custom)`

### ViewportKind {#viewport-kind}

`FlareViewportKind`

> Resolved viewport class.

`pc` · `ipad` · `h5`

### LayoutMode {#layout-mode}

`FlareLayoutMode`

> Layout override mode.

**Used by: **[ConfigProvider](/en/components/config-provider)

`auto` · `pc` · `ipad` · `h5`
