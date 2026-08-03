---
title: FilterTabs
---

# FilterTabs

<p><span class="flare-tag">通用</span></p>

> 可横滚筛选标签（{value,label,badge?}）—— v-model 绑定当前值 + change 事件。

**数据源**：纯展示

## 预览

<div class="flare-demo">
  <FilterTabsDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `options` | `FlareFilterTabOption[]` | ✔ | — | 标签项：{ value, label, badge? }。 |
| `v-model` | `string` |  | — | 当前选中的标签值。 |


## States

<span class="flare-tag">default</span> <span class="flare-tag">active</span>

## Events

<span class="flare-tag">change</span> <span class="flare-tag">update:modelValue</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareFilterTabs</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareFilterTabs } from "@flare-im/vue-ui";
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

