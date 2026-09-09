# @flare-im/ui-spec — L2 Component Contracts

English · [中文](README.zh-CN.md)

Framework-neutral IM component contracts: **one component = one contract (props / states / events + `dataSource` core view), each platform implemented natively**.
This is the neutralized part of the "Ant Design-like component API" — each platform's L1 package implements against it, and consistency is locked down by this spec.

## Install

```bash
npm install @flare-im/ui-spec
```

The contract itself is a JSON file and can be read directly:

```js
import components from "@flare-im/ui-spec/components.json" with { type: "json" };

console.log(components.length); // number of components
```

When implementing a component library for a given platform yourself, use it as the single source of truth to verify that props/events are complete —
the inconsistency problem across the four platform implementations is exactly what this contract locks down.

## Contract format (per component)
| Field | Meaning |
|---|---|
| `name` | Component name (per-platform symbols in `platforms`) |
| `summary` | One-line responsibility |
| `dataSource` | Which **core observable view** (L4) the data comes from — all platforms consume the same one |
| `props[]` | `{ name, type, required?, default?, desc? }` |
| `states[]` | Possible states (e.g. pending/sent/read/failed) |
| `events[]` | Callback/event names |
| `platforms` | `vue / flutter / ios / compose` → `{ package, symbol }` (per-platform dependency and symbol) |

<!-- CATALOG:START -->
## Component catalog

**135 components / 11 categories** (source in [`components.json`](./components.json);
props/events extracted and calibrated from the `@flare-im/vue-ui` source).

> This section is generated from the contract by `gen-readme-catalog.mjs`; do not edit by hand — a hand-written catalog rots as the contract grows.

- **Message** — 32
  `AnnouncementBanner` · `ChatHeader` · `ContactMessage` · `DatePill` · `EmojiMessage` · `FileMessage` · `ImageGrid` · `ImageMessage` · `LinkCardMessage` · `LocationMessage` · `MessageActionSheet` · `MessageBatchToolbar` · `MessageBubble` · `MessageContentView` · `MessageList` · `PinnedMessageBar` · `ReactionSummary` · `ReadReceiptSheet` · `RedPacketCard` · `ScrollToLatest` · `StickerMessage` · `SystemMessage` · `TaskMessage` · `TextMessage` · `TranslationView` · `TypingIndicator` · `UnknownMessage` · `UnreadDivider` · `VideoMessage` · `VoiceMessage` · `VoicePlayer` · `VoteMessage`
- **General** — 24
  `AnnouncementReadBar` · `Avatar` · `Button` · `CapabilityBoundary` · `ConnectionDetails` · `DangerConfirm` · `EmptyState` · `FilterTabs` · `Icon` · `IconButton` · `Input` · `MessageStatus` · `PermissionPrompt` · `PrimaryButton` · `ReauthPrompt` · `SearchBar` · `SearchDateRangeFilter` · `SearchPanel` · `SearchResults` · `SegmentedControl` · `Skeleton` · `StatusBanner` · `TimeStamp` · `Toast`
- **Composer** — 13
  `Composer` · `ComposerActionPanel` · `ComposerReplyStrip` · `ComposerSendButton` · `EmojiPicker` · `MentionPicker` · `PollComposer` · `QuickPhrases` · `RichMarkdownInput` · `SlashCommandMenu` · `StickerPanel` · `VoiceHoldButton` · `VoiceRecordingBar`
- **Contacts** — 13
  `ContactDetail` · `ContactItem` · `ContactList` · `ContactMatchList` · `GroupDetail` · `GroupList` · `GroupMemberGrid` · `GroupPermissionMatrix` · `MemberPanel` · `MemberRoleSheet` · `NewFriendRequests` · `RelationActionBar` · `UnknownUserPlaceholder`
- **Form** — 11
  `Checkbox` · `DatePicker` · `FormField` · `RadioGroup` · `Rating` · `Select` · `Slider` · `Stepper` · `Switch` · `Textarea` · `TimePicker`
- **Conversation** — 8
  `ChatWallpaperPicker` · `ConversationActionSheet` · `ConversationBatchToolbar` · `ConversationDetails` · `ConversationList` · `ConversationRow` · `ForwardPicker` · `StartConversationDialog`
- **Moments** — 8
  `CommentThread` · `MomentActionPopover` · `MomentAudienceSheet` · `MomentCard` · `MomentComposer` · `MomentsCoverHeader` · `MomentsVisibilityRuleList` · `TopicChip`
- **Profile** — 8
  `DeviceSessions` · `NotificationPreferences` · `ProfileCard` · `ProfileEditor` · `ProfilePanel` · `QRCard` · `SettingsList` · `StorageUsage`
- **Call** — 7
  `CallControls` · `CallDevicePicker` · `CallDock` · `CallView` · `GroupCallView` · `IncomingCall` · `ScreenShare`
- **Media** — 6
  `ImagePreviewModal` · `MarkdownPreview` · `MediaCenter` · `TransferProgress` · `TransferQueue` · `VideoPlayerModal`
- **Layout** — 5
  `AppShell` · `ConfigProvider` · `ConversationWorkspace` · `ResponsiveLayout` · `ScreenHeader`

<!-- CATALOG:END -->

**Content-type registry** (`contentTypes.registered`): `MessageBubble`/`MessageContentView` dispatch to individual renderers by content-type
(text/image/video/audio/file/location/card/linkCard/sticker/emoji/vote/task/schedule/announcement/miniProgram/notification/placeholder), and products can register new types.

## Validation (drift prevention, mirroring the sdk-spec bidirectional coverage)
```bash
node validate.mjs
```
Checks: (1) every component contract has complete fields; (2) all four platforms have package+symbol; (3) the **Vue reference symbol (e.g. `MessageBubble.vue`) actually exists in
`@flare-im/vue-ui`** — it errors if the spec and the reference implementation don't line up. Once each platform's L1 package lands, the validation is extended to "that platform's symbol exists and its props are covered".

## Relationships
- **L4** data/behavior: `flare-im-core-sdk` client.views (already exists) — `dataSource` points to it.
- **L3** tokens: [`../tokens`](../tokens) — component visuals go through `--flare-*`.
- **L1** per-platform packages: Vue is already in `@flare-im/vue-ui`; Flutter/iOS/Compose to be extracted from each platform's app (Phase 4).
