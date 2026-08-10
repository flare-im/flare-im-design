---
title: TaskMessage
---

# TaskMessage

<p><span class="flare-tag">消息</span></p>

> 任务消息体 —— 勾选框 + 标题（完成划线）+ 附注。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <TaskMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `title` | `string` | ✓ | — | 任务标题。 |
| `meta` | `string` |  | — | 次级行（截止 / 状态）。 |
| `done` | `boolean` |  | — | 已完成 —— 勾选并划线标题。 |


## States

_无_

## Events

<span class="flare-tag">toggle</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareTaskMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareTaskMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>TaskMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>TaskMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareTaskMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareTaskMessage
  :title="title"
  :meta="meta"
  :done="done"
  @toggle="onToggle"
  />
</template>
```

```dart [Flutter]
FlareTaskMessage(
  title: title,
  meta: meta,
  done: done,
  onToggle: onToggle,
);
```

```swift [iOS]
TaskMessageView(title: title, meta: meta, done: done, onToggle: onToggle)
```

```kotlin [Android]
TaskMessage(
  title = title,
  meta = meta,
  done = done,
  onToggle = onToggle,
)
```

:::

