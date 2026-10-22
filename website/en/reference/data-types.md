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
| `tail` | `boolean` | ✓ | Draw the bubble tail: a bubble surface ending its run (spec/message-grouping-vectors.json). |

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
| `source` | `string` |  | Where the request came from, already worded by the host ("Added from a contact card, shared by X"); drawn as its own secondary line under the message. |
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

### ComposerCapabilities {#composer-capabilities}

`FlareComposerCapabilities`

> Host-owned availability of the composer's "+" actions and toolbar tools; presentation only, the server still decides what may be sent.

**Used by: **[Composer](/en/components/composer) · [ComposerActionPanel](/en/components/composer-action-panel)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `availableActionIds` | `string[]` |  | "+" panel ids to keep; omitted keeps every action. |
| `availableToolIds` | [`ComposerToolId[]`](/en/reference/data-types#composer-tool-id) |  | Toolbar tools to show (emoji, mention, voice, image, richText, attachments — the "+" button); omitted shows every tool, a list shows only the tools it names. SwiftUI spells it availableToolIDs. |
| `mentions` | `boolean` |  | Whether the conversation supports @ at all (false for a direct chat); Flutter, SwiftUI and Compose take the composer's own mention switch. |

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

### ChartPoint {#chart-point}

`FlareChartPoint`

> One reading of a ChartCard series.

**Used by: **[ChartCard](/en/components/chart-card)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `label` | `string` | ✓ | What the reading is for — a date, a period, a name — already formatted by the host. |
| `value` | `number \| null` | ✓ | The reading. `null` when there is none for this label (a gap); never substitute zero. |

### DataTableColumn {#data-table-column}

`FlareDataTableColumn`

> One column of a DataTable.

**Used by: **[DataTable](/en/components/data-table)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `key` | `string` | ✓ | Field of the row this column reads; also names the `cell-<key>` slot. |
| `title` | `string` | ✓ | Header text; on a narrow container it labels every stacked cell. |
| `width` | `number \| string` |  | Fixed width (a number is px). |
| `minWidth` | `number \| string` |  | Lower bound when the table shares the space out. |
| `sortable` | `boolean` |  | Draw a sort control in the header; the host sorts and passes `sort` back. |
| `align` | `'start' \| 'center' \| 'end'` |  | Horizontal alignment of the header and the cells. Default `start`. |
| `ellipsis` | `boolean` |  | Keep the cell on one line and cut it with an ellipsis; the full text stays in `title`. |
| `slot` | `string` |  | Slot that renders this column's cells. Default `cell-<key>`. |
| `hideable` | `boolean` |  | False keeps the column out of the column chooser: it is always visible. Default true. |

### DataTableSort {#data-table-sort}

`FlareDataTableSort`

> The sort a DataTable shows and reports.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `key` | `string` | ✓ | Column key. |
| `order` | `'asc' \| 'desc'` | ✓ | Direction. |

### DataTablePagination {#data-table-pagination}

`FlareDataTablePagination`

> Server-side paging of a DataTable: what page is shown, and how many rows exist or, for a cursor source, whether another page follows.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `page` | `number` | ✓ | 1-based current page. |
| `pageSize` | `number` | ✓ | Rows per page. |
| `total` | `number` |  | Rows on the server, not on this page. Omit it for a cursor-paged source that cannot count. |
| `hasNext` | `boolean` |  | Cursor sources: whether the server has a page after this one (its `has_more`). Ignored when `total` is given. |
| `pageSizes` | `number[]` |  | Page sizes the person may pick; omitted draws no page-size control. |

### PermissionNode {#permission-node}

`FlarePermissionNode`

> One node of a PermissionTree: a permission code, or a group of them.

**Used by: **[PermissionTree](/en/components/permission-tree)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `code` | `string` | ✓ | The permission code a leaf stands for; a parent's code only groups. |
| `name` | `string` | ✓ | Display name. |
| `description` | `string` |  | One line under the name. |
| `children` | [`FlarePermissionNode[]`](/en/reference/data-types#permission-node) |  | Child nodes; a node with children is a group. |

### DescriptionItem {#description-item}

`FlareDescriptionItem`

> One label / value line of a DescriptionList.

**Used by: **[DescriptionList](/en/components/description-list)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `key` | `string` | ✓ | Stable id of the line; also names the `item-<key>` slot. |
| `label` | `string` | ✓ | What the value is. |
| `value` | `string \| number \| null` |  | The value as text, formatted by the host. `null`, `undefined` and an empty string are "not set". |
| `span` | `number` |  | Columns this line spans; clamped to the list's columns. Default 1. |
| `monospace` | `boolean` |  | Draw the value in the monospaced face — ids, codes, keys. |
| `copyable` | `boolean` |  | Draw a copy key after the value. |

### ConfirmReason {#confirm-reason}

`FlareConfirmReason`

> The reason a DangerConfirm asks for before a recorded change (an audit reason).

**Used by: **[DangerConfirm](/en/components/danger-confirm)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `label` | `string` | ✓ | Field label, e.g. "Audit reason". |
| `placeholder` | `string` |  | Placeholder of the field. |
| `hint` | `string` |  | A line under the field: who reads the reason, where it is kept. |
| `maxLength` | `number` |  | Characters the field takes. |
| `maxBytes` | `number` |  | UTF-8 bytes the trimmed reason may take; more marks the field and holds the confirm key. |
| `optional` | `boolean` |  | The reason may be left empty. Default false. |

### RedPacketClaim {#red-packet-claim}

`FlareRedPacketClaim`

> One row of the red packet claim list: the host resolves name and avatar, the kit formats amount and time.

**Used by: **[RedPacketDetail](/en/components/red-packet-detail)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Claimant user id; seeds the avatar. |
| `name` | `string` | ✓ | Display name. |
| `avatar` | `string` |  | Avatar URL or media id. |
| `amountMinor` | `string` | ✓ | Claimed amount, minor units. |
| `claimedAtMs` | `number` | ✓ | Claim time. |
| `best` | `boolean` | ✓ | The server's best-luck mark. |

### LocationCoordinate {#location-coordinate}

`FlareLocationCoordinate`

> A WGS-84 coordinate (what requestCurrentLocation answers).

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `latitude` | `number` | ✓ | Latitude, -90..90. |
| `longitude` | `number` | ✓ | Longitude, -180..180. |

### LocationAddress {#location-address}

`FlareLocationAddress`

> What a reverse geocode answers for a coordinate.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `title` | `string` | ✓ | Place name. |
| `address` | `string` | ✓ | Address line. |

### LocationPlace {#location-place}

`FlareLocationPlace`

> A place the location picker lists and sends: a nearby POI, a search result or the current location (id "current").

**Used by: **[LocationPicker](/en/components/location-picker)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Stable place id; "current" is the device position. |
| `title` | `string` | ✓ | Place name. |
| `address` | `string` | ✓ | Address line. |
| `latitude` | `number` | ✓ | WGS-84 latitude. |
| `longitude` | `number` | ✓ | WGS-84 longitude. |
| `distanceM` | `number` |  | Distance from the search centre in metres, when the host knows it; drawn as "120m" / "1.2km". |

### LocationValue {#location-value}

`FlareLocationValue`

> A location message as the Vue timeline reports it in locationOpen; Flutter, SwiftUI and Compose pass their location content.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `latitude` | `number` | ✓ | WGS-84 latitude (NaN without one). |
| `longitude` | `number` | ✓ | WGS-84 longitude. |
| `title` | `string` | ✓ | Place name. |
| `address` | `string` | ✓ | Address line. |
| `snapshotUrl` | `string` |  | Static map URL. |
| `provider` | [`LocationProvider`](/en/reference/data-types#location-provider) |  | Map service named by the payload, osm when it names none. |

### ContactPickerEntry {#contact-picker-entry}

`FlareContactPickerEntry`

> One person the contact picker can return.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `userId` | `string` | ✓ | The person's user id; a contact card carries it. |
| `name` | `string` | ✓ | Display name; searched. |
| `avatarUrl` | `string` |  | Avatar URL. |
| `subtitle` | `string` |  | Secondary line (department, handle); searched. |
| `isSelf` | `boolean` |  | The signed-in user: drawn with "(me)" and still selectable. |

### ContactPickerGroup {#contact-picker-group}

`FlareContactPickerGroup`

> One tab of the contact picker.

**Used by: **[ContactPicker](/en/components/contact-picker)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | friends, groupMembers or the host's own id. |
| `label` | `string` |  | Tab label; the kit labels friends and groupMembers itself. |
| `entries` | [`ContactPickerEntry[]`](/en/reference/data-types#contact-picker-entry) | ✓ | The people in the tab, in display order. |

### PluginViewModel {#plugin-view-model}

`FlarePluginViewModel`

> A resolved plugin view (core SDK ResolvedPluginView).

**Used by: **[PluginView](/en/components/plugin-view) · [PluginDetailSheet](/en/components/plugin-detail-sheet) · [PluginPage](/en/components/plugin-page)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `available` | `boolean` | ✓ | False: only the title shows (disabled plugin, history). |
| `title` | `string` | ✓ | Card title. |
| `fields` | `{label, value}[]` | ✓ | Label/value rows (v1). |
| `actions` | [`PluginAction[]`](/en/reference/data-types#plugin-action) | ✓ | Footer actions, labels translated; block-owned actions are not here. |
| `blocks` | [`PluginBlock[]`](/en/reference/data-types#plugin-block) |  | Display blocks, in order; unknown kinds are skipped. |
| `inputs` | [`PluginInput[]`](/en/reference/data-types#plugin-input) |  | Every input of the document; an action's form names the ones it collects. |
| `detail` | `boolean` |  | The contribution has a detail view ("see all"). |
| `nextCursor` | `string` |  | Detail views only: the cursor of the next page (core SDK detail paging, a non-blank scalar of at most 256 bytes). While it is set PluginDetailSheet offers load more; the host fetches that page and passes back the merged view. |
| `menuActions` | [`PluginAction[]`](/en/reference/data-types#plugin-action) |  | Actions in the card's ⋯ menu (placement menu), in order; absent when empty. |
| `unavailableReason` | `'disabled' \| 'not_installed' \| 'no_permission' \| 'unsupported_platform' \| 'incompatible_version' \| 'catalog_unreachable' \| 'unbound_copy'` |  | Why the view is unavailable or read-only. |

### PluginAction {#plugin-action}

`FlarePluginAction`

> A resolved action; target and input are opaque to the kit.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Opaque id handed back in action(id, payload). |
| `label` | `string` | ✓ | Key label. |
| `style` | [`PluginActionStyle`](/en/reference/data-types#plugin-action-style) |  | primary or danger; secondary when absent. |
| `confirm` | `string` |  | Asked first in the kit DangerConfirm. |
| `form` | `string[]` |  | Input ids collected first in PluginForm. |

### PluginBlock {#plugin-block}

`FlarePluginBlock`

> One display block, tagged by kind (see spec/plugin-view-vectors.json for each shape).

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `kind` | `'text' \| 'fields' \| 'choices' \| 'entries' \| 'people' \| 'status' \| 'progress' \| 'time' \| 'divider' \| 'note' \| 'rows'` | ✓ | Block kind; rows only on admin pages (Vue). |
| `text` | `{text, maxLines?, style: 'body' \| 'title' \| 'secondary'}` |  | Collapsible text with expand. |
| `fields` | `{fields: {label, value}[]}` |  | Label/value rows. |
| `choices` | `{options: PluginChoice[], multiple, voted, closed, showResults, total?, inputName, action?: PluginAction}` |  | Options; action is the block's submit action. |
| `entries` | `{items: {index, text, name?, userId?, group?: {key, label, count?, total?, percent?}}[], numbered, grouped?, total, more, emptyText?}` |  | A list (sign-ups, voters); grouped lists put a header before each item with group. |
| `people` | `{groups: {label, userIds, count, tone?}[]}` |  | Avatar stacks with a count per group. |
| `status` | `{label?, text, tone}` |  | A badge. |
| `progress` | `{label?, value, total, percent}` |  | A bar with value/total. |
| `time` | `{label?, atMs, endMs?, countdown}` |  | An instant or range, optionally counting down. |
| `note` | `{text, tone?}` |  | A tinted note. |
| `rows` | `{source, columns: {label, format}[], rows: {key, cells: {text, timeMs?}[], actions: {id, input}[], detailInput?}[], nextCursor?, actions: PluginAction[], emptyText?, filters?: string[]}` |  | Admin table (Vue only). filters lists the ids of the view's inputs shown as the page's filters (absent: every input); the other inputs belong to row action forms (flarePluginFilterInputs). |

### PluginChoice {#plugin-choice}

`FlarePluginChoice`

> One option of a choices block.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `index` | `number` | ✓ | Position, submitted in selection. |
| `label` | `string` | ✓ | Option text. |
| `selected` | `boolean` | ✓ | The viewer chose it. |
| `count` | `number` |  | Votes, when results show. |
| `percent` | `number` |  | 0..100, when results show. |

### PluginInput {#plugin-input}

`FlarePluginInput`

> A resolved form input (UiInput).

**Used by: **[PluginForm](/en/components/plugin-form)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `id` | `string` | ✓ | Key of the value in formValues. |
| `kind` | [`PluginInputKind`](/en/reference/data-types#plugin-input-kind) | ✓ | Control kind. |
| `label` | `string` | ✓ | Field label. |
| `required` | `boolean` |  | A value is required. |
| `placeholder` | `string` |  | Placeholder. |
| `maxLength` | `number` |  | Characters (text 256, textarea 2000, options item 100 by default). |
| `min` | `number` |  | number: smallest value; options, members: fewest items. |
| `max` | `number` |  | number: largest value; options, members: most items (members max 1 = single pick). |
| `default` | `unknown` |  | Initial value. |
| `choices` | `{value, label}[]` |  | select only. |

### PluginFormError {#plugin-form-error}

`FlarePluginFormError`

> One problem with a submitted value (UiFormError).

**Used by: **[PluginView](/en/components/plugin-view) · [PluginForm](/en/components/plugin-form) · [PluginDetailSheet](/en/components/plugin-detail-sheet) · [PluginPage](/en/components/plugin-page)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `input` | `string` | ✓ | Input id. |
| `issue` | [`PluginFormIssue`](/en/reference/data-types#plugin-form-issue) | ✓ | What is wrong. |

### PluginUser {#plugin-user}

`FlarePluginUser`

> What resolveUser answers for a user id.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `name` | `string` | ✓ | Display name. |
| `avatarUrl` | `string` |  | Avatar; initials when absent or failing. |

### PluginMember {#plugin-member}

`FlarePluginMember`

> A candidate for a members input.

**Used by: **[PluginView](/en/components/plugin-view) · [PluginForm](/en/components/plugin-form) · [PluginDetailSheet](/en/components/plugin-detail-sheet) · [PluginPage](/en/components/plugin-page)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `userId` | `string` | ✓ | Submitted id. |
| `name` | `string` | ✓ | Display name. |
| `avatarUrl` | `string` |  | Avatar. |

### PluginActionPayload {#plugin-action-payload}

`FlarePluginActionPayload`

> What action(id, payload) carries.

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `selection` | `number[]` |  | Chosen option indices (choices), ascending. |
| `formValues` | `Record<string, unknown>` |  | Submitted form values by input id. |
| `row` | `{key, input}` |  | The row of a rows action (Vue). |

### MessageReadSummary {#message-read-summary}

`FlareMessageReadSummary`

> The SDK's group read summary of the viewer's own message (MessageReceiptView.readSummary).

**Used by: **[MessageMeta](/en/components/message-meta)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `readCount` | `number` | ✓ | Members who read it. |
| `unreadCount` | `number` | ✓ | Members who have not. |
| `total` | `number` | ✓ | Members it was sent to. |

### RedPacketDetailsView {#red-packet-details-view}

`FlareRedPacketDetailsView`

> The plugin's details result for one viewer; amounts the viewer may not see are absent.

**Used by: **[RedPacketDetail](/en/components/red-packet-detail)

| Name | Type | Req. | Description |
|---|---|:---:|---|
| `viewerRole` | [`RedPacketViewerRole`](/en/reference/data-types#red-packet-viewer-role) | ✓ | Who is looking. |
| `status` | [`RedPacketStatus`](/en/reference/data-types#red-packet-status) | ✓ | Packet status. |
| `kind` | [`RedPacketKind`](/en/reference/data-types#red-packet-kind) | ✓ | Packet kind. |
| `greeting` | `string` | ✓ | The greeting. |
| `currency` | `string` | ✓ | ISO 4217 code. |
| `currencyExponent` | `number` | ✓ | Fraction digits of the currency. |
| `totalMinor` | `string` |  | Total, minor units (sender only). |
| `claimedMinor` | `string` |  | Claimed so far, minor units (sender only). |
| `refundedMinor` | `string` |  | Returned to the sender, minor units (sender only). |
| `myAmountMinor` | `string` |  | What the viewer received, minor units. |
| `claimedCount` | `number` | ✓ | Shares claimed. |
| `shareCount` | `number` | ✓ | Shares in total. |
| `createdAtMs` | `number` | ✓ | Created at. |
| `completedAtMs` | `number` |  | All shares taken at. |
| `expiresAtMs` | `number` | ✓ | Expires at. |
| `refundedAtMs` | `number` |  | Returned at. |
| `claimsListed` | `boolean` | ✓ | The viewer may see the claim list. |

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

### ComposerActionKind {#composer-action-kind}

`FlareComposerActionKind`

> Where a "+" tile comes from: a built-in feature or an authorised plugin's composer-action; hosts may leave it out for a tile of their own.

`feature` · `plugin`

### ComposerToolId {#composer-tool-id}

`FlareComposerToolId`

> Composer toolbar tool ids, the same on all four platforms; attachments is the "+" button.

`emoji` · `mention` · `voice` · `image` · `richText` · `attachments`

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

### RedPacketOpenState {#red-packet-open-state}

`FlareRedPacketOpenState`

> Phase of the open-a-packet sheet.

**Used by: **[RedPacketOpenSheet](/en/components/red-packet-open-sheet)

`ready` · `opening` · `finished` · `expired` · `notEligible` · `error`

### RedPacketKind {#red-packet-kind}

`FlareRedPacketKind`

> Packet kinds a composer can offer.

**Used by: **[RedPacketCard](/en/components/red-packet-card) · [RedPacketComposer](/en/components/red-packet-composer)

`lucky` · `normal` · `exclusive`

### LocationProvider {#location-provider}

`FlareLocationProvider`

> The tenant's map service; it decides which web map a location card opens.

**Used by: **[LocationMessage](/en/components/location-message) · [LocationPicker](/en/components/location-picker)

`osm` · `amap`

### PluginActionStyle {#plugin-action-style}

`FlarePluginActionStyle`

> How an action key is drawn.

`primary` · `danger`

### PluginTone {#plugin-tone}

`FlarePluginTone`

> Semantic colour of a status, note or people group; drawn with the *Text tokens.

`neutral` · `info` · `success` · `warning` · `danger`

### PluginInputKind {#plugin-input-kind}

`FlarePluginInputKind`

> Form input kinds.

`text` · `textarea` · `number` · `toggle` · `select` · `datetime` · `options` · `members`

### PluginFormIssue {#plugin-form-issue}

`FlarePluginFormIssue`

> Form error kinds (UiFormIssue).

`required` · `unknown` · `invalidType` · `tooLong` · `outOfRange` · `notAChoice` · `tooFewItems` · `tooManyItems` · `invalidItem` · `duplicateItem`

### PluginViewInset {#plugin-view-inset}

`FlarePluginViewInset`

> Where a PluginView sits: none; sheet — straight in a kit sheet (md / lg / xl); sheetTop — at the top of a sheet with more under it, e.g. a preface above PluginForm (md / lg / 0).

**Used by: **[PluginView](/en/components/plugin-view)

`none` · `sheet` · `sheetTop`

### MessageSurface {#message-surface}

`FlareMessageSurface`

> The surface a message row draws its content on (spec/message-surface-vectors.json).

**Used by: **[MessageBubble](/en/components/message-bubble)

`bubble` · `bareMedia` · `card` · `centered`

### MessageMetaPlacement {#message-meta-placement}

`FlareMessageMetaPlacement`

> Where a message's time and receipt sit (spec/message-meta-placement-vectors.json).

**Used by: **[MessageMeta](/en/components/message-meta)

`inline` · `bubbleFooter` · `below` · `none`

### RedPacketCardState {#red-packet-card-state}

`FlareRedPacketCardState`

> What a red packet card shows (spec/red-packet-vectors.json cardState).

**Used by: **[RedPacketCard](/en/components/red-packet-card)

`unopened` · `viewable` · `claimed` · `finished` · `expired` · `refunded`

### RedPacketStatus {#red-packet-status}

`FlareRedPacketStatus`

> The plugin's packet status (public layer).

`open` · `completed` · `expired` · `refunded`

### RedPacketViewerRole {#red-packet-viewer-role}

`FlareRedPacketViewerRole`

> Who is looking at the details, as the server decided.

`sender` · `claimer` · `eligible` · `ineligible`
