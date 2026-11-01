# Public API

This repository is in the `2.0.0-rc.1` development phase. It documents the current supported surface, not a compatibility facade for earlier RC layouts.

## Sources Of Truth

- `spec/components.json` defines component names, props, states, events, and platform symbols.
- `spec/public-export-map.json` is the generated component-to-package map.
- `tokens/tokens.json` and `tokens/themes.json` define the semantic design system.
- Each package facade defines the declarations consumers may import.

An implementation file that is not reachable from a documented facade is internal even when the language makes it technically importable.

## Vue

`@flare-im/vue-ui` exposes only these explicit entry points:

- `.`
- `./components`
- `./theme`
- `./i18n`
- `./contracts`
- `./composables`
- `./utils`
- `./icon-glyphs`
- `./style.css`

Wildcard and implementation-directory imports are unsupported. Product apps, SDK adapters, diagnostics routes, and authentication flows are not package API.

`./components` exports exactly the Vue symbols registered in `spec/components.json` plus the companion exports declared in `spec/public-api-exceptions.json` (the icon-name table of FlareIcon). Hooks live on `./composables` (`useFlareConfig`, `useFlarePlatform`, `useFlareOverlayContainer`, `useFlareMessageRenderers`, …), pure helpers on `./utils`. `node tooling/check-public-api.mjs --strict` (release-check `api-check`) fails on any export outside the catalog; exports awaiting a merge are tracked in `spec/public-api-exceptions.json#pendingMerge` and keep the gate red until cleared. The reference workbench shell, the authentication screen and the diagnostics console are product code and live in `flare-im-core-client-sdk/examples/shared/vue-reference`.

## Native Packages

- Flutter: declarations exported by `package:flare_im_ui/flare_im_ui.dart`.
- Every public native component is either a catalog symbol or a `nativeCompanions` entry in `spec/public-api-exceptions.json` (sliver list forms, the Compose platform provider); anything else public and unused fails `node tooling/check-dead-components.mjs`.
- Compose: public declarations in `com.flare.im.ui` from `packages/android-im-ui`.
- SwiftUI: public declarations in the `FlareIMUI` product from `packages/ios-im-ui`.

The four implementations share semantic contracts while retaining platform-native rendering and presentation behavior. Registered platform differences belong in the component contract, not in hidden aliases.

## Composition Seams

Every slot a component declares exists on each platform the contract claims for it, checked by `node tooling/check-component-slots.mjs`. A slot that a platform does not have is narrowed in `spec/components.json` (`slotPlatforms`) and must say why in `slotReasons` — a narrowing records a gap, it does not hide one, and the gate fails without the reason. Where a platform names a slot idiomatically, `platformAliases.<platform>.slots` (or `.props`, since on a native kit a slot is a prop) records the name: Flutter's `emptyPlaceholder`, `trailingBuilder` and `contextBanner` are the same seams as `empty`, `trailing` and `context`.

A list that is empty can be replaced by the host on all four kits (`ContactList.empty`, `GroupList.empty`, `MessageList.empty`), an empty state can carry the host's own controls (`EmptyState.actions`), and a screen header can take what the screen is reached through (`ScreenHeader.leading`). Each falls back to the kit's own answer when the host gives nothing.

## Contact Index

The A–Z index letter of a name is one contract on four kits, checked against `spec/contact-index-vectors.json`. Vue and SwiftUI read the platform's pinyin collation; Flutter and Compose read `tooling/build-pinyin-initials.mjs`'s generated table of every character in CJK Unified Ideographs, produced from that same collation. A polyphonic character follows the collation's reading on every kit; a host that knows a surname's reading passes `indexKey`.

## Group Management

