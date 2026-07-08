---
title: FileMessage
---

# FileMessage

<p><span class="flare-tag">Message</span></p>

> File message body — icon, name / size / ext, download affordance.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <FileMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `name` | `string` | ✔ | — | File name. |
| `size` | `string` |  | — | Human-readable size (e.g. 2.4 MB). |
| `ext` | `string` |  | — | Extension / kind label. |
| `icon` | `slot` |  | — | Custom leading icon (a slot / icon param), e.g. a per-file-type glyph. Defaults to a folder. |


## States

_None_

## Events

<span class="flare-tag">open</span> <span class="flare-tag">download</span>

> [!TIP]
> Decoupled — you pass props; `download` / `open` are handled by the host (the component never touches the URL), and the leading icon is customizable. For live SDK-driven messages use [MessageContentView](/en/components/message-content-view).

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareFileMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareFileMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FileMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FileMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareFileMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareFileMessage
  :name="name"
  :size="size"
  :ext="ext"
  @open="onOpen"
  @download="onDownload"
  />
</template>
```

```dart [Flutter]
FlareFileMessage(
  name: name,
  size: size,
  ext: ext,
  onOpen: onOpen,
  onDownload: onDownload,
);
```

```swift [iOS]
FileMessageView(name: name, size: size, ext: ext, onOpen: onOpen, onDownload: onDownload)
```

```kotlin [Android]
FileMessage(
  name = name,
  size = size,
  ext = ext,
  onOpen = onOpen,
  onDownload = onDownload,
)
```

:::

