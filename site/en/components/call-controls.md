---
title: CallControls
---

# CallControls

<p><span class="flare-tag">Call</span></p>

> Call control bar — mute, camera, speaker, flip camera, hang up (adapts to audio/video).

**Data source**: local RTC device state

## Preview

<div class="flare-demo">
  <CallControlsDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `muted` | `boolean` |  | — | Mic is muted. |
| `cameraOn` | `boolean` |  | — | Camera is on (video mode). |
| `speakerOn` | `boolean` |  | — | Speaker is on (audio mode). |
| `mode` | `'audio' \| 'video'` |  | `video` | Audio hides camera/flip; video hides speaker. |


## States

<span class="flare-tag">audio</span> <span class="flare-tag">video</span>

## Events

<span class="flare-tag">toggleMute</span> <span class="flare-tag">toggleCamera</span> <span class="flare-tag">toggleSpeaker</span> <span class="flare-tag">switchCamera</span> <span class="flare-tag">hangup</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareCallControls</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareCallControls</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>CallControlsView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>CallControls</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareCallControls } from "flare-core-vue-im-ui";
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