Which group management entries a viewer gets is one contract on four kits, checked against `spec/group-management-vectors.json`: `FlareGroupCapabilities` (`canManageInfo`, `canManageJoinSettings`, `canManageJoinRequests`, `canInvite`, `canDissolve`) and `FlareMemberActions` per member (`canRemove`, `canMute`, `canChangeRole`, `canTransferOwner`), read by `groupManagementEntries`, `groupDetailMemberActions`, `memberRoleActions(member, actions)` and `groupPermissionRows(settings, capabilities, …)`. The kit holds no role, owner or permission-bit rule: the host passes what its permission source answered (the social SDK's `memberCapabilities` and `memberActions`). `FlareGroupDetailModel.canManage` / `isOwner`, `MemberRoleSheet`'s `viewerRole` and its capability switches, `GroupPermissionMatrix.canManage` and the unused application-level `FlareGroupCapabilities` of Vue and Flutter were removed outright.

## Display Names

A projected name is one contract on four kits, checked against `spec/display-name-vectors.json` and documented with its rendering table in `docs/display-names.md`. The type is `FlareDisplayName`, camelCase on the wire as the core SDK writes it — `named` (`text`, optional `source`), `members` (`names`, `total`, the reader counted in `total` and never in `names`) and `unnamed` (`entity`, `idTail`) — with the enums `FlareDisplayNameSource` and `FlareDisplayNameEntity`; Vue exports the types, `flareDisplayNameFrom` and `flareIdTail` on `./contracts`, Compose and Flutter read the wire through `FlareDisplayName.fromMap` / `fromJson`, SwiftUI through `Codable` and, for JSON a host already decoded (a dictionary off an SDK bridge), `FlareDisplayName(json:)`, which is nil only when there is no value. Reading never fails: an unknown `entity` reads as `person`, an unknown `kind` (or a form missing its text) as an unnamed person without an id tail. `flareDisplayNameText(name, strings)` writes it as text on every kit (Vue on `./utils`, its `strings` a translator or a locale): a name as it is; members joined with `displayNameSeparator` plus, when total > names + 1, `displayNameMembersMore(names, total, others)` — Chinese counts the group's total (「等 12 人」), English the others beyond the names and the reader ("and 8 others"); and an unnamed value by entity (`displayNameUser(idTail)`, `displayNameUnknownUser`, `displayNameGroup`, `displayNameSystem`, `displayNameAi`, `displayNameCustomer`, `displayNameChannel`, `displayNameBroadcast`, `displayNameTemp`; Vue `displayName.*`). `flareIdTail(id)` is the id's last four Unicode scalars after trimming, the rule the core SDK makes `idTail` with; `flarePluginFallbackName` reads it. Components that show a name keep string props: the host calls `flareDisplayNameText` where it wires the projected value in.
 A quote's sender is `flareQuoteSenderText` on every kit (Vue on `./utils` over a quote's `quotedSender`, `quotedSenderName` and `quotedSenderId`; native over `FlareReplyTarget`, which adds the optional `senderId` and `sender: FlareDisplayName`), checked against the `quoteSender` group of the same table: the projected sender, else the name, else the unnamed person of the id — never blank and never the id.

## Count Badges

A count badge is one rule on four kits, checked against `spec/count-badge-vectors.json`: `flareCountBadgeText(count, more)` reads 99+ when `more` (there are more than the count, as when the server had more than the page it counted) or when the count is above 99, else the count, with a missing or negative count written 0; `flareCountBadgeDrawn(count, more)` is a count above 0 or `more`. A navigation item's count badge takes `more` (Vue `FlareNavigationBadge`, Compose and SwiftUI `FlareApplicationNavigationBadge`, Flutter `FlareNavigationBadge`), a filter tab takes `badgeMore` (`FlareFilterTabOption` on every kit) and a Vue settings row `FlareSettingsItem.badgeMore`, all defaulting to false; a filter tab and a settings row draw their badge only when `flareCountBadgeDrawn`. Vue exports both functions on `./contracts`.

## Locations

A place from the social SDK's geo search (`GeoPlace`: `id`, `title`, `address`, `lat`, `lng`, `distanceM`) reads into the kit's place by one rule, checked against the `placeFrom` group of `spec/location-vectors.json`: Vue `flareLocationPlaceFrom(value)` on `./contracts`, Compose `FlareLocationPlace.fromMap` / `fromJson`, SwiftUI `FlareLocationPlace(json:)` and Flutter `FlareLocationPlace.fromJson`. The coordinate is `lat` / `lng` (or `latitude` / `longitude` when those are missing) and only a JSON number counts; a value that is not an object or has no valid coordinate (0, 0 included) reads as none. The rest of the location contract is `docs/location-and-contact-components.md`.

## Message List Paging

The message list's two ends are one contract on four kits, checked against `spec/message-list-paging-vectors.json` and documented in `docs/message-list-paging.md`. Besides `hasOlder`, `loadingOlder`, `olderError` and the load-older intent, every kit's message list (Vue `FlareMessageList`, Compose `MessageList`, SwiftUI `MessageListView`, Flutter `FlareMessageList`) takes `hasNewer`, `loadingNewer`, `newerError` and the intents load-newer (Vue event `load-newer`, native `onLoadNewer`) and jump-to-latest (Vue event `jump-to-latest`, native `onJumpToLatest`), all defaulting to off: a list left at the defaults draws no newer end, never asks for newer and has no back-to-latest key beyond the new-messages one. An end draws a spinner while loading, else its error and the load or retry button while there is more and the host takes the intent; the list asks for a page by itself within 160 logical pixels of an edge, never after a failure. A window detached from the latest (`hasNewer`) shows `ScrollToLatest` without a count and raises jump-to-latest; the latest window the host hands over then opens at its newest message, and a newer page read into a detached window keeps the reader in place. Native `FlareStrings` add `messageListLoadNewer`; Vue adds `chat.loadNewer` and `chat.loadingNewer`. Rows keep their `resolveMessageId` key. The locate trip gains a form that opens a window around the message instead of paging back to it: `flareLocateMessageAround` (Vue `./utils`, Compose, Flutter) and `FlareLocate.runAround` (SwiftUI) over `anchor` (`FlareLocateAnchor`: `messageId`, optional `seq`), `showInList(id)`, `openAround(anchor)` answering the anchor key or nothing, `settle` and `isCurrent`, checked against the `around` group of `spec/locate-orchestration-vectors.json`. `flareLocateMessage` / `FlareLocate.run` stay until the apps move to the timeline view.

