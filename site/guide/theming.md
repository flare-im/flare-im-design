# 主题定制

主题**可定制、可自由组合、引入即用**。所有组件的视觉都来自一组 CSS 变量（`--flare-color-*`），你只需覆盖其中几个，或从一个主色**派生整套主题**——组件立即跟着变。

## 在线体验

选一个主色或预设，下面的组件实时换肤（每套主题由 `deriveFlareTheme` 从一个主色派生 hover/active/气泡/链接/选中等）：

<ThemePlayground />

## 引入即用（纯 CSS · 任何项目）

最通用的方式：导入一次样式，再用普通 CSS 覆盖几个变量——**不需要 JS、不需要 SDK、不挑框架**。

```ts
// 1) 应用入口导入一次基础样式
import "@flare-im/vue-ui/style.css";
```

```css
/* 2) 覆盖权威变量即整体换肤：组件的每处颜色最终都解析到这组 --flare-color-* */
:root {
  --flare-color-primary: #0d9488;      /* 主色：未读徽标 / 发送键 / 选中 / 强调 */
  --flare-color-bubble-self: #0d9488;  /* 己方气泡 */
  --flare-color-text-link: #0d9488;    /* 链接 */
  --flare-color-bg-selected: #d5f5f0;  /* 选中行底 */
}

/* 只想局部换肤？作用到某个容器即可，多主题可共存 */
.brand-b {
  --flare-color-primary: #e11d48;
  --flare-color-bubble-self: #e11d48;
}
```

想从**一个主色自动派生**整套（hover / active / 气泡 / 链接 / 选中）？用下面的 `deriveFlareTheme`。

### 可覆盖的权威变量

| 变量 | 作用 |
|---|---|
| `--flare-color-primary` · `-hover` · `-active` | 主色及其悬停 / 按下态 |
| `--flare-color-bubble-self` | 己方消息气泡底色 |
| `--flare-color-text-link` · `-link-hover` | 链接色 |
| `--flare-color-bg-primary` · `-secondary` · `-tertiary` | 背景层级 |
| `--flare-color-bg-selected` · `-hover` | 选中 / 悬停底 |
| `--flare-color-text-primary` · `-secondary` · `-tertiary` | 文本层级 |
| `--flare-color-border-primary` · `-secondary` | 描边 |
| `--flare-color-success` · `error` · `warning` | 语义色（换品牌色时通常保留） |

完整清单见[设计 Tokens](/guide/tokens)。

## 用法

`@flare-im/tokens/theme` 提供框架无关的运行时 API：

```ts
import {
  applyFlareTheme,
  deriveFlareTheme,
  flarePresets,
} from "@flare-im/tokens/theme";

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
import { FlareThemeProvider } from "@flare-im/vue-ui";
import { deriveFlareTheme } from "@flare-im/tokens/theme";
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
