---
title: FilterTabs
---

# FilterTabs

<p><span class="flare-tag">General</span></p>

> Scrollable filter tablist ({value,label,badge?}) with a v-model active value and a change event.

**Data source**: presentational only

## Preview

<div class="flare-demo">
  <FilterTabsDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `options` | `FlareFilterTabOption[]` | ✔ | — | Tab options: { value, label, badge? }. |
| `v-model` | `string` |  | — | The active tab value. |


## States

<span class="flare-tag">default</span> <span class="flare-tag">active</span>

## Events

<span class="flare-tag">change</span> <span class="flare-tag">update:modelValue</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareFilterTabs</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareFilterTabs } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareFilterTabs
  :options="options"
  :v-model="v-model"
  @change="onChange"
  @update:modelValue="onUpdate:modelValue"
  />
</template>
```

:::

