---
title: ResponsiveLayout
---

# ResponsiveLayout

<p><span class="flare-tag">Layout</span></p>

> Responsive conversation layout — mobile single column (list↔chat), tablet two columns (list+chat), desktop three columns (list+chat+detail).

**Data source**: layout only; the three slots (list/chat/detail) are filled by the product

## Preview

<div class="flare-demo flare-demo--stack">
  <ResponsiveLayoutDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `hasDetail` | `boolean` |  | — | Whether a detail pane exists (enables 3-column). |
| `activePane` | `'list' \| 'chat' \| 'detail'` |  | — | Which pane is foregrounded on mobile. |


## States

<span class="flare-tag">single</span> <span class="flare-tag">dual</span> <span class="flare-tag">triple</span>

## Events

<span class="flare-tag">paneChange</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ResponsiveLayoutView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareResponsiveLayout } from "@flare-im/vue-ui";
</script>
<template>
  <FlareResponsiveLayout
  :hasDetail="hasDetail"
  :activePane="activePane"
  @paneChange="onPaneChange"
  />
</template>
```

```dart [Flutter]
FlareResponsiveLayout(
  hasDetail: hasDetail,
  activePane: activePane,
  onPaneChange: onPaneChange,
);
```

```swift [iOS]
ResponsiveLayoutView(hasDetail: hasDetail, activePane: activePane, onPaneChange: onPaneChange)
```

```kotlin [Android]
ResponsiveLayout(
  hasDetail = hasDetail,
  activePane = activePane,
  onPaneChange = onPaneChange,
)
```

:::


## Examples

### Responsive three-pane

Three columns on desktop (list+chat+detail), two on tablet, one on mobile — switching by activePane with a back affordance.

::: code-group

```vue [Vue]
<FlareResponsiveLayout :has-detail="true" :active-pane="pane" @pane-change="p => pane = p">
  <template #list><FlareConversationList :items="rows" /></template>
  <template #chat><FlareMessageList v-bind="thread" /></template>
  <template #detail><FlareConversationDetails :conversation="conv" /></template>
</FlareResponsiveLayout>
```

```dart [Flutter]
FlareResponsiveLayout(
  activePane: pane,
  onPaneChange: (p) => setState(() => pane = p),
  list: FlareConversationList(items: rows),
  chat: FlareMessageList(messages: timeline, currentUserId: me.id),
  detail: FlareConversationDetails(conversation: conv),
)
```

```swift [iOS]
ResponsiveLayoutView(
  activePane: pane, onPaneChange: { pane = $0 },
  list: AnyView(ConversationListView(items: rows)),
  chat: AnyView(MessageListView(messages: timeline, currentUserId: me.id)),
  detail: AnyView(ConversationDetailsView(conversation: conv))
)
```

```kotlin [Android]
ResponsiveLayout(
  activePane = pane,
  onPaneChange = { pane = it },
  list = { ConversationList(items = rows) },
  chat = { MessageList(messages = timeline, currentUserId = me.id) },
  detail = { ConversationDetails(conversation = conv) },
)
```

:::
