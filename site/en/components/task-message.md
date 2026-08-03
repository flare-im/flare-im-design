---
title: TaskMessage
---

# TaskMessage

<p><span class="flare-tag">Message</span></p>

> Task message body — checkbox + title (struck when done) + meta.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <TaskMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | Task title. |
| `meta` | `string` |  | — | Secondary line (due / status). |
| `done` | `boolean` |  | — | Completed — checks the box and strikes the title. |


## States

_None_

## Events

<span class="flare-tag">toggle</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareTaskMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareTaskMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>TaskMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>TaskMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

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

