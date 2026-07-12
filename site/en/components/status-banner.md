---
title: StatusBanner
---

# StatusBanner

<p><span class="flare-tag">General</span></p>

> Compact status strip (connection / sync / runtime) with a tone, an optional pulsing dot and an optional inline action.

**Data source**: presentational only

## Preview

<div class="flare-demo">
  <StatusBannerDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `text` | `string` | ✔ | — | The status message. |
| `tone` | `"info" \| "success" \| "warning" \| "danger" \| "neutral"` |  | — | Semantic tone (default info). |
| `dot` | `boolean` |  | — | Show the leading dot (default true). |
| `pulse` | `boolean` |  | — | Pulse the dot; respects reduced-motion. |
| `actionText` | `string` |  | — | Optional inline action label. |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">action</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareStatusBanner</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareStatusBanner } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareStatusBanner
  :text="text"
  :tone="tone"
  :dot="dot"
  @action="onAction"
  />
</template>
```

:::

