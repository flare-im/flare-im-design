---
title: CallView
---

# CallView

<p><span class="flare-tag">音视频通话</span></p>

> 音视频通话中界面 —— 对端画面 / 头像、状态、时长，叠加控制条。视频渲染由宿主注入。

**数据源**：RTC 会话状态（core / 媒体层）；画面轨道由宿主渲染

## 预览

<div class="flare-demo flare-demo--stack">
  <CallViewDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `peerName` | `string` | ✔ | — | 通话对端的名称。 |
| `mode` | `'audio' \| 'video'` | ✔ | — | 音频或视频 —— 改变版式。 |
| `state` | `'calling' \| 'ringing' \| 'connected'` | ✔ | — | 呼叫中 / 响铃中 / 已接通。 |
| `durationLabel` | `string` |  | — | 已格式化的通话时长（mm:ss）。 |
| `peerAvatarUrl` | `string` |  | — | 对端头像，音频通话时显示。 |


## States

<span class="flare-tag">calling</span> <span class="flare-tag">ringing</span> <span class="flare-tag">connected</span>

## Events

<span class="flare-tag">hangup</span> <span class="flare-tag">toggleMute</span> <span class="flare-tag">toggleCamera</span> <span class="flare-tag">toggleSpeaker</span> <span class="flare-tag">switchCamera</span>

> [!TIP]
> 视频轨道用宿主注入的渲染 slot；控制条为 CallControls。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareCallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareCallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>CallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>CallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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


## 示例

### 音视频通话中

视频画面由宿主注入（video 插槽 / AnyView / videoContent）；控制条内建，状态与时长由 RTC 会话驱动。

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
