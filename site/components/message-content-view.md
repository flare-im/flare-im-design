---
title: MessageContentView
---

# MessageContentView

<p><span class="flare-tag">消息</span></p>

> 内容类型分发器 —— 经内容类型注册表按类型渲染消息正文（文本 / 图片 / 视频 / 名片 / 投票 / 任务 / …）。产品扩展点。

**数据源**：取时间线视图的 message.content

## 预览

<div class="flare-demo flare-demo--stack">
  <MessageContentViewDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `content` | `MessageContent` | ✓ | — | 要分发的带类型消息正文。 |
| `self` | `boolean` |  | — | 发送方 —— 部分正文据此换样式（如文字色）。 |
| `previewMode` | `boolean` |  | — | 紧凑渲染，用于引用 / 回复条 / 搜索命中。 |
| `messageId` | `string` |  | — | 消息 id，用于媒体操作与定位。 |
| `messageExtra` | `Record<string, unknown>` |  | — | 按类型透传给渲染器的额外载荷。 |
| `senderName` | `string` |  | — | 发送者名，部分内容类型会用（如名片）。 |
| `mediaState` | `MessageMediaDownloadUiState` |  | — | 媒体正文的下载 / 进度状态。 |


## States

<span class="flare-tag">ready</span> <span class="flare-tag">downloading</span> <span class="flare-tag">unsupported</span>

## Events

<span class="flare-tag">locate-message</span> <span class="flare-tag">media-action</span>

> [!TIP]
> 内建类型见 `contentTypes.registered`，产品内容可注册新类型。每种类型也都是独立组件：[TextMessage](/components/text-message) · [ImageMessage](/components/image-message) · [VideoMessage](/components/video-message) · [VoiceMessage](/components/voice-message) · [FileMessage](/components/file-message) · [LocationMessage](/components/location-message) · [ContactMessage](/components/contact-message) · [LinkCardMessage](/components/link-card-message) · [VoteMessage](/components/vote-message) · [TaskMessage](/components/task-message) · [StickerMessage](/components/sticker-message) · [EmojiMessage](/components/emoji-message) · [SystemMessage](/components/system-message)。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageContentView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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


## 示例

### 每个类型都是独立组件

MessageContentView 只按类型分派 —— 但每种消息体都作为独立组件导出（props 简洁），你可以把任意一个单独放进自己的布局里自由组合。

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

### 注册自定义内容类型

内建 17 种内容类型；产品把 vote / task 等注册到内容注册表，MessageBubble 与 MessageContentView 会自动分派。

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
