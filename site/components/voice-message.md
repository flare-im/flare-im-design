---
title: VoiceMessage
---

# VoiceMessage

<p><span class="flare-tag">消息</span></p>

> 语音消息体 —— 波形 + 时长。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <VoiceMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `seconds` | `number` |  | `1` | 语音时长（秒）。 |
| `playing` | `boolean` |  | — | 是否正在播放（驱动波形 / 图标）。 |


## States

_无_

## Events

<span class="flare-tag">play</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVoiceMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVoiceMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VoiceMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VoiceMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareVoiceMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareVoiceMessage
  :seconds="seconds"
  :playing="playing"
  @play="onPlay"
  />
</template>
```

```dart [Flutter]
FlareVoiceMessage(
  seconds: seconds,
  playing: playing,
  onPlay: onPlay,
);
```

```swift [iOS]
VoiceMessageView(seconds: seconds, playing: playing, onPlay: onPlay)
```

```kotlin [Android]
VoiceMessage(
  seconds = seconds,
  playing = playing,
  onPlay = onPlay,
)
```

:::

