---
title: VideoPlayerModal
---

# VideoPlayerModal

<p><span class="flare-tag">媒体</span></p>

> 全屏视频播放器，带封面与标题。

**数据源**：视频经 client.media 解析（离主线程流式）

## 预览

<div class="flare-demo flare-demo--stack">
  <VideoPlayerModalDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `show` | `boolean` | ✔ | — | 控制播放器开 / 关。 |
| `videoSrc` | `string` | ✔ | — | 已解析、待播放的视频源。 |
| `poster` | `string` |  | — | 开播前展示的封面图。 |
| `title` | `string` |  | — | 播放器顶部显示的标题。 |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">playing</span> <span class="flare-tag">paused</span>

## Events

<span class="flare-tag">close</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVideoPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVideoPlayer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VideoPlayerView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VideoPlayer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

