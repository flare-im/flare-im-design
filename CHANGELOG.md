# Changelog

English · [中文](CHANGELOG.zh-CN.md)

All notable changes to the Flare IM UI Kit (`flare-im-design`) are documented here.

The kit is one contract with four implementations — Flutter (`flare_im_ui`), iOS/SwiftUI (`FlareIMUI`), Android/Compose (`com.flare.im:im-ui-compose`) and Vue (`@flare-im/vue-ui`) — versioned together. The format is based on [Keep a Changelog](https://keepachangelog.com); the project follows [Semantic Versioning](https://semver.org).

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
