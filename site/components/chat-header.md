---
title: ChatHeader
---

# ChatHeader

<p><span class="flare-tag">消息</span></p>

> 当前会话头部 —— 标题、副标题 / 在线态，以及头部操作（搜索 / 通话 / 详情）。

**数据源**：当前会话摘要 + 对端在线态（你的数据）

## 预览

<div class="flare-demo flare-demo--stack">
  <ChatHeaderDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | 头部显示的会话名。 |
| `subtitle` | `string` |  | — | 副标题行（成员数、正在输入、最后在线…）。 |
| `presence` | `'online' \| 'offline' \| 'busy' \| 'away'` |  | — | 单聊对端在线态；驱动状态点。 |


## States

<span class="flare-tag">online</span> <span class="flare-tag">offline</span>

## Events

<span class="flare-tag">search</span> <span class="flare-tag">call</span> <span class="flare-tag">details</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareChatHeader</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareChatHeader</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ChatHeaderView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ChatHeader</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

