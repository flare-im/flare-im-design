---
title: ContactMessage
---

# ContactMessage

<p><span class="flare-tag">消息</span></p>

> 名片消息体 —— pastel 头像 + 名称 / ID。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <ContactMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `name` | `string` | ✓ | — | 联系人名（驱动 pastel 头像）。 |
| `avatarUrl` | `string` |  | — | 头像图；无则回退到 pastel 首字母。 |
| `subtitle` | `string` |  | — | 自由副标题（用户名 / ID / 部门…）。 |


## States

_无_

## Events

<span class="flare-tag">open</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareContactMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareContactMessage
  :name="name"
  :avatarUrl="avatarUrl"
  :subtitle="subtitle"
  @open="onOpen"
  />
</template>
```

```dart [Flutter]
FlareContactMessage(
  name: name,
  avatarUrl: avatarUrl,
  subtitle: subtitle,
  onOpen: onOpen,
);
```

```swift [iOS]
ContactMessageView(name: name, avatarUrl: avatarUrl, subtitle: subtitle, onOpen: onOpen)
```

```kotlin [Android]
ContactMessage(
  name = name,
  avatarUrl = avatarUrl,
  subtitle = subtitle,
  onOpen = onOpen,
)
```

:::

