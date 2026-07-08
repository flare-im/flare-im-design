---
title: PinnedMessageBar
---

# PinnedMessageBar

<p><span class="flare-tag">消息</span></p>

> 线程上方的置顶消息吸顶条；点按定位到被置顶的消息。

**数据源**：取时间线视图的置顶消息

## 预览

<div class="flare-demo flare-demo--stack">
  <PinnedBarDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `items` | [`PinnedMessageItem[]`](/reference/data-types#pinned-message-item) | ✔ | — | 置顶消息集；多条时条内轮播。 |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">single</span> <span class="flare-tag">many</span>

## Events

<span class="flare-tag">focus</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlarePinnedMessageBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlarePinnedMessageBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>PinnedMessageBarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>PinnedMessageBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlarePinnedMessageBar } from "flare-core-vue-im-ui";
</script>
<template>
  <FlarePinnedMessageBar
  :items="items"
  @focus="onFocus"
  />
</template>
```

```dart [Flutter]
FlarePinnedMessageBar(
  items: items,
  onFocus: onFocus,
);
```

```swift [iOS]
PinnedMessageBarView(items: items, onFocus: onFocus)
```

```kotlin [Android]
PinnedMessageBar(
  items = items,
  onFocus = onFocus,
)
```

:::

