---
title: MessageList
---

# MessageList

<p><span class="flare-tag">消息</span></p>

> 虚拟化消息线程 —— 分组、加载更早、多选、逐条操作、媒体状态。

**数据源**：消息数组（你的数据），窗口化渲染，加载更早由你的 onLoadOlder 回调触发；可选接 Flare core 时间线的 loadOlder()

## 预览

<div class="flare-demo flare-demo--stack">
  <MessageListDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `conversationId` | `string` | ✔ | — | 打开哪条时间线。 |
| `conversationType` | `'single' \| 'group' \| 'ai'` |  | — | 单聊 / 群 / AI —— 影响气泡版式。 |
| `messages` | `Message[]` | ✔ | — | 视图给出的窗口化消息片段。 |
| `currentUserId` | `string` | ✔ | — | 当前用户 id，用于自 / 他判定。 |
| `multiSelectMode` | `boolean` |  | — | 开启逐条多选。 |
| `selectedIds` | `string[]` |  | — | 多选态下已勾选的 id。 |
| `loadingOlder` | `boolean` |  | — | 顶部显示加载更早的转圈。 |
| `hasOlder` | `boolean` |  | — | 是否还有更早历史可翻。 |
| `bottomInset` | `number` |  | — | 底部额外内边距（如让开输入框）。 |
| `menuConfig` | `MessageMenuConfig` |  | — | 整表可用的长按操作集合。 |
| `mediaDownloadStates` | `Record<string, MessageMediaDownloadUiState>` |  | — | messageId → 媒体下载状态 的映射。 |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">loadingOlder</span> <span class="flare-tag">atBottom</span> <span class="flare-tag">multiSelect</span>

## Events

<span class="flare-tag">atBottomChange</span> <span class="flare-tag">react</span> <span class="flare-tag">reply</span> <span class="flare-tag">edit</span> <span class="flare-tag">delete</span> <span class="flare-tag">recall</span> <span class="flare-tag">forward</span> <span class="flare-tag">pin</span> <span class="flare-tag">mark</span> <span class="flare-tag">preview</span> <span class="flare-tag">resend</span> <span class="flare-tag">mediaAction</span> <span class="flare-tag">multiSelect</span>

> [!TIP]
> 60fps 虚拟化；O(visible)；追加 / 前插时锚定滚动位。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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


## 示例

### 接入一个会话时间线

messages 来自 core 的时间线视图；长按弹出操作、点击媒体、失败重发都由宿主处理，组件只做展示与虚拟化。

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
