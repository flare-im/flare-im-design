---
title: ConversationRow
---

# ConversationRow

<p><span class="flare-tag">Conversation</span></p>

> A single inbox row — avatar, title, last-message/draft preview, unread badge, time, mute/pin markers.

**Data source**: one ConversationRow item from the conversation-list view

## Preview

<div class="flare-demo">
  <ConversationRowDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `item` | `ConversationRow` | ✔ | — | The row's data (title, preview, unread, time, flags). |
| `active` | `boolean` |  | — | Renders the selected/open state. |
| `draftPreview` | `string` |  | — | Unsent draft text; shown in place of the last message. |


## States

<span class="flare-tag">unread</span> <span class="flare-tag">muted</span> <span class="flare-tag">pinned</span> <span class="flare-tag">active</span>

## Events

<span class="flare-tag">select</span> <span class="flare-tag">action</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConversationRow</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareConversationRow</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ConversationRowView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ConversationRow</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareConversationRow } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareConversationRow
  :item="item"
  :active="active"
  :draftPreview="draftPreview"
  @select="onSelect"
  @action="onAction"
  />
</template>
```

```dart [Flutter]
FlareConversationRow(
  item: item,
  active: active,
  draftPreview: draftPreview,
  onSelect: onSelect,
  onAction: onAction,
);
```

```swift [iOS]
ConversationRowView(item: item, active: active, draftPreview: draftPreview, onSelect: onSelect, onAction: onAction)
```

```kotlin [Android]
ConversationRow(
  item = item,
  active = active,
  draftPreview = draftPreview,
  onSelect = onSelect,
  onAction = onAction,
)
```

:::

