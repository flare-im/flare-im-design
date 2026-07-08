---
title: VideoMessage
---

# VideoMessage

<p><span class="flare-tag">消息</span></p>

> 视频消息体 —— 封面 + 播放叠层 + 时长角标。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <VideoMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `duration` | `string` |  | `"00:00"` | 时长文案（mm:ss）。 |
| `poster` | `string` |  | — | 封面图；不传则显示占位。 |
| `alt` | `string` |  | — | 视频的无障碍描述。 |


## States

_无_

## Events

<span class="flare-tag">play</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVideoMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVideoMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VideoMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VideoMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

