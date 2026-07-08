---
title: VideoMessage
---

# VideoMessage

<p><span class="flare-tag">Message</span></p>

> Video message body — poster with a play overlay and duration badge.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <VideoMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `duration` | `string` |  | `"00:00"` | Duration label (mm:ss). |
| `poster` | `string` |  | — | Poster image; omit to show a placeholder. |
| `alt` | `string` |  | — | Accessible description of the video. |


## States

_None_

## Events

<span class="flare-tag">play</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVideoMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVideoMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VideoMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VideoMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareVideoMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareVideoMessage
  :duration="duration"
  :poster="poster"
  :alt="alt"
  @play="onPlay"
  />
</template>
```

```dart [Flutter]
FlareVideoMessage(
  duration: duration,
  poster: poster,
  alt: alt,
  onPlay: onPlay,
);
```

```swift [iOS]
VideoMessageView(duration: duration, poster: poster, alt: alt, onPlay: onPlay)
```

```kotlin [Android]
VideoMessage(
  duration = duration,
  poster = poster,
  alt = alt,
  onPlay = onPlay,
)
```

:::

