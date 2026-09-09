---
title: ConversationList
---

# ConversationList

<p><span class="flare-tag">Conversation</span></p>

> The inbox — virtualised rows of conversations (avatar, title, preview, unread, timestamp).

**Data source**: an array of conversations (your data); optionally the Flare core openConversationList() observable list that reorders + updates unread live

## Preview

<div class="flare-demo flare-demo--stack">
  <ConversationListDemo />
</div>


## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `items` | [`ConversationRowModel[]`](/en/reference/data-types#conversation-row-model) | ✓ | — | Ordered conversation rows from the view. |
| `activeId` | `string` |  | — | Currently open conversation, highlighted in the list. |
| `loading` | `boolean` |  | — | Shows a skeleton/spinner while the first page loads. |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">unread</span> <span class="flare-tag">muted</span> <span class="flare-tag">pinned</span>

## Events

_None_

> [!TIP]
> Must virtualise (native list per platform); O(visible), no full re-layout on update. The Vue reference is a pure slot container (no emits) — rows are host-rendered, so the contract declares none; Flutter/iOS/Compose expose onSelect / onLongPress at list level, and Flutter additionally onLoadMore.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConversationList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareConversationList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ConversationListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ConversationList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareConversationList } from "@flare-im/vue-ui";
</script>
<template>
  <FlareConversationList
  :items="items"
  :activeId="activeId"
  :loading="loading"
  />
</template>
```

```dart [Flutter]
FlareConversationList(
  items: items,
  activeId: activeId,
  loading: loading,
);
```

```swift [iOS]
ConversationListView(items: items, activeId: activeId, loading: loading)
```

```kotlin [Android]
ConversationList(
  items = items,
  activeId = activeId,
  loading = loading,
)
```

:::


## Examples

### The inbox

items come from client.views.openConversationList(), reordering and updating unread live; the active conversation is highlighted.

::: code-group

```vue [Vue]
<FlareConversationList :items="rows" :active-id="openId" @select="open" @long-press="rowMenu" />
```

```dart [Flutter]
FlareConversationList(items: rows, activeId: openId, onSelect: (r) => open(r.id), onLongPress: rowMenu)
```

```swift [iOS]
ConversationListView(items: rows, activeId: openId) { row in open(row.id) }
```

```kotlin [Android]
ConversationList(items = rows, activeId = openId, onSelect = { open(it.id) })
```

:::
