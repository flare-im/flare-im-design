---
title: LocationMessage
---

# LocationMessage

<p><span class="flare-tag">消息</span></p>

> 位置消息体 —— 地图占位 + 标题 / 地址。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <LocationMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `title` | `string` | ✓ | — | 地点名。 |
| `address` | `string` |  | — | 详细地址。 |
| `mapImage` | `string` |  | — | 静态地图图 URL；无则回退到定位占位。 |


## States

_无_

## Events

<span class="flare-tag">open</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareLocationMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareLocationMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>LocationMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>LocationMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareLocationMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareLocationMessage
  :title="title"
  :address="address"
  :mapImage="mapImage"
  @open="onOpen"
  />
</template>
```

```dart [Flutter]
FlareLocationMessage(
  title: title,
  address: address,
  mapImage: mapImage,
  onOpen: onOpen,
);
```

```swift [iOS]
LocationMessageView(title: title, address: address, mapImage: mapImage, onOpen: onOpen)
```

```kotlin [Android]
LocationMessage(
  title = title,
  address = address,
  mapImage = mapImage,
  onOpen = onOpen,
)
```

:::

