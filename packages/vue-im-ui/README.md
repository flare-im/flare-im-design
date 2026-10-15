# @flare-im/vue-ui

Vue 3 presentation components for the Flare IM design system. Components receive host-owned view state and emit typed UI intents. The package does not create sessions, perform network requests, own persistence, or route an application.

## Install

```bash
npm install @flare-im/vue-ui @flare-im/tokens vue naive-ui
```

The package publishes Vue and TypeScript source so the host bundler compiles it with the application's Vue version and CSS pipeline. Vite and Nuxt support this directly; Webpack consumers must include the package in their Vue loader rule.

## Public Entries

| Path | Contents |
|---|---|
| `@flare-im/vue-ui` | Complete public API |
| `@flare-im/vue-ui/admin` | Focused shared table, drawer, form and provider entry without the chat/composer graph |
| `@flare-im/vue-ui/admin.css` | Tokens and admin control foundations without chat/timeline styles |
| `@flare-im/vue-ui/components` | General, IM, and composition components |
| `@flare-im/vue-ui/contracts` | Host-facing view-state and interaction contracts |
| `@flare-im/vue-ui/theme` | Theme runtime and semantic token helpers |
| `@flare-im/vue-ui/i18n` | Built-in locales and locale registration |
| `@flare-im/vue-ui/composables` | UI-only adaptive and interaction composables |
| `@flare-im/vue-ui/utils` | Presentation helpers |
| `@flare-im/vue-ui/style.css` | Generated tokens and component styles |

## Usage

```vue
<script setup lang="ts">
import {
  FlareConversationList,
  FlareConversationRow,
  FlareUiProvider,
} from "@flare-im/vue-ui/components";
import "@flare-im/vue-ui/style.css";
</script>

<template>
  <FlareUiProvider layout-mode="auto">
    <FlareConversationList :items="rows" active-id="c1">
      <template #item="{ item, active }">
        <FlareConversationRow :item="item" :active="active" @select="onSelect" />
      </template>
    </FlareConversationList>
  </FlareUiProvider>
</template>
```

## Ownership

Admin tables can set `fill` inside a height-bounded panel: only the rows scroll, while
the column toolbar and pagination remain reachable on narrow and short viewports.
Set `paginationDisabled` during a host-owned mutation to lock both page and page-size
controls without hiding the readable rows. Loading locks paging automatically.
Cursor sources display only the actual count on this page and the page number: short
or filtered pages do not justify a global row offset or an estimated total.
Use `FlarePermissionTree selection-mode="independent"` when parents are real grants:
every code is toggled on its own, never by ancestor/descendant inference. The default
leaf-selection mode is for grouping-only trees. The host still owns authorization.

The package owns rendering, focus, selection affordances, responsive composition, accessibility semantics, theme resolution, and deterministic UI state projection. The host owns application routing, data acquisition, authoritative lifecycle state, permissions, commands, persistence, media transport, and business policy.

General UI and IM UI are logical layers inside one cohesive package. They are not separate placeholder packages and there are no compatibility entry points for the former repository layout.

## Development

```bash
npm test
npm run typecheck
npm run build
npm run pack
```