## Data Display

`FlareMetricTile` and `FlareChartCard`, with the `FlareChartPoint` type, are on `./components` for web dashboards and have no native counterpart: their contracts in `spec/components.json` declare the Vue platform only and say why in `notes`. They take host-owned readings — a number, a preformatted string, or `null` for no reading, which is drawn as a dash or a gap and never as 0 — and draw with kit tokens only, as plain SVG with no chart library, so a theme or dark mode restyles them with the page. The plot is `role="img"` named by a numeric summary and every reading is also in a table for assistive technology. The styling seams are the `extra` and `footer` slots, `appearance` (`card` / `plain`) and the `--flare-chart-card-plot-height` custom property.

`FlareDataTable` and `FlarePermissionTree`, with the `FlareDataTableColumn`, `FlareDataTablePagination`, `FlareDataTableSort` and `FlarePermissionNode` types, join them on `./components` for web consoles, again Vue only with the reason in `notes`. The table draws host-owned rows in a real `<table>` and only reports intents — `update:sort`, `update:pagination`, `update:selectedKeys`, `update:visibleColumns`, `rowClick` — never sorting or paging itself; its seams are the `cell-<key>`, `row-actions`, `batch`, `toolbar` and `empty` slots, `density`, `stickyHeader` and the `--flare-component-data-table-*` custom properties. The tree takes the leaf codes only (`checkedCodes`) and derives every parent; its seams are the `node` and `empty` slots. Both are additive to the 2.0 surface: no existing symbol, prop or token changed.

`FlareFilterBar`, `FlareDescriptionList`, `FlareCodeBlock` and `FlareTag`, with the `FlareDescriptionItem`, `FlareDescriptionLabelPlacement` and `FlareDescriptionValue` types, complete the console set on `./components`, Vue only with the reason in `notes`. The filter bar reports `search` / `reset` and `update:expanded` and never reads a value; its seams are the default, `more` and `actions` slots and `--flare-component-filter-bar-field-min-width`. The description list reports `copy(key, copied)`; its seams are the `item-<key>` slots and `--flare-component-description-list-label-width`. The code block reports `copy(copied)` and is bounded by `--flare-component-code-block-max-height`. The tag takes `FlareTone`. `FlareDataTablePagination.total` became optional and `hasNext` was added, so a cursor source pages without a count. `FlareDangerConfirm` and `FlareConfirmOptions` gained `reason` (`FlareConfirmReason` and the UTF-8 counter `confirmReasonBytes`, on `./contracts`) and `confirmPhrase` (Vue only, `platforms: ["vue"]` on the props); `confirm` and `action` receive a `FlareConfirmInput`; `FlareConfirmRequest` gained `id`. `FlareStatusBanner` gained `title`, `dismissible` and the `dismiss` event, and `FlareNavigationItem` gained `href`, gated by the new `safeNavigationHref` on `./contracts` (Vue only). All of it is additive: an existing call compiles and behaves as before.

## Theme API

`FlareThemeMode` (light / dark / system) and `flareThemeIsDark(mode, systemDark)` are public on all four kits, over `spec/theme-mode-vectors.json`; the host holds and stores the person's choice, and the three labels are in every strings table. `tokens.json` also carries the text roles (title / section / body / caption), public as `--flare-text-<role>-*` on the web and `FlareTextRole` / `FlareTextRoles` on the three native kits. There is no global density preset.

The server clock is public on all four kits, over `spec/server-clock-vectors.json`: Vue `setFlareServerClockOffset` / `flareServerClockOffset` / `flareServerNowMs` / `flareServerNow` on `./utils`, and `FlareServerClock` (`setOffsetMs`, `offsetMs`, `nowMs()`, `now`) on the three native kits. The host hands in the core SDK's estimate; the kit never measures it.

The six built-in brands and both appearance modes are public. Custom themes are supported through semantic color overrides on every platform. Components consume semantic/component tokens and do not expose raw palette dependencies as contract.

## Change Rules

During RC development, a breaking correction is allowed only when source, spec, tokens, tests, examples, website, CI, and release documentation move together. Removed names are removed outright; this repository does not keep deprecated callbacks, token aliases, package facades, or path forwarding layers.

After a stable release, semantic-version policy and migration notes will govern removals. Internal demos, fixtures, previews, generated sample data, and tooling remain changeable without a public API promise.
