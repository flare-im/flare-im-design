---
title: ChatHeader
---

# ChatHeader

<p><span class="flare-tag">Message</span></p>

> The active conversation's header — title, subtitle/presence, and header actions (search/call/details).

**Data source**: active conversation summary + peer presence (your data)

## Preview

<div class="flare-demo flare-demo--stack">
  <ChatHeaderDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | Conversation name shown in the header. |
| `subtitle` | `string` |  | — | Secondary line (member count, typing, last-seen…). |
| `presence` | `'online' \| 'offline' \| 'busy' \| 'away'` |  | — | Peer presence for a 1:1 chat; drives the status dot. |


## States

<span class="flare-tag">online</span> <span class="flare-tag">offline</span>

## Events

<span class="flare-tag">search</span> <span class="flare-tag">call</span> <span class="flare-tag">details</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareChatHeader</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareChatHeader</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ChatHeaderView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ChatHeader</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareChatHeader } from "@flare-im/vue-ui";
</script>
<template>
  <FlareChatHeader
  :title="title"
  :subtitle="subtitle"
  :presence="presence"
  @search="onSearch"
  @call="onCall"
  @details="onDetails"
  />
</template>
```

```dart [Flutter]
FlareChatHeader(
  title: title,
  subtitle: subtitle,
  presence: presence,
  onSearch: onSearch,
  onCall: onCall,
  onDetails: onDetails,
);
```

```swift [iOS]
ChatHeaderView(title: title, subtitle: subtitle, presence: presence, onSearch: onSearch, onCall: onCall, onDetails: onDetails)
```

```kotlin [Android]
ChatHeader(
  title = title,
  subtitle = subtitle,
  presence = presence,
  onSearch = onSearch,
  onCall = onCall,
  onDetails = onDetails,
)
```

:::

