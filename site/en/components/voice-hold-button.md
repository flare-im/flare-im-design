---
title: VoiceHoldButton
---

# VoiceHoldButton

<p><span class="flare-tag">Composer</span></p>

> Hold-to-talk voice button — press to record, slide up to cancel. A composable Composer part.

**Data source**: presentational — raises start / end / cancel; the host records and sends

## Preview

<div class="flare-demo">
  <VoiceHoldButtonDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `label` | `string` |  | — | Idle label (e.g. Hold to talk). |
| `recordingLabel` | `string` |  | — | Label while recording. |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">recording</span> <span class="flare-tag">cancelHint</span>

## Events

<span class="flare-tag">start</span> <span class="flare-tag">end</span> <span class="flare-tag">cancel</span>

> [!TIP]
> A part of [Composer](/en/components/composer) — use it standalone to build your own input bar.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareVoiceHoldButton } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareVoiceHoldButton
  :label="label"
  :recordingLabel="recordingLabel"
  @start="onStart"
  @end="onEnd"
  @cancel="onCancel"
  />
</template>
```

```dart [Flutter]
FlareVoiceHoldButton(
  label: label,
  recordingLabel: recordingLabel,
  onStart: onStart,
  onEnd: onEnd,
  onCancel: onCancel,
);
```

```swift [iOS]
FlareVoiceHoldButton(label: label, recordingLabel: recordingLabel, onStart: onStart, onEnd: onEnd, onCancel: onCancel)
```

```kotlin [Android]
FlareVoiceHoldButton(
  label = label,
  recordingLabel = recordingLabel,
  onStart = onStart,
  onEnd = onEnd,
  onCancel = onCancel,
)
```

:::

