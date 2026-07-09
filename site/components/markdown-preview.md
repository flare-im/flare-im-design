---
title: MarkdownPreview
---

# MarkdownPreview

<p><span class="flare-tag">媒体</span></p>

> 只读渲染的 Markdown/RichDoc 内容，可选字数统计。

**数据源**：Markdown / RichDoc 字符串（你的数据）

## 预览

<div class="flare-demo flare-demo--stack">
  <MarkdownPreviewDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `content` | `string` | ✔ | — | 只读渲染的 Markdown/RichDoc 串。 |
| `showStats` | `boolean` |  | — | 在内容下方显示字 / 词数。 |


## States

<span class="flare-tag">rendered</span>

## Events

_无_

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMarkdownPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMarkdownPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MarkdownPreviewView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MarkdownPreview</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareMarkdownPreview } from "flare-core-vue-im-ui";
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

