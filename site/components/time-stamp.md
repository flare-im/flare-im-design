---
title: TimeStamp
---

# TimeStamp

<p><span class="flare-tag">通用</span></p>

> 消息或会话行的相对 / 绝对时间标签。

**数据源**：取视图的 message.createdAt / conversation.lastMessageAt

## 预览

<div class="flare-demo">
  <TimeStampDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `label` | `string` | ✔ | — | 已格式化的时间串；格式化在 core 完成，各端一致。 |


## States

_无_

## Events

_无_

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareTimeStamp</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareTimeStamp</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>TimeStampView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>TimeStamp</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareTimeStamp } from "flare-core-vue-im-ui";
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

