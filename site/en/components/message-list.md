---
title: MessageList
---

# MessageList

<p><span class="flare-tag">Message</span></p>

> The virtualised message thread — grouping, load-older, multi-select, per-message actions, media state.

**Data source**: client.views.openTimeline(conversationId); windowed, load-older via view.loadOlder()

## Preview

<div class="flare-demo flare-demo--stack">
  <MessageListDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `conversationId` | `string` | ✔ | — | Which timeline to open. |
| `conversationType` | `'single' \| 'group' \| 'ai'` |  | — | Single/group/AI — affects bubble layout. |
| `messages` | `Message[]` | ✔ | — | Windowed message slice from the view. |
| `currentUserId` | `string` | ✔ | — | Viewer's id, for self/other resolution. |
| `multiSelectMode` | `boolean` |  | — | Turns on per-bubble selection. |
| `selectedIds` | `string[]` |  | — | Ids currently checked in multi-select. |
| `loadingOlder` | `boolean` |  | — | Shows the load-older spinner at the top. |
| `hasOlder` | `boolean` |  | — | Whether more history exists to page in. |
| `bottomInset` | `number` |  | — | Extra bottom padding (e.g. above the composer). |
| `menuConfig` | `MessageMenuConfig` |  | — | Enabled long-press actions across the list. |
| `mediaDownloadStates` | `Record<string, MessageMediaDownloadUiState>` |  | — | Map of messageId → media download state. |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">loadingOlder</span> <span class="flare-tag">atBottom</span> <span class="flare-tag">multiSelect</span>

## Events

<span class="flare-tag">atBottomChange</span> <span class="flare-tag">react</span> <span class="flare-tag">reply</span> <span class="flare-tag">edit</span> <span class="flare-tag">delete</span> <span class="flare-tag">recall</span> <span class="flare-tag">forward</span> <span class="flare-tag">pin</span> <span class="flare-tag">mark</span> <span class="flare-tag">preview</span> <span class="flare-tag">resend</span> <span class="flare-tag">mediaAction</span> <span class="flare-tag">multiSelect</span>

> [!TIP]
> 60fps virtualised; O(visible); scroll anchoring on append/prepend.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageList } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareMessageList
  :conversationId="conversationId"
  :messages="messages"
  :currentUserId="currentUserId"
  @atBottomChange="onAtBottomChange"
  @react="onReact"
  @reply="onReply"
  />
</template>
```

```dart [Flutter]
FlareMessageList(
  conversationId: conversationId,
  messages: messages,
  currentUserId: currentUserId,
  onAtBottomChange: onAtBottomChange,
  onReact: onReact,
  onReply: onReply,
);
```

```swift [iOS]
MessageListView(conversationId: conversationId, messages: messages, currentUserId: currentUserId, onAtBottomChange: onAtBottomChange, onReact: onReact, onReply: onReply)
```

```kotlin [Android]
MessageList(
  conversationId = conversationId,
  messages = messages,
  currentUserId = currentUserId,
  onAtBottomChange = onAtBottomChange,
  onReact = onReact,
  onReply = onReply,
)
```

:::


## Examples

### Wiring up a timeline

messages come from core's timeline view; long-press actions, media taps and resend are handled by the host — the component only renders and virtualises.

::: code-group

```vue [Vue]
<FlareMessageList
  :messages="messages"
  :current-user-id="me.id"
  conversation-kind="group"
  @message-long-press="showActions"
  @media-action="openMedia"
  @resend="resend"
/>
```

```dart [Flutter]
FlareMessageList(
  messages: timeline,                 // List<FlareMessageData>
  currentUserId: me.id,
  conversationKind: FlareConversationKind.group,
  mediaDownloadStates: mediaStates,
  onMessageLongPress: showActions,
  onMediaAction: (m, content) => openMedia(content),
  onResend: (m) => resend(m.id),
)
```

```swift [iOS]
MessageListView(
  messages: timeline,
  currentUserId: me.id,
  conversationKind: .group,
  onMessageLongPress: showActions,
  onResend: resend
)
```

```kotlin [Android]
MessageList(
  messages = timeline,
  currentUserId = me.id,
  conversationKind = FlareConversationKind.Group,
  onMessageLongPress = ::showActions,
  onResend = ::resend,
)
```

:::
