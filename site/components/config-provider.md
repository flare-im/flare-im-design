---
title: ConfigProvider
---

# ConfigProvider

<p><span class="flare-tag">布局</span></p>

> 全局配置 —— 在根部统一默认控件尺寸/密度,并驱动多语言(locale)与主题(浅色/深色)切换;后代用 useFlareConfig() 读取与切换,它返回 { size, setSize, locale, setLocale, themeMode, isDark, setThemeMode, toggleTheme }。该组件不对外发事件。

**数据源**：由你传入



## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `size` | `FlareControlSize` |  | `"md"` | 默认控件尺寸。 |
| `density` | `'compact' \| 'default'` |  | `"default"` | 密度(预留)。 |
| `locale` | `FlareLocale` |  | `已存偏好 / "zh-CN"` | 初始语言('zh-CN' \| 'en-US');后代用 useFlareConfig().setLocale() 切换,自动持久化。 |
| `theme` | `FlareThemeMode` |  | `已存偏好 / "system"` | 初始主题('light' \| 'dark' \| 'system');后代用 useFlareConfig().setThemeMode()/toggleTheme() 切换,自动持久化。 |


## States

_无_

## Events

_无_

> [!TIP]
> 按设计仅 web:provide/inject 的全局配置包裹件(size/density/locale/theme)。原生端通过 SwiftUI @Environment / FlareColors.of(scheme)(iOS)与 CompositionLocal / MaterialTheme(Compose)达成同等全局配置,故不提供可移植的 ConfigProvider 组件。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConfigProvider</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareConfigProvider } from "@flare-im/vue-ui";
</script>
<template>
  <FlareConfigProvider
  :size="size"
  :density="density"
  :locale="locale"
  />
</template>
```

:::

