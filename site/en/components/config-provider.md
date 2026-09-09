---
title: ConfigProvider
---

# ConfigProvider

<p><span class="flare-tag">Layout</span></p>

> Global config — unify default control size/density at the root and drive language (locale) + theme (light/dark) switching; descendants read and switch via useFlareConfig(), which returns { size, setSize, locale, setLocale, themeMode, isDark, setThemeMode, toggleTheme }. The component emits no events.

**Data source**: passed in by you



## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `size` | `FlareControlSize` |  | `"md"` | Default control size. |
| `density` | `'compact' \| 'default'` |  | `"default"` | Density (reserved). |
| `locale` | `FlareLocale` |  | `已存偏好 / "zh-CN"` | Initial language ('zh-CN' \| 'en-US'); switch via useFlareConfig().setLocale(), persisted automatically. |
| `theme` | `FlareThemeMode` |  | `已存偏好 / "system"` | Initial theme ('light' \| 'dark' \| 'system'); switch via useFlareConfig().setThemeMode()/toggleTheme(), persisted automatically. |


## States

_None_

## Events

_None_

> [!TIP]
> Web-only by design: a provide/inject config wrapper (size/density/locale/theme). Native platforms achieve the same globally via SwiftUI @Environment / FlareColors.of(scheme) (iOS) and CompositionLocal / MaterialTheme (Compose), so no portable ConfigProvider component is shipped there.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConfigProvider</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
</div>


## Usage

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

