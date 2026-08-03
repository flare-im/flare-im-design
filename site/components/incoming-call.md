---
title: IncomingCall
---

# IncomingCall

<p><span class="flare-tag">音视频通话</span></p>

> 来电 / 通话邀请 —— 来电人头像 / 名称、音视频类型，接听 / 拒绝。

**数据源**：RTC 来电信令

## 预览

<div class="flare-demo flare-demo--stack">
  <IncomingCallDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `callerName` | `string` | ✔ | — | 来电人的名称。 |
| `mode` | `'audio' \| 'video'` | ✔ | — | 音频或视频邀请。 |
| `callerAvatarUrl` | `string` |  | — | 来电人的头像。 |


## States

<span class="flare-tag">ringing</span>

## Events

<span class="flare-tag">accept</span> <span class="flare-tag">reject</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareIncomingCall</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareIncomingCall</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>IncomingCallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>IncomingCall</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareIncomingCall } from "@flare-im/vue-ui";
</script>
<template>
  <FlareIncomingCall
  :callerName="callerName"
  :mode="mode"
  :callerAvatarUrl="callerAvatarUrl"
  @accept="onAccept"
  @reject="onReject"
  />
</template>
```

```dart [Flutter]
FlareIncomingCall(
  callerName: callerName,
  mode: mode,
  callerAvatarUrl: callerAvatarUrl,
  onAccept: onAccept,
  onReject: onReject,
);
```

```swift [iOS]
IncomingCallView(callerName: callerName, mode: mode, callerAvatarUrl: callerAvatarUrl, onAccept: onAccept, onReject: onReject)
```

```kotlin [Android]
IncomingCall(
  callerName = callerName,
  mode = mode,
  callerAvatarUrl = callerAvatarUrl,
  onAccept = onAccept,
  onReject = onReject,
)
```

:::

