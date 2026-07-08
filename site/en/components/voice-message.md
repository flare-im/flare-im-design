---
title: VoiceMessage
---

# VoiceMessage

<p><span class="flare-tag">Message</span></p>

> Audio / voice message body — a waveform and duration.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <VoiceMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `seconds` | `number` |  | `1` | Clip length in seconds. |


## States

_None_

## Events

_None_

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVoiceMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVoiceMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VoiceMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VoiceMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareVoiceMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareVoiceMessage
  :seconds="seconds"
  />
</template>
```

```dart [Flutter]
FlareVoiceMessage(
  seconds: seconds,
);
```

```swift [iOS]
VoiceMessageView(seconds: seconds)
```

```kotlin [Android]
VoiceMessage(
  seconds = seconds,
)
```

:::

