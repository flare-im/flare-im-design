---
title: FileMessage
---

# FileMessage

<p><span class="flare-tag">消息</span></p>

> 文件消息体 —— 图标、名称 / 大小 / 类型、下载。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <FileMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `name` | `string` | ✓ | — | 文件名。 |
| `size` | `string` |  | — | 可读大小（如 2.4 MB）。 |
| `ext` | `string` |  | — | 扩展名 / 类型标签。 |
| `icon` | `slot` |  | — | 自定义前置图标（slot / icon 参数），如按文件类型的图标。默认文件夹。 |


## States

_无_

## Events

<span class="flare-tag">open</span> <span class="flare-tag">download</span>

> [!TIP]
> 解耦 —— 你喂 props；`download` / `open` 由宿主处理（组件不碰 URL），前置图标可自定义。实时 SDK 驱动的消息用 [MessageContentView](/components/message-content-view)。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareFileMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareFileMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FileMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FileMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareFileMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareFileMessage
  :name="name"
  :size="size"
  :ext="ext"
  @open="onOpen"
  @download="onDownload"
  />
</template>
```

```dart [Flutter]
FlareFileMessage(
  name: name,
  size: size,
  ext: ext,
  onOpen: onOpen,
  onDownload: onDownload,
);
```

```swift [iOS]
FileMessageView(name: name, size: size, ext: ext, onOpen: onOpen, onDownload: onDownload)
```

```kotlin [Android]
FileMessage(
  name = name,
  size = size,
  ext = ext,
  onOpen = onOpen,
  onDownload = onDownload,
)
```

:::

