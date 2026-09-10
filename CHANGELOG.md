# Changelog

English · [中文](CHANGELOG.zh-CN.md)

All notable changes to the Flare IM UI Kit (`flare-im-design`) are documented here.

The kit is one contract with four implementations — Flutter (`flare_im_ui`), iOS/SwiftUI (`FlareIMUI`), Android/Compose (`com.flare.im:im-ui-compose`) and Vue (`@flare-im/vue-ui`) — versioned together. The format is based on [Keep a Changelog](https://keepachangelog.com); the project follows [Semantic Versioning](https://semver.org).

## [Unreleased]

### Changed
- **Contract truthfulness** — the spec now records what the four implementations actually expose: Vue symbols are the `components/index.ts` export names, events are camelCase with per-platform derivation, form controls carry a `model` field, and `lexicon` / `eventAliases` / `eventPlatforms` / `platformAliases` make platform idioms and platform-only surfaces explicit. `spec/validate.mjs` compares every declared prop and event against the Vue, Flutter, SwiftUI and Compose signatures (both directions); the remaining differences live in `spec/signature-baseline.json` and can only shrink.
- **Composer / ChatHeader / MessageActionSheet** contracts rewritten from the implementations. `MessageActionSheet` uses one action-id table on every platform (`image`, `camera`, `file`, `location`, `card`, `vote`, `task`, `schedule`, …); the Vue `build(op)` event, the Flutter `key` field and the `create_*` ops stay as deprecated aliases.
- **ConversationDetails** takes `tone: FlareTone` (`connectionTone` deprecated) and no longer imports `@flare-im/sdk` types; **Toast** accepts `tone` alongside `variant`.
- **GroupDetail** `openChat` emits `(userIds, name)` positionally on every platform.

### Added
- Vue **ChatHeader** `title` / `subtitle` / `presence` / `avatarUserId` / `avatarUrl` / `showBack` and `search` / `call` / `details` events; **Avatar** `presence` (with `away`) and `id` / `name` aliases.
- iOS and Compose **MessageBubble / MessageList** multi-select (`multiSelectMode`, `selected` / `selectedIds`, `onToggleSelect`), **NewFriendRequests** `onView`, **Toast** `onClose`, **MessageStatus** `onResend`; Compose **Avatar** `avatarUrl`; Flutter **ConversationRow** `onLongPress` (`onAction` deprecated).

### Deprecated
- Vue `Avatar.status` / `showStatus`, `ChatHeader.back`, `MessageActionSheet.build`, `ConversationDetails.connectionTone`; Flutter `FlareConversationRow.onAction`, `FlareComposerAction.key`; iOS `ContactDetailView` (use `FlareContactDetail`).

## [1.0.14] - 2026-09-08

Additive, backward-compatible release: every new parameter defaults to the previous behaviour, so existing call sites are unaffected.

### Added
- **BrandLogo** (`FlareBrandLogo`) on all four platforms — the shared Flare mark, with `plate` / plain variants, used by the auth screens.
- **Conversation list, host-rows containers** — Flutter `FlareConversationSliverList` (a sliver: the host keeps its own scroll view, pull-to-refresh and per-id row subscriptions) and iOS/Android `ConversationListContainer` (bring your own row builder; the kit standardises the empty / loading / lazy-list shell). Complements the self-contained `FlareConversationList`.
- **Message list, host-rows sliver** — Flutter `FlareMessageSliverList`, complementing the self-contained `FlareMessageList` for chat screens that drive their own scroll controller and per-message rows.
- **`FlareConversationRow.previewSpansBuilder`** (Flutter) — rich inline preview spans (media chips, mentions) in a conversation row.
- **EmptyState rich variants** (all platforms) — `loading` (spinner in place of the icon), `onTap` (the whole placeholder becomes tappable, distinct from the action button), a custom icon slot (Flutter `iconWidget`, Android `iconContent`, Vue `#icon`; iOS keeps `systemImage`), and a `tone` of `normal` / `error` (error colours the title and icon with the danger token and lets long error text wrap).
- **IconButton overrides** (all platforms) — `tintColor` (foreground), `backgroundColor`, and `customSize`, for arbitrary-tint circular / header buttons. `customSize` derives the glyph at `size * 0.46`.
- **Input** (Flutter) — an optional leading `prefix` widget inside the field (e.g. a search icon) and `autofocus`.
- **FilterTabs `padding`** (Flutter) — host control over the tab-row gutter.
- **SettingsList `select` row kind** (Flutter `FlareSettingKind.select`) — a pick-one row that shows a trailing check on the selected item and emphasises its label.
- **`notifications` i18n namespace** (Vue `messages.ts`, zh-CN / en-US).

### Changed
- **SegmentedControl** (Flutter, iOS) now lays its segments out full-width instead of a fixed minimum width.

### Distribution
- Package versions unified across channels at `1.0.14`: npm `@flare-im/vue-ui@1.0.14`, GitHub tag `1.0.14` (iOS SPM and Android JitPack `com.flare.im:im-ui-compose:1.0.14`), Flutter `flare_im_ui: 1.0.14`.

## [1.0.9] and earlier

Pre-changelog. See the git history and tags (`1.0.4`–`1.0.9`) for prior releases.
