# flare-core-vue-im-ui

Shared Vue 3 + TypeScript + Naive UI presentation layer for Flare IM example apps (Web, Electron, Tauri, uni-app H5).

**Not an SDK runtime.** Components receive view-state props and emit intents; example apps map intents to `FlareImClient` / platform-specific raw clients.

## Install

```bash
npm i flare-core-vue-im-ui
```

`flare-im-design-tokens` 会作为依赖自动装上。Vue 3 与 Naive UI 是 peer dependencies，
需要宿主工程自行安装（见下方 [Peer dependencies](#peer-dependencies)）。

## Exports

| Path | Contents |
|------|----------|
| `.` | Full barrel |
| `./theme` | Semantic tokens, CSS vars, Naive overrides |
| `./i18n` | zh-CN / en-US keys + `useFlareI18n` |
| `./contracts` | View-state types (conversation row, message content, layout) |
| `./composables` | `useFlareAdaptive`, `useViewport`, `useFlareWorkbenchUi`, message menu interaction |
| `./components` | `FlareWorkbenchShell`, `FlareUiProvider`, conversations, messages, composer, diagnostics, auth |
| `./style.css` | Workbench shell, auth, chat, composer, diagnostics, responsive layout CSS |
| `./app` | Optional workbench components, SDK context helpers, and platform adapter hooks |
| `./sdk-lab` | Lazy-loadable SDK Lab component for example apps |
| `./app/style.css` | CSS for the optional workbench components |

## Source layout

| Path | Role |
|------|------|
| `src/design-system/` | Product foundations: provider, theme runtime, generated tokens, shared CSS foundations |
| `src/components/` | Public reusable IM components grouped by product surface |
| `src/app/` | Optional workbench building blocks: `components/`, SDK context, runtime adapters, and page-level state |
| `src/shared/` | Cross-cutting contracts, i18n, config, constants, tests |
| `src/composables/` | Public Vue composition APIs for host apps and shared components |
| `src/utils/` | Public UI/data formatting helpers |

## Usage

```vue
<script setup lang="ts">
import { FlareUiProvider, FlareConversationList, FlareConversationRow } from "flare-core-vue-im-ui/components";
import "flare-core-vue-im-ui/style.css";
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

## Peer dependencies

- `vue` ^3.5
- `naive-ui` ^2.44

## Design boundary

This package owns product UI foundations and reusable interaction surfaces only. Host apps own `App.vue`, router creation, route guards, URL shape, runtime transport, login credentials, native shell adapters, and final SDK lifecycle bootstrapping.
