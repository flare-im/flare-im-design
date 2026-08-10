---
title: VideoPlayerModal
---

# VideoPlayerModal

<p><span class="flare-tag">Media</span></p>

> Full-screen video player with poster and title.

**Data source**: media resolved via client.media (off-thread streaming)

## Preview

<div class="flare-demo flare-demo--stack">
  <VideoPlayerModalDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `show` | `boolean` | ✓ | — | Controls open/close of the player. |
| `videoSrc` | `string` | ✓ | — | Resolved video source to play. |
| `poster` | `string` |  | — | Still shown before playback starts. |
| `title` | `string` |  | — | Title shown in the player chrome. |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">playing</span> <span class="flare-tag">paused</span>

## Events

<span class="flare-tag">close</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVideoPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVideoPlayer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VideoPlayerView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VideoPlayer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareVideoPreview } from "@flare-im/vue-ui";
</script>
<template>
  <FlareVideoPreview
  :show="show"
  :videoSrc="videoSrc"
  :poster="poster"
  @close="onClose"
  />
</template>
```

```dart [Flutter]
FlareVideoPlayer(
  show: show,
  videoSrc: videoSrc,
  poster: poster,
  onClose: onClose,
);
```

```swift [iOS]
VideoPlayerView(show: show, videoSrc: videoSrc, poster: poster, onClose: onClose)
```

```kotlin [Android]
VideoPlayer(
  show = show,
  videoSrc = videoSrc,
  poster = poster,
  onClose = onClose,
)
```

:::

