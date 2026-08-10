---
title: ConversationDetails
---

# ConversationDetails

<p><span class="flare-tag">会话</span></p>

> 会话信息 / 设置面板 —— 统计、连接状态，以及单会话操作（免打扰 / 置顶 / 归档 / 清空 / 删除 / 同步）。

**数据源**：取视图的会话摘要 + client 的连接状态

## 预览

<div class="flare-demo flare-demo--stack">
  <ConversationDetailsDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `conversation` | `Conversation` | ✓ | — | 要展示的会话摘要。 |
| `connectionText` | `string` |  | — | 可读的连接文案（如已连接 / 重连中）。 |
| `connectionTone` | `'ok' \| 'warn' \| 'error'` |  | — | 连接文案的语义级别 —— 决定其颜色。 |
| `messageCount` | `number` |  | — | 消息总数，显示在统计行。 |
| `latestMessageId` | `string` |  | — | 最新消息 id，用于诊断 / 跳转。 |


## States

<span class="flare-tag">muted</span> <span class="flare-tag">pinned</span> <span class="flare-tag">archived</span>

## Events

<span class="flare-tag">mute</span> <span class="flare-tag">pin</span> <span class="flare-tag">archive</span> <span class="flare-tag">clear-history</span> <span class="flare-tag">delete</span> <span class="flare-tag">mark-read</span> <span class="flare-tag">mark-unread</span> <span class="flare-tag">sync</span> <span class="flare-tag">open-devtools</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConversationDetails</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareConversationDetails</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ConversationDetailsView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ConversationDetails</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

