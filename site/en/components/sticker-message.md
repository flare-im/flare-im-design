---
title: StickerMessage
---

# StickerMessage

<p><span class="flare-tag">Message</span></p>

> Sticker body — a bare, larger glyph / image (no bubble).

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <StickerMessageDemo />
</div>

## Emoji & sticker picker

The real composer picker — 157 animated emoji + sticker packs, all resolved from the
single cross-platform source `flare-im-design/assets/emoji-sticker` (served in the docs
at `/flare-im-ui-assets/`). Tap an emoji to insert `[key]`, tap a sticker to send it.

<div class="flare-demo">
  <EmojiStickerPanelDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `emoji` | `string` |  | `"🐱"` | Emoji fallback when no image. |
| `src` | `string` |  | — | Sticker image source. |


## States

_None_

## Events

<span class="flare-tag">click</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareStickerMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareStickerMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>StickerMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>StickerMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

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

