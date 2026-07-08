---
title: VoteMessage
---

# VoteMessage

<p><span class="flare-tag">Message</span></p>

> Vote message body — a title over options with proportional bars.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <VoteMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | Poll question. |
| `options` | `FlareVoteOption[]` |  | — | Options as { text, pct }. |


## States

_None_

## Events

_None_

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVoteMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVoteMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>VoteMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>VoteMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareVoteMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareVoteMessage
  :title="title"
  :options="options"
  />
</template>
```

```dart [Flutter]
FlareVoteMessage(
  title: title,
  options: options,
);
```

```swift [iOS]
VoteMessageView(title: title, options: options)
```

```kotlin [Android]
VoteMessage(
  title = title,
  options = options,
)
```

:::


## Examples

### Options as { text, pct }

Each option is a text label and a percentage; the bar width tracks pct. The option type is `FlareVoteOption` on every platform.

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
