---
title: LinkCardMessage
---

# LinkCardMessage

<p><span class="flare-tag">消息</span></p>

> 链接卡片 —— 缩略图 + 标题 + 域名。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <LinkCardMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | 链接标题。 |
| `domain` | `string` |  | — | 带链接图标显示的域名。 |
| `thumb` | `string` |  | — | 缩略图；无则回退占位。 |
| `description` | `string` |  | — | 标题下的可选描述行。 |


## States

_无_

## Events

<span class="flare-tag">open</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareLinkCardMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareLinkCardMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>LinkCardMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>LinkCardMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareLinkCardMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareLinkCardMessage
  :title="title"
  :domain="domain"
  :thumb="thumb"
  @open="onOpen"
  />
</template>
```

```dart [Flutter]
FlareLinkCardMessage(
  title: title,
  domain: domain,
  thumb: thumb,
  onOpen: onOpen,
);
```

```swift [iOS]
LinkCardMessageView(title: title, domain: domain, thumb: thumb, onOpen: onOpen)
```

```kotlin [Android]
LinkCardMessage(
  title = title,
  domain = domain,
  thumb = thumb,
  onOpen = onOpen,
)
```

:::

