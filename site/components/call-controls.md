---
title: CallControls
---

# CallControls

<p><span class="flare-tag">音视频通话</span></p>

> 通话控制条 —— 静音、摄像头、扬声器、翻转摄像头、挂断（音 / 视频自适应）。

**数据源**：本地 RTC 设备状态

## 预览

<div class="flare-demo">
  <CallControlsDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `muted` | `boolean` |  | — | 麦克风已静音。 |
| `cameraOn` | `boolean` |  | — | 摄像头已开（视频模式）。 |
| `speakerOn` | `boolean` |  | — | 扬声器已开（音频模式）。 |
| `mode` | `'audio' \| 'video'` |  | `video` | 音频隐藏摄像头 / 翻转；视频隐藏扬声器。 |


## States

<span class="flare-tag">audio</span> <span class="flare-tag">video</span>

## Events

<span class="flare-tag">toggleMute</span> <span class="flare-tag">toggleCamera</span> <span class="flare-tag">toggleSpeaker</span> <span class="flare-tag">switchCamera</span> <span class="flare-tag">hangup</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareCallControls</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareCallControls</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>CallControlsView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>CallControls</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareCallControls } from "@flare-im/vue-ui";
</script>
<template>
  <FlareCallControls
  :muted="muted"
  :cameraOn="cameraOn"
  :speakerOn="speakerOn"
  @toggleMute="onToggleMute"
  @toggleCamera="onToggleCamera"
  @toggleSpeaker="onToggleSpeaker"
  />
</template>
```

```dart [Flutter]
FlareCallControls(
  muted: muted,
  cameraOn: cameraOn,
  speakerOn: speakerOn,
  onToggleMute: onToggleMute,
  onToggleCamera: onToggleCamera,
  onToggleSpeaker: onToggleSpeaker,
);
```

```swift [iOS]
CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, onToggleMute: onToggleMute, onToggleCamera: onToggleCamera, onToggleSpeaker: onToggleSpeaker)
```

```kotlin [Android]
CallControls(
  muted = muted,
  cameraOn = cameraOn,
  speakerOn = speakerOn,
  onToggleMute = onToggleMute,
  onToggleCamera = onToggleCamera,
  onToggleSpeaker = onToggleSpeaker,
)
```

:::

