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

## Data Display

`FlareMetricTile` and `FlareChartCard`, with the `FlareChartPoint` type, are on `./components` for web dashboards and have no native counterpart: their contracts in `spec/components.json` declare the Vue platform only and say why in `notes`. They take host-owned readings — a number, a preformatted string, or `null` for no reading, which is drawn as a dash or a gap and never as 0 — and draw with kit tokens only, as plain SVG with no chart library, so a theme or dark mode restyles them with the page. The plot is `role="img"` named by a numeric summary and every reading is also in a table for assistive technology. The styling seams are the `extra` and `footer` slots, `appearance` (`card` / `plain`) and the `--flare-chart-card-plot-height` custom property.

`FlareDataTable` and `FlarePermissionTree`, with the `FlareDataTableColumn`, `FlareDataTablePagination`, `FlareDataTableSort` and `FlarePermissionNode` types, join them on `./components` for web consoles, again Vue only with the reason in `notes`. The table draws host-owned rows in a real `<table>` and only reports intents — `update:sort`, `update:pagination`, `update:selectedKeys`, `update:visibleColumns`, `rowClick` — never sorting or paging itself; its seams are the `cell-<key>`, `row-actions`, `batch`, `toolbar` and `empty` slots, `density`, `stickyHeader` and the `--flare-component-data-table-*` custom properties. The tree takes the leaf codes only (`checkedCodes`) and derives every parent; its seams are the `node` and `empty` slots. Both are additive to the 2.0 surface: no existing symbol, prop or token changed.

`FlareFilterBar`, `FlareDescriptionList`, `FlareCodeBlock` and `FlareTag`, with the `FlareDescriptionItem`, `FlareDescriptionLabelPlacement` and `FlareDescriptionValue` types, complete the console set on `./components`, Vue only with the reason in `notes`. The filter bar reports `search` / `reset` and `update:expanded` and never reads a value; its seams are the default, `more` and `actions` slots and `--flare-component-filter-bar-field-min-width`. The description list reports `copy(key, copied)`; its seams are the `item-<key>` slots and `--flare-component-description-list-label-width`. The code block reports `copy(copied)` and is bounded by `--flare-component-code-block-max-height`. The tag takes `FlareTone`. `FlareDataTablePagination.total` became optional and `hasNext` was added, so a cursor source pages without a count. `FlareDangerConfirm` and `FlareConfirmOptions` gained `reason` (`FlareConfirmReason` and the UTF-8 counter `confirmReasonBytes`, on `./contracts`) and `confirmPhrase` (Vue only, `platforms: ["vue"]` on the props); `confirm` and `action` receive a `FlareConfirmInput`; `FlareConfirmRequest` gained `id`. `FlareStatusBanner` gained `title`, `dismissible` and the `dismiss` event, and `FlareNavigationItem` gained `href`, gated by the new `safeNavigationHref` on `./contracts` (Vue only). All of it is additive: an existing call compiles and behaves as before.

## Theme API

`FlareThemeMode` (light / dark / system) and `flareThemeIsDark(mode, systemDark)` are public on all four kits, over `spec/theme-mode-vectors.json`; the host holds and stores the person's choice, and the three labels are in every strings table. `tokens.json` also carries the text roles (title / section / body / caption), public as `--flare-text-<role>-*` on the web and `FlareTextRole` / `FlareTextRoles` on the three native kits. There is no global density preset.

The six built-in brands and both appearance modes are public. Custom themes are supported through semantic color overrides on every platform. Components consume semantic/component tokens and do not expose raw palette dependencies as contract.

## Change Rules

During RC development, a breaking correction is allowed only when source, spec, tokens, tests, examples, website, CI, and release documentation move together. Removed names are removed outright; this repository does not keep deprecated callbacks, token aliases, package facades, or path forwarding layers.

After a stable release, semantic-version policy and migration notes will govern removals. Internal demos, fixtures, previews, generated sample data, and tooling remain changeable without a public API promise.
