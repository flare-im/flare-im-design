---
title: AppShell
---

# AppShell

<p><span class="flare-tag">布局</span></p>

> 应用外壳 —— 自适应导航（手机底部 Tab / 平板·PC 侧栏）+ 内容区，撑起整个 IM 应用骨架。

**数据源**：导航项配置 + 当前路由

## 预览

<div class="flare-demo flare-demo--stack">
  <AppShellDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `items` | [`NavItem[]`](/reference/data-types#nav-item) | ✔ | — | 导航目的地，含图标 / 文案 / 角标。 |
| `activeKey` | `string` | ✔ | — | 当前选中的导航 key。 |


## States

<span class="flare-tag">mobile</span> <span class="flare-tag">tablet</span> <span class="flare-tag">desktop</span>

## Events

<span class="flare-tag">navigate</span>

> [!TIP]
> 断点自适应：手机=底部导航；平板 / PC=侧边导航。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareAppShell</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareAppShell</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>AppShellView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>AppShell</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareAppShell } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareAppShell
  :items="items"
  :activeKey="activeKey"
  @navigate="onNavigate"
  />
</template>
```

```dart [Flutter]
FlareAppShell(
  items: items,
  activeKey: activeKey,
  onNavigate: onNavigate,
);
```

```swift [iOS]
AppShellView(items: items, activeKey: activeKey, onNavigate: onNavigate)
```

```kotlin [Android]
AppShell(
  items = items,
  activeKey = activeKey,
  onNavigate = onNavigate,
)
```

:::

