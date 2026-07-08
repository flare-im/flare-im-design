---
title: ImageMessage
---

# ImageMessage

<p><span class="flare-tag">消息</span></p>

> 图片消息体 —— 圆角缩略图。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <ImageMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `src` | `string` |  | — | 图源；不传则显示占位。 |
| `width` | `number` |  | `132` | 缩略图宽（px）。 |
| `height` | `number` |  | `92` | 缩略图高（px）。 |
| `alt` | `string` |  | — | 图片的无障碍描述。 |


## States

_无_

## Events

<span class="flare-tag">click</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareImageMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareImageMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ImageMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ImageMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareImageMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareImageMessage
  :src="src"
  :width="width"
  :height="height"
  @click="onClick"
  />
</template>
```

```dart [Flutter]
FlareImageMessage(
  src: src,
  width: width,
  height: height,
  onClick: onClick,
);
```

```swift [iOS]
ImageMessageView(src: src, width: width, height: height, onClick: onClick)
```

```kotlin [Android]
ImageMessage(
  src = src,
  width = width,
  height = height,
  onClick = onClick,
)
```

:::

