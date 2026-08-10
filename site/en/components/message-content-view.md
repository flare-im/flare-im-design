---
title: MessageContentView
---

# MessageContentView

<p><span class="flare-tag">Message</span></p>

> Content-type dispatcher — renders a message body by type via the content-type registry (text/image/video/card/vote/task/…). Extension point for products.

**Data source**: message.content from the timeline view

## Preview

<div class="flare-demo flare-demo--stack">
  <MessageContentViewDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `content` | `MessageContent` | ✓ | — | The typed message body to dispatch on. |
| `self` | `boolean` |  | — | Outgoing side — some bodies restyle (e.g. text color). |
| `previewMode` | `boolean` |  | — | Compact render for quotes/reply strips/search hits. |
| `messageId` | `string` |  | — | Id, for media actions and locate-message. |
| `messageExtra` | `Record<string, unknown>` |  | — | Type-specific extra payload passed to the renderer. |
| `senderName` | `string` |  | — | Sender name, used by some content types (e.g. cards). |
| `mediaState` | `MessageMediaDownloadUiState` |  | — | Download/progress state for media bodies. |


## States

<span class="flare-tag">ready</span> <span class="flare-tag">downloading</span> <span class="flare-tag">unsupported</span>

## Events

<span class="flare-tag">locate-message</span> <span class="flare-tag">media-action</span>

> [!TIP]
> Built-in types live in `contentTypes.registered`; register new ones for product content. Each type is also a standalone component: [TextMessage](/en/components/text-message) · [ImageMessage](/en/components/image-message) · [VideoMessage](/en/components/video-message) · [VoiceMessage](/en/components/voice-message) · [FileMessage](/en/components/file-message) · [LocationMessage](/en/components/location-message) · [ContactMessage](/en/components/contact-message) · [LinkCardMessage](/en/components/link-card-message) · [VoteMessage](/en/components/vote-message) · [TaskMessage](/en/components/task-message) · [StickerMessage](/en/components/sticker-message) · [EmojiMessage](/en/components/emoji-message) · [SystemMessage](/en/components/system-message).

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageContentView } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMessageContentView
  :content="content"
  :self="self"
  :previewMode="previewMode"
  @locate-message="onLocateMessage"
  @media-action="onMediaAction"
  />
</template>
```

```dart [Flutter]
FlareMessageContentView(
  content: content,
  self: self,
  previewMode: previewMode,
  onLocateMessage: onLocateMessage,
  onMediaAction: onMediaAction,
);
```

```swift [iOS]
MessageContentView(content: content, self: self, previewMode: previewMode, onLocateMessage: onLocateMessage, onMediaAction: onMediaAction)
```

```kotlin [Android]
MessageContentView(
  content = content,
  self = self,
  previewMode = previewMode,
  onLocateMessage = onLocateMessage,
  onMediaAction = onMediaAction,
)
```

:::


## Examples

### Each type is its own component

MessageContentView just dispatches by type — but every per-type body is exported as a standalone component with clean props, so you can drop any single one into your own layout.

::: code-group

```vue [Vue]
<!-- use any single message body on its own -->
<FlareFileMessage name="设计规范 v2.pdf" size="2.4 MB" ext="PDF" />
<FlareVoteMessage title="周会时间投票" :options="[{ text: '周四 15:00', pct: 62 }]" />
<FlareLocationMessage title="三里屯" address="北京市朝阳区" />

<!-- or let the dispatcher pick by content.type -->
<FlareMessageContentView :content="message.content" :self="isSelf" />
```

```dart [Flutter]
// each body is a widget; the dispatcher picks by type
FlareFileMessage(name: '设计规范 v2.pdf', size: '2.4 MB', ext: 'PDF');
FlareVoteMessage(title: '周会时间投票', options: options);
// or:
FlareMessageContentView(content: message.content, self: isSelf);
```

```swift [iOS]
FileMessageView(name: "设计规范 v2.pdf", size: "2.4 MB", ext: "PDF")
VoteMessageView(title: "周会时间投票", options: options)
// or: MessageContentView(content: message.content, isSelf: isSelf)
```

```kotlin [Android]
FileMessage(name = "设计规范 v2.pdf", size = "2.4 MB", ext = "PDF")
VoteMessage(title = "周会时间投票", options = options)
// or: MessageContentView(content = message.content, self = isSelf)
```

:::

### Registering a custom content type

17 content types are built in; register your own (vote/task/…) in the content registry and MessageBubble / MessageContentView dispatch to it automatically.

::: code-group

```vue [Vue]
registerContentType("vote", VotePanel);
```

```dart [Flutter]
FlareContentRegistry.register("vote", (ctx, content, c) => VotePanel(content));
```

```swift [iOS]
FlareContentRegistry.register("vote") { content, ctx in AnyView(VotePanel(content)) }
```

```kotlin [Android]
FlareContentRegistry.register("vote") { content, ctx -> VotePanel(content) }
```

:::
