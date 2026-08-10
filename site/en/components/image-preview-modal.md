---
title: ImagePreviewModal
---

# ImagePreviewModal

<p><span class="flare-tag">Media</span></p>

> Full-screen image viewer — zoom/pan, download with progress.

**Data source**: media resolved via client.media (off-thread, progressive)

## Preview

<div class="flare-demo flare-demo--stack">
  <ImagePreviewModalDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `show` | `boolean` | ✓ | — | Controls open/close of the viewer. |
| `imageSrc` | `string` | ✓ | — | Resolved image source to display. |
| `loading` | `boolean` |  | — | Full-res still resolving. |
| `alt` | `string` |  | — | Accessible description of the image. |
| `downloading` | `boolean` |  | — | A save is in progress. |
| `progressPct` | `number` |  | — | Download progress, 0–100. |
| `zoomMin` | `number` |  | — | Minimum zoom factor. |
| `zoomMax` | `number` |  | — | Maximum zoom factor. |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">ready</span> <span class="flare-tag">zoomed</span> <span class="flare-tag">downloading</span>

## Events

<span class="flare-tag">close</span> <span class="flare-tag">download</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareImagePreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareImagePreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ImagePreviewView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ImagePreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareImagePreview } from "@flare-im/vue-ui";
</script>
<template>
  <FlareImagePreview
  :show="show"
  :imageSrc="imageSrc"
  :loading="loading"
  @close="onClose"
  @download="onDownload"
  />
</template>
```

```dart [Flutter]
FlareImagePreview(
  show: show,
  imageSrc: imageSrc,
  loading: loading,
  onClose: onClose,
  onDownload: onDownload,
);
```

```swift [iOS]
ImagePreviewView(show: show, imageSrc: imageSrc, loading: loading, onClose: onClose, onDownload: onDownload)
```

```kotlin [Android]
ImagePreview(
  show = show,
  imageSrc = imageSrc,
  loading = loading,
  onClose = onClose,
  onDownload = onDownload,
)
```

:::

