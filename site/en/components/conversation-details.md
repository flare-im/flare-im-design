---
title: ConversationDetails
---

# ConversationDetails

<p><span class="flare-tag">Conversation</span></p>

> The conversation info/settings panel — counts, connection state, and per-conversation actions (mute/pin/archive/clear/delete/sync).

**Data source**: conversation summary from the view + connection state from the client

## Preview

<div class="flare-demo flare-demo--stack">
  <ConversationDetailsDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `conversation` | `Conversation` | ✔ | — | The conversation summary to describe. |
| `connectionText` | `string` |  | — | Human-readable connection label (e.g. connected/reconnecting). |
| `connectionTone` | `'ok' \| 'warn' \| 'error'` |  | — | Severity of the connection label — drives its color. |
| `messageCount` | `number` |  | — | Total messages, shown in the stats row. |
| `latestMessageId` | `string` |  | — | Id of the newest message, for diagnostics/jump. |


## States

<span class="flare-tag">muted</span> <span class="flare-tag">pinned</span> <span class="flare-tag">archived</span>

## Events

<span class="flare-tag">mute</span> <span class="flare-tag">pin</span> <span class="flare-tag">archive</span> <span class="flare-tag">clear-history</span> <span class="flare-tag">delete</span> <span class="flare-tag">mark-read</span> <span class="flare-tag">mark-unread</span> <span class="flare-tag">sync</span> <span class="flare-tag">open-devtools</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConversationDetails</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareConversationDetails</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ConversationDetailsView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ConversationDetails</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareConversationDetails } from "@flare-im/vue-ui";
</script>
<template>
  <FlareConversationDetails
  :conversation="conversation"
  :connectionText="connectionText"
  :connectionTone="connectionTone"
  @mute="onMute"
  @pin="onPin"
  @archive="onArchive"
  />
</template>
```

```dart [Flutter]
FlareConversationDetails(
  conversation: conversation,
  connectionText: connectionText,
  connectionTone: connectionTone,
  onMute: onMute,
  onPin: onPin,
  onArchive: onArchive,
);
```

```swift [iOS]
ConversationDetailsView(conversation: conversation, connectionText: connectionText, connectionTone: connectionTone, onMute: onMute, onPin: onPin, onArchive: onArchive)
```

```kotlin [Android]
ConversationDetails(
  conversation = conversation,
  connectionText = connectionText,
  connectionTone = connectionTone,
  onMute = onMute,
  onPin = onPin,
  onArchive = onArchive,
)
```

:::

