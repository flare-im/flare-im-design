---
title: LocationMessage
---

# LocationMessage

<p><span class="flare-tag">Message</span></p>

> Location message body — a map placeholder over title / address.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <LocationMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | Place name. |
| `address` | `string` |  | — | Full address line. |
| `mapImage` | `string` |  | — | Static map image URL; falls back to a pin placeholder. |


## States

_None_

## Events

<span class="flare-tag">open</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareLocationMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareLocationMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>LocationMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>LocationMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareLocationMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareLocationMessage
  :title="title"
  :address="address"
  :mapImage="mapImage"
  @open="onOpen"
  />
</template>
```

```dart [Flutter]
FlareLocationMessage(
  title: title,
  address: address,
  mapImage: mapImage,
  onOpen: onOpen,
);
```

```swift [iOS]
LocationMessageView(title: title, address: address, mapImage: mapImage, onOpen: onOpen)
```

```kotlin [Android]
LocationMessage(
  title = title,
  address = address,
  mapImage = mapImage,
  onOpen = onOpen,
)
```

:::

