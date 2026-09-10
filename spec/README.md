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
| `events[]` | Callback/event names — camelCase in the contract; Vue derives kebab-case (`@toggle-select`), native platforms derive `on` + PascalCase (`onToggleSelect`) |
| `model` | `{ prop, event }` — the v-model pair for form controls (`modelValue` / `update:modelValue`); native platforms express it as a controlled value / binding |
| `props[].platforms` | Optional; restricts a prop to some platforms (e.g. Vue-only slot-detection flags) |
| `eventPlatforms` | Optional `{ event: [platforms] }`; restricts an event to some platforms (e.g. per-action message events are Vue-only, native platforms expose `messageLongPress` and let the host build the menu) |
| `platformAliases` | Optional `{ platform: { props: {…}, events: {…} } }` — component-level idiomatic names that satisfy the contract (e.g. `edit` → `onEditRemark`) |
| `deprecatedCallbacks` | Optional `{ platform: [names] }` — old callback names kept for one version; not counted as undeclared |
| `platforms` | `vue / flutter / ios / compose` → `{ package, symbol }` (per-platform dependency and symbol). The Vue symbol is the export name from `components/index.ts` |

Top-level tables shared by every component:

| Field | Meaning |
|---|---|
| `lexicon` | Contract term → per-platform accepted names (`conversationType` → `conversationKind`, `ariaLabel` → `semanticLabel` / `accessibilityLabel` / `contentDescription`, …) |
| `eventAliases` | Contract event → per-platform idiomatic callbacks beyond the default derivation (`click` → `onPressed` / `action` / `onClick`, `change` → `onChanged`, `submit` → `onSubmitted`) |
| `composerActions` | The single attachment-action id table (`image`, `camera`, `file`, `location`, `card`, `vote`, `task`, `schedule`, …) every platform's MessageActionSheet uses |

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
Checks: (1) every component contract has complete, bilingual fields and camelCase prop/event names; (2) every declared platform has package+symbol and the symbol exists (Vue: exported from `components/index.ts`; Flutter class; SwiftUI struct; Compose function); (3) **signatures**: every declared prop and event must be found in each platform's public signature (honouring `lexicon`, `eventAliases`, `platformAliases`, `props[].platforms`, `eventPlatforms`), and every native `onXxx` callback must be declared. Remaining historical differences live in `signature-baseline.json` and can only shrink — a new difference fails, and a resolved difference fails until the baseline is regenerated:

```bash
node signature-report.mjs              # per-platform totals
node signature-report.mjs --component MessageList   # one component, verbose
node signature-report.mjs --baseline   # rewrite signature-baseline.json (only after the diff got smaller)
```

## Relationships
- **L4** data/behavior: `flare-im-core-sdk` client.views (already exists) — `dataSource` points to it.
- **L3** tokens: [`../tokens`](../tokens) — component visuals go through `--flare-*`.
- **L1** per-platform packages: Vue is already in `@flare-im/vue-ui`; Flutter/iOS/Compose to be extracted from each platform's app (Phase 4).
