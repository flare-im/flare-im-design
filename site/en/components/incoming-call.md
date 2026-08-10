---
title: IncomingCall
---

# IncomingCall

<p><span class="flare-tag">Call</span></p>

> Incoming call / invite — caller avatar/name, audio/video kind, accept & reject.

**Data source**: RTC incoming-call signaling

## Preview

<div class="flare-demo flare-demo--stack">
  <IncomingCallDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `callerName` | `string` | ✓ | — | Name of the caller. |
| `mode` | `'audio' \| 'video'` | ✓ | — | Audio or video invite. |
| `callerAvatarUrl` | `string` |  | — | Caller's avatar. |


## States

<span class="flare-tag">ringing</span>

## Events

<span class="flare-tag">accept</span> <span class="flare-tag">reject</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareIncomingCall</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareIncomingCall</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>IncomingCallView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>IncomingCall</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

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

