---
title: ComposerReplyStrip
---

# ComposerReplyStrip

<p><span class="flare-tag">Composer</span></p>

> Reply strip (回复条) — shown above the input when replying: left brand rail + sender / summary + cancel.

**Data source**: presentational — sender + summary in, a `cancel` callback out

## Preview

<div class="flare-demo">
  <ComposerReplyStripDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `senderName` | `string` | ✔ | — | Name of the person being replied to. |
| `summary` | `string` | ✔ | — | One-line preview of the quoted message. |
| `label` | `string` |  | `Reply` | Leading text before the sender. |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">cancel</span>

> [!TIP]
> A part of [Composer](/en/components/composer) — use it standalone to build your own input bar.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareComposerReplyStrip } from "@flare-im/vue-ui";
</script>
<template>
  <FlareComposerReplyStrip
  :senderName="senderName"
  :summary="summary"
  :label="label"
  @cancel="onCancel"
  />
</template>
```

```dart [Flutter]
FlareComposerReplyStrip(
  senderName: senderName,
  summary: summary,
  label: label,
  onCancel: onCancel,
);
```

```swift [iOS]
FlareComposerReplyStrip(senderName: senderName, summary: summary, label: label, onCancel: onCancel)
```

```kotlin [Android]
FlareComposerReplyStrip(
  senderName = senderName,
  summary = summary,
  label = label,
  onCancel = onCancel,
)
```

:::

