---
title: ImagePreviewModal
---

# ImagePreviewModal

<p><span class="flare-tag">媒体</span></p>

> 全屏图片查看器 —— 缩放 / 拖动，带进度下载。

**数据源**：图源经 client.media 解析（离主线程、渐进）

## 预览

<div class="flare-demo flare-demo--stack">
  <ImagePreviewModalDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `show` | `boolean` | ✔ | — | 控制查看器开 / 关。 |
| `imageSrc` | `string` | ✔ | — | 已解析、待展示的图源。 |
| `loading` | `boolean` |  | — | 原图仍在解析中。 |
| `alt` | `string` |  | — | 图片的无障碍描述。 |
| `downloading` | `boolean` |  | — | 正在保存中。 |
| `progressPct` | `number` |  | — | 下载进度，0–100。 |
| `zoomMin` | `number` |  | — | 最小缩放倍数。 |
| `zoomMax` | `number` |  | — | 最大缩放倍数。 |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">ready</span> <span class="flare-tag">zoomed</span> <span class="flare-tag">downloading</span>

## Events

<span class="flare-tag">close</span> <span class="flare-tag">download</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareImagePreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareImagePreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ImagePreviewView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ImagePreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

