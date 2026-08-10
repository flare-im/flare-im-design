---
title: Data Types
---

# Data Types

> Shared data structures used by component props. Feed these objects to the components from your own data source — the components carry no SDK coupling.

## Interfaces

### Contact {#contact}

`FlareContact`

> A directory contact.

**Used by: **[ContactList](/en/components/contact-list) · [ContactItem](/en/components/contact-item) · [ContactDetail](/en/components/contact-detail)

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

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `key` | `string` | ✓ | Stable row key emitted on interaction. |
| `label` | `string` | ✓ | Row label. |
| `icon` | `string` |  | Leading icon name. |
| `kind` | [`FlareSettingKind`](/en/reference/data-types#setting-kind) |  | Row kind — navigation, toggle or value. |
| `value` | `boolean` |  | Toggle state (for `kind: "toggle"`). |
| `detail` | `string` |  | Trailing detail text (for `kind: "value"`). |

### SettingsSection {#settings-section}

`FlareSettingsSection`

> A titled group of settings rows.

**Used by: **[SettingsList](/en/components/settings-list)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `title` | `string` |  | Optional section header. |
| `items` | [`FlareSettingsItem[]`](/en/reference/data-types#settings-item) | ✓ | Rows in this section. |

### NavItem {#nav-item}

`FlareNavItem`

> A primary navigation entry.

**Used by: **[AppShell](/en/components/app-shell)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `key` | `string` | ✓ | Route/tab key. |
| `label` | `string` | ✓ | Nav label. |
| `icon` | `string` |  | Icon name. |
| `badge` | `number` |  | Unread/notification badge count. |

### ConversationRowModel {#conversation-row-model}

`FlareConversationRowModel`

> Package-owned conversation row view state (no SDK coupling).

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
| `draft` | `string` |  | Unsent draft; shown with a draft tag. |
| `lastMessage` | `{ text?; time?; content? } \| null` |  | Structured last message (alternative to preview). |
| `pinned` | `boolean` |  | Pinned to the top. |
| `muted` | `boolean` |  | Notifications muted. |
| `archived` | `boolean` |  | Archived out of the main list. |

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
| `pct` | `number` | ✓ | Result percentage (0–100) for the bar. |

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

## Enums / unions

### SettingKind {#setting-kind}

`FlareSettingKind`

> How a settings row renders and behaves.

`navigation` · `toggle` · `value`

### ConversationAction {#conversation-action}

`FlareConversationAction`

> Actions emitted from a conversation row/details.

`open` · `mark_read` · `mark_unread` · `pin` · `unpin` · `mute` · `unmute` · `archive` · `unarchive` · `clear_history` · `delete`

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

`auto` · `pc` · `ipad` · `h5`

### DensityMode {#density-mode}

`FlareDensityMode`

> UI density.

`comfortable` · `compact`
