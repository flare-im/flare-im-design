---
title: MessageBubble
---

# MessageBubble

<p><span class="flare-tag">消息</span></p>

> 线程里的一条消息 —— 内容、发送者、分组、送达状态。正文按内容类型委派给对应视图。

**数据源**：一条消息对象（你的数据）；status 驱动状态；可选来自 Flare core 时间线

## 预览

<div class="flare-demo flare-demo--stack">
  <MessageBubbleDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `message` | `Message` | ✔ | — | 要渲染的消息。 |
| `currentUserId` | `string` | ✔ | — | 当前用户 id；判定自己 / 对方。 |
| `self` | `boolean` |  | `message.senderId === currentUserId` | 强制发送方；默认由 sender==当前用户 推导。 |
| `conversationType` | `'single' \| 'group' \| 'ai'` |  | `single` | 单聊 / 群 / AI —— 影响发送者名与分组。 |
| `groupStart` | `boolean` |  | — | 同发送者连发的首条（显示头像 / 名）。 |
| `groupEnd` | `boolean` |  | — | 连发的末条（带尾角与时间）。 |
| `multiSelectMode` | `boolean` |  | — | 渲染多选勾选框。 |
| `selected` | `boolean` |  | — | 多选态下是否被选中。 |
| `menuConfig` | `MessageMenuConfig` |  | — | 该消息长按可用的操作集合。 |
| `mediaDownloadState` | `MessageMediaDownloadUiState` |  | — | 媒体正文（图 / 视频 / 文件）的下载进度 / 状态。 |


## States

<span class="flare-tag">pending</span> <span class="flare-tag">sent</span> <span class="flare-tag">read</span> <span class="flare-tag">failed</span>

## Events

<span class="flare-tag">react</span> <span class="flare-tag">reply</span> <span class="flare-tag">edit</span> <span class="flare-tag">delete</span> <span class="flare-tag">pin</span> <span class="flare-tag">mark</span> <span class="flare-tag">preview</span>

> [!TIP]
> 乐观：status 来自 core 视图，绝不等网络。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageBubble</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageBubble</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageBubbleView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageBubble</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageBubble } from "flare-core-vue-im-ui";
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

