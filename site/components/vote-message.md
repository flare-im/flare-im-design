---
title: VoteMessage
---

# VoteMessage

<p><span class="flare-tag">消息</span></p>

> 投票消息体 —— 标题 + 带进度条的选项。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <VoteMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | 投票标题。 |
| `options` | [`FlareVoteOption[]`](/reference/data-types#vote-option) |  | — | 选项 { text, pct } 列表。 |
| `total` | `string` |  | — | 可选页脚，如「12 人已投」。 |


## States

_无_

## Events

<span class="flare-tag">select</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVoteMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVoteMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VoteMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VoteMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareVoteMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareVoteMessage
  :title="title"
  :options="options"
  :total="total"
  @select="onSelect"
  />
</template>
```

```dart [Flutter]
FlareVoteMessage(
  title: title,
  options: options,
  total: total,
  onSelect: onSelect,
);
```

```swift [iOS]
VoteMessageView(title: title, options: options, total: total, onSelect: onSelect)
```

```kotlin [Android]
VoteMessage(
  title = title,
  options = options,
  total = total,
  onSelect = onSelect,
)
```

:::


## 示例

### 选项即 { text, pct }

每个选项是文案 + 百分比，进度条宽度跟随 pct。选项类型在各端都是 `FlareVoteOption`。

::: code-group

```vue [Vue]
<FlareVoteMessage
  title="周会时间投票"
  :options="[{ text: '周四 15:00', pct: 62 }, { text: '周五 10:00', pct: 38 }]"
/>
```

```dart [Flutter]
FlareVoteMessage(
  title: '周会时间投票',
  options: const [
    FlareVoteOption('周四 15:00', 62),
    FlareVoteOption('周五 10:00', 38),
  ],
)
```

```swift [iOS]
VoteMessageView(title: "周会时间投票", options: [
  FlareVoteOption("周四 15:00", 62),
  FlareVoteOption("周五 10:00", 38),
])
```

```kotlin [Android]
VoteMessage(
  title = "周会时间投票",
  options = listOf(
    FlareVoteOption("周四 15:00", 62),
    FlareVoteOption("周五 10:00", 38),
  ),
)
```

:::
