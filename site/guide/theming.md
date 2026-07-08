# 主题定制

主题**可定制、可自由组合、引入即用**。所有组件的视觉都来自一组 CSS 变量（`--flare-color-*`），你只需覆盖其中几个，或从一个主色**派生整套主题**——组件立即跟着变。

## 在线体验

选一个主色或预设，下面的组件实时换肤（每套主题由 `deriveFlareTheme` 从一个主色派生 hover/active/气泡/链接/选中等）：

<ThemePlayground />

## 用法

`flare-im-design-tokens/theme` 提供框架无关的运行时 API：

```ts
import {
  applyFlareTheme,
  deriveFlareTheme,
  flarePresets,
} from "flare-im-design-tokens/theme";

// 1) 从一个主色派生整套主题，作用于整页
applyFlareTheme(deriveFlareTheme({ primary: "#2563EB" }));

// 2) 直接用内置预设（violet / ocean / forest / sunset / rose / graphite）
applyFlareTheme(flarePresets.forest);

// 3) 只覆盖你想改的几个（键 = --flare-color- 之后的后缀）
applyFlareTheme({ "bubble-self": "#111827", "primary": "#111827" });

// 4) 作用于某个子树（多主题共存）
applyFlareTheme(flarePresets.rose, document.querySelector("#panel-a"));
```

也可以只覆盖语义色：

```ts
applyFlareTheme(deriveFlareTheme({
  primary: "#7C3AED",
  success: "#10B981",
  error: "#F43F5E",
}));
```

## Vue：主题 Provider

Vue 里用 `FlareThemeProvider` 把主题作用到一段子树（可嵌套、可局部）：

```vue
<script setup>
import { FlareThemeProvider } from "flare-core-vue-im-ui";
import { deriveFlareTheme } from "flare-im-design-tokens/theme";
</script>

<template>
  <FlareThemeProvider :theme="deriveFlareTheme({ primary: '#2563EB' })">
    <FlareConversationList :items="items" />
    <MessageList v-bind="thread" />
  </FlareThemeProvider>
</template>
```

## 各端

- **Web / Vue**：覆盖 CSS 变量（上面的 API），或 `FlareThemeProvider` 局部作用。
- **Flutter**：`FlareColors` 是不可变值对象——用你自己的实例（或 `copyWith` 覆盖字段）通过 `InheritedWidget`/Provider 往下传。
- **iOS**：把定制的 `FlareColors` 放进 `@Environment` 或直接传入组件。
- **Android**：`FlareColors` 是 data class——`FlareColors.Light.copy(primary = …)` 后用 `CompositionLocal` 下发。

> 底层是**同一份 tokens.json 单一源**：暗色主题已内建（`[data-flare-theme="dark"]`），运行时覆盖只是在其上再叠加你的品牌色。
