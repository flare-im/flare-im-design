---
title: ResponsiveLayout
---

# ResponsiveLayout

<p><span class="flare-tag">布局</span></p>

> 自适应会话布局 —— 手机单栏（列表↔聊天切换）、平板双栏（列表+聊天）、PC 三栏（列表+聊天+详情）。

**数据源**：纯布局；三个 slot（list/chat/detail）由产品填充

## 预览

<div class="flare-demo flare-demo--stack">
  <ResponsiveLayoutDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `hasDetail` | `boolean` |  | — | 是否存在详情栏（启用三栏）。 |
| `activePane` | `'list' \| 'chat' \| 'detail'` |  | — | 手机端前置显示哪个栏。 |


## States

<span class="flare-tag">single</span> <span class="flare-tag">dual</span> <span class="flare-tag">triple</span>

## Events

<span class="flare-tag">paneChange</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ResponsiveLayoutView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareResponsiveLayout } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareResponsiveLayout
  :hasDetail="hasDetail"
  :activePane="activePane"
  @paneChange="onPaneChange"
  />
</template>
```

```dart [Flutter]
FlareResponsiveLayout(
  hasDetail: hasDetail,
  activePane: activePane,
  onPaneChange: onPaneChange,
);
```

```swift [iOS]
ResponsiveLayoutView(hasDetail: hasDetail, activePane: activePane, onPaneChange: onPaneChange)
```

```kotlin [Android]
ResponsiveLayout(
  hasDetail = hasDetail,
  activePane = activePane,
  onPaneChange = onPaneChange,
)
```

:::


## 示例

### 自适应三栏

PC 三栏（列表+聊天+详情），平板双栏，手机单栏按 activePane 切换并显示返回。

::: code-group

```vue [Vue]
<FlareResponsiveLayout :has-detail="true" :active-pane="pane" @pane-change="p => pane = p">
  <template #list><FlareConversationList :items="rows" /></template>
  <template #chat><FlareMessageList v-bind="thread" /></template>
  <template #detail><FlareConversationDetails :conversation="conv" /></template>
</FlareResponsiveLayout>
```

```dart [Flutter]
FlareResponsiveLayout(
  activePane: pane,
  onPaneChange: (p) => setState(() => pane = p),
  list: FlareConversationList(items: rows),
  chat: FlareMessageList(messages: timeline, currentUserId: me.id),
  detail: FlareConversationDetails(conversation: conv),
)
```

```swift [iOS]
ResponsiveLayoutView(
  activePane: pane, onPaneChange: { pane = $0 },
  list: AnyView(ConversationListView(items: rows)),
  chat: AnyView(MessageListView(messages: timeline, currentUserId: me.id)),
  detail: AnyView(ConversationDetailsView(conversation: conv))
)
```

```kotlin [Android]
ResponsiveLayout(
  activePane = pane,
  onPaneChange = { pane = it },
  list = { ConversationList(items = rows) },
  chat = { MessageList(messages = timeline, currentUserId = me.id) },
  detail = { ConversationDetails(conversation = conv) },
)
```

:::
