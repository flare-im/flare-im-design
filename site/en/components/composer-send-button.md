---
title: ComposerSendButton
---

# ComposerSendButton

<p><span class="flare-tag">Composer</span></p>

> Send button (发送) — brand-purple when active, disabled otherwise. A composable Composer part.

**Data source**: presentational — an `active` flag in, a `send` callback out (only when active)

## Preview

<div class="flare-demo">
  <ComposerSendButtonDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `active` | `boolean` | ✔ | — | Enabled/purple when there is content to send. |
| `label` | `string` |  | `Send` | Accessible label. |


## States

<span class="flare-tag">disabled</span> <span class="flare-tag">active</span>

## Events

<span class="flare-tag">send</span>

> [!TIP]
> A part of [Composer](/en/components/composer) — use it standalone to build your own input bar.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareComposerSendButton } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareComposerSendButton
  :active="active"
  :label="label"
  @send="onSend"
  />
</template>
```

```dart [Flutter]
FlareComposerSendButton(
  active: active,
  label: label,
  onSend: onSend,
);
```

```swift [iOS]
FlareComposerSendButton(active: active, label: label, onSend: onSend)
```

```kotlin [Android]
FlareComposerSendButton(
  active = active,
  label = label,
  onSend = onSend,
)
```

:::

