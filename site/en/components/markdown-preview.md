---
title: MarkdownPreview
---

# MarkdownPreview

<p><span class="flare-tag">Media</span></p>

> Rendered read-only Markdown/RichDoc content with optional stats.

**Data source**: a Markdown / RichDoc string (your data)

## Preview

<div class="flare-demo flare-demo--stack">
  <MarkdownPreviewDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `content` | `string` | ✔ | — | Markdown/RichDoc string to render read-only. |
| `showStats` | `boolean` |  | — | Show word/char counts under the content. |


## States

<span class="flare-tag">rendered</span>

## Events

_None_

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMarkdownPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMarkdownPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MarkdownPreviewView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MarkdownPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMarkdownPreview } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMarkdownPreview
  :content="content"
  :showStats="showStats"
  />
</template>
```

```dart [Flutter]
FlareMarkdownPreview(
  content: content,
  showStats: showStats,
);
```

```swift [iOS]
MarkdownPreviewView(content: content, showStats: showStats)
```

```kotlin [Android]
MarkdownPreview(
  content = content,
  showStats = showStats,
)
```

:::

