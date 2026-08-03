---
title: TimeStamp
---

# TimeStamp

<p><span class="flare-tag">General</span></p>

> Relative/absolute time label for a message or conversation row.

**Data source**: message.createdAt / conversation.lastMessageAt from the view

## Preview

<div class="flare-demo">
  <TimeStampDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `label` | `string` | ✔ | — | Preformatted time string; formatting lives in core so all platforms agree. |


## States

_None_

## Events

_None_

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareTimeStamp</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareTimeStamp</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>TimeStampView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>TimeStamp</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareTimeStamp } from "@flare-im/vue-ui";
</script>
<template>
  <FlareTimeStamp
  :label="label"
  />
</template>
```

```dart [Flutter]
FlareTimeStamp(
  label: label,
);
```

```swift [iOS]
TimeStampView(label: label)
```

```kotlin [Android]
TimeStamp(
  label = label,
)
```

:::

