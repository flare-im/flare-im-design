---
title: MessageBubble
---

# MessageBubble

<p><span class="flare-tag">Message</span></p>

> One message in a thread — content, sender, grouping, delivery status. Delegates body to a per-content-type view.

**Data source**: one message object (your data); status drives state; optionally from a Flare core timeline

## Preview

<div class="flare-demo flare-demo--stack">
  <MessageBubbleDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `message` | `Message` | ✓ | — | The message to render. |
| `currentUserId` | `string` | ✓ | — | Viewer's id; decides self vs. other side. |
| `self` | `boolean` |  | `message.senderId === currentUserId` | Force the outgoing side; defaults from sender == current user. |
| `conversationType` | `'single' \| 'group' \| 'ai'` |  | `single` | Single/group/AI — affects sender name & grouping. |
| `groupStart` | `boolean` |  | — | First bubble of a same-sender run (shows avatar/name). |
| `groupEnd` | `boolean` |  | — | Last bubble of a run (carries the tail & time). |
| `multiSelectMode` | `boolean` |  | — | Renders the selection checkbox. |
| `selected` | `boolean` |  | — | Whether this bubble is checked in multi-select. |
| `menuConfig` | `MessageMenuConfig` |  | — | Which long-press actions are enabled for this message. |
| `mediaDownloadState` | `MessageMediaDownloadUiState` |  | — | Progress/state for media bodies (image/video/file). |


## States

<span class="flare-tag">pending</span> <span class="flare-tag">sent</span> <span class="flare-tag">read</span> <span class="flare-tag">failed</span>

## Events

<span class="flare-tag">react</span> <span class="flare-tag">reply</span> <span class="flare-tag">edit</span> <span class="flare-tag">delete</span> <span class="flare-tag">pin</span> <span class="flare-tag">mark</span> <span class="flare-tag">preview</span>

> [!TIP]
> Optimistic: status from the core view, never a network wait.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageBubble</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageBubble</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageBubbleView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageBubble</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageBubble } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMessageBubble
  :message="message"
  :currentUserId="currentUserId"
  :self="self"
  @react="onReact"
  @reply="onReply"
  @edit="onEdit"
  />
</template>
```

```dart [Flutter]
FlareMessageBubble(
  message: message,
  currentUserId: currentUserId,
  self: self,
  onReact: onReact,
  onReply: onReply,
  onEdit: onEdit,
);
```

```swift [iOS]
MessageBubbleView(message: message, currentUserId: currentUserId, self: self, onReact: onReact, onReply: onReply, onEdit: onEdit)
```

```kotlin [Android]
MessageBubble(
  message = message,
  currentUserId = currentUserId,
  self = self,
  onReact = onReact,
  onReply = onReply,
  onEdit = onEdit,
)
```

:::

