---
title: StatusBanner
---

# StatusBanner

<p><span class="flare-tag">通用</span></p>

> 紧凑状态条（连接 / 同步 / 运行时）—— 语气色 + 可选脉冲圆点 + 可选内联操作。

**数据源**：纯展示

## 预览

<div class="flare-demo">
  <StatusBannerDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `text` | `string` | ✔ | — | 状态文案。 |
| `tone` | `"info" \| "success" \| "warning" \| "danger" \| "neutral"` |  | — | 语义色（默认 info）。 |
| `dot` | `boolean` |  | — | 显示前置圆点（默认 true）。 |
| `pulse` | `boolean` |  | — | 圆点脉冲动画；尊重 reduced-motion。 |
| `actionText` | `string` |  | — | 可选内联操作按钮文案。 |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">action</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareStatusBanner</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
</div>


## 用法

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

