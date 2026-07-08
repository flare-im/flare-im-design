---
title: ImageMessage
---

# ImageMessage

<p><span class="flare-tag">Message</span></p>

> Image message body — a rounded thumbnail.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <ImageMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `src` | `string` |  | — | Image source; omit to show a placeholder. |
| `width` | `number` |  | `132` | Thumbnail width in px. |
| `height` | `number` |  | `92` | Thumbnail height in px. |


## States

_None_

## Events

<span class="flare-tag">click</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareImageMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareImageMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ImageMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ImageMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

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

