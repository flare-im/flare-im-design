---
title: CallView
---

# CallView

<p><span class="flare-tag">Call</span></p>

> In-call surface — peer video/avatar, state, duration, with an overlaid control bar. Video render is host-injected.

**Data source**: RTC session state (core/media layer); video track rendered by the host

## Preview

<div class="flare-demo flare-demo--stack">
  <CallViewDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `peerName` | `string` | ✔ | — | Name of the person on the call. |
| `mode` | `'audio' \| 'video'` | ✔ | — | Audio or video — changes the layout. |
| `state` | `'calling' \| 'ringing' \| 'connected'` | ✔ | — | Calling / ringing / connected. |
| `durationLabel` | `string` |  | — | Preformatted elapsed time (mm:ss). |
| `peerAvatarUrl` | `string` |  | — | Peer avatar, shown for audio calls. |


## States

<span class="flare-tag">calling</span> <span class="flare-tag">ringing</span> <span class="flare-tag">connected</span>

## Events

<span class="flare-tag">hangup</span> <span class="flare-tag">toggleMute</span> <span class="flare-tag">toggleCamera</span> <span class="flare-tag">toggleSpeaker</span> <span class="flare-tag">switchCamera</span>

> [!TIP]
> Video track uses a host-injected render slot; the control bar is CallControls.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareCallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareCallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>CallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>CallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareCallView } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareCallView
  :peerName="peerName"
  :mode="mode"
  :state="state"
  @hangup="onHangup"
  @toggleMute="onToggleMute"
  @toggleCamera="onToggleCamera"
  />
</template>
```

```dart [Flutter]
FlareCallView(
  peerName: peerName,
  mode: mode,
  state: state,
  onHangup: onHangup,
  onToggleMute: onToggleMute,
  onToggleCamera: onToggleCamera,
);
```

```swift [iOS]
CallView(peerName: peerName, mode: mode, state: state, onHangup: onHangup, onToggleMute: onToggleMute, onToggleCamera: onToggleCamera)
```

```kotlin [Android]
CallView(
  peerName = peerName,
  mode = mode,
  state = state,
  onHangup = onHangup,
  onToggleMute = onToggleMute,
  onToggleCamera = onToggleCamera,
)
```

:::


## Examples

### In an active call

The video surface is host-injected (video slot / AnyView / videoContent); the control bar is built in and driven by RTC session state and duration.

::: code-group

```vue [Vue]
<FlareCallView peer-name="Henry" mode="video" state="connected" duration-label="02:14" @hangup="hangup" @toggle-mute="toggleMute">
  <template #video><RtcRenderer :track="remoteTrack" /></template>
</FlareCallView>
```

```dart [Flutter]
FlareCallView(
  peerName: 'Henry', mode: FlareCallMode.video, state: FlareCallState.connected,
  durationLabel: '02:14', videoContent: RtcRenderer(track: remoteTrack),
  onHangup: hangup, onToggleMute: toggleMute,
)
```

```swift [iOS]
CallView(peerName: "Henry", mode: .video, state: .connected, durationLabel: "02:14",
        video: AnyView(RtcRenderer(track: remoteTrack)), onHangup: hangup)
```

```kotlin [Android]
CallView(peerName = "Henry", mode = FlareCallMode.Video, state = FlareCallState.Connected,
     durationLabel = "02:14", videoContent = { RtcRenderer(remoteTrack) }, onHangup = ::hangup)
```

:::
