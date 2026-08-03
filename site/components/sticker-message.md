---
title: StickerMessage
---

# StickerMessage

<p><span class="flare-tag">消息</span></p>

> 贴纸消息体 —— 裸的大图 / emoji（无气泡）。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <StickerMessageDemo />
</div>

## 表情包 / 贴纸选择器

真实的输入框选择器 —— 157 个动图表情 + 贴纸包，资源统一来自 `flare-im-design/assets/emoji-sticker`（四端共享的单一真相源，站内经 `/flare-im-ui-assets/` 服务）。点选表情插入 `[key]`，点选贴纸即发送。

<div class="flare-demo">
  <EmojiStickerPanelDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `emoji` | `string` |  | `"🐱"` | 无图片时的 emoji 兜底。 |
| `src` | `string` |  | — | 贴纸图源。 |


## States

_无_

## Events

<span class="flare-tag">click</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareStickerMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareStickerMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>StickerMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>StickerMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareStickerMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareStickerMessage
  :emoji="emoji"
  :src="src"
  @click="onClick"
  />
</template>
```

```dart [Flutter]
FlareStickerMessage(
  emoji: emoji,
  src: src,
  onClick: onClick,
);
```

```swift [iOS]
StickerMessageView(emoji: emoji, src: src, onClick: onClick)
```

```kotlin [Android]
StickerMessage(
  emoji = emoji,
  src = src,
  onClick = onClick,
)
```

:::

