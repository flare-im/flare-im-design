---
title: EmojiMessage
---

# EmojiMessage

<p><span class="flare-tag">Message</span></p>

> Large-emoji body — bare, no bubble.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <EmojiMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `emoji` | `string` |  | `"🎉"` | The emoji to render large. |


## States

_None_

## Events

<span class="flare-tag">click</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareEmojiMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareEmojiMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>EmojiMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>EmojiMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareEmojiMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareEmojiMessage
  :emoji="emoji"
  @click="onClick"
  />
</template>
```

```dart [Flutter]
FlareEmojiMessage(
  emoji: emoji,
  onClick: onClick,
);
```

```swift [iOS]
EmojiMessageView(emoji: emoji, onClick: onClick)
```

```kotlin [Android]
EmojiMessage(
  emoji = emoji,
  onClick = onClick,
)
```

:::

