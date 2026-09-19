# 主题

Flare IM 的主题链路只有一个方向：

```text
Theme Palette
  ↓
Semantic Tokens
  ↓
Component Tokens
  ↓
Components
```

组件只消费语义 token 或组件 token。不要在消息气泡、已读回执、会话选中态或发送按钮中直接使用 Violet、Purple 或原始色板值。

## 在线演示

<ThemePlayground />

## 内置主题

内置 `violet`、`ocean`、`forest`、`sunset`、`rose`、`graphite`，每个主题都同时定义 Light 与 Dark。切换主题会同时改变：

- primary action 与 focus ring
- 会话 hover / selected
- outgoing / selected / failed message
- sent / delivered / read / failed status
- reply 与 reaction selected
- Composer 边框、focus 与发送按钮

Incoming message 保持中性是有意设计，不表示主题失效。

## Web 运行时

```ts
import {
  applyFlareTheme,
  flareBuiltInThemes,
  flareThemeNames,
  type FlareThemeMode,
  type FlareThemeName,
} from "@flare-im/tokens/theme";

const brand: FlareThemeName = "forest";
const mode: FlareThemeMode = "dark";

applyFlareTheme(brand, mode);
console.log(flareThemeNames, flareBuiltInThemes[brand]);
```

`applyFlareTheme(theme, mode, element?)` 默认作用于 `document.documentElement`，传入容器可限定局部主题。

Vue 子树使用 provider：

```vue
<script setup lang="ts">
import { FlareUiProvider, FlareConversationList, FlareMessageList } from "@flare-im/vue-ui/components";
</script>

<template>
  <FlareUiProvider brand-theme="ocean" theme-mode="dark">
    <FlareConversationList :items="items" />
    <FlareMessageList v-bind="thread" />
  </FlareUiProvider>
</template>
```

## 自定义主题

Web 的 `CustomTheme` 必须同时提供 Light / Dark，并至少覆盖 primary、surface、text、border、focus、message outgoing、message read 与 danger。从最接近的内置主题开始，再覆盖语义字段：

```ts
import { createFlareCustomTheme, flareBuiltInThemes } from "@flare-im/tokens/theme";

const mode = (source: typeof flareBuiltInThemes.ocean.light, outgoing: string, read: string) => ({
  colors: {
    ...source.colors,
    primary: outgoing,
    focusRing: `${outgoing}57`,
    message: {
      ...source.colors.message,
      outgoing: {
        ...source.colors.message.outgoing,
        background: outgoing,
      },
      status: {
        ...source.colors.message.status,
        read,
      },
    },
  },
});

export const acmeTheme = createFlareCustomTheme({
  name: "acme",
  light: mode(flareBuiltInThemes.ocean.light, "#0057b8", "#0057b8"),
  dark: mode(flareBuiltInThemes.ocean.dark, "#0b6fd3", "#69aef5"),
});
```

## 原生端

Flutter 从内置语义映射复制，再通过 `FlareTheme` 注入：

```dart
final colors = FlareColors.oceanLight.copyWith(
  primary: const Color(0xFF0057B8),
  messageOutgoingBackground: const Color(0xFF0057B8),
);
FlareTheme(colors: colors, child: const ChatScreen());
```

Compose 使用 data class 的 `copy` 与 provider：

```kotlin
val colors = FlareColors.OceanLight.copy(
    primary = Color(0xFF0057B8),
    messageOutgoingBackground = Color(0xFF0057B8),
)
FlareThemeProvider(dark = false, colors = colors) { ChatScreen() }
```

Provider 同时提供 Flare 语义色与 MaterialTheme 的颜色、字体映射。页面组合使用
`MaterialTheme.typography`，无需在应用中复制字体阶梯或再嵌套一套 Material 主题。
自定义色板时传入对应的 `dark` 值；传入完整的 light/dark 语义色板，不只替换品牌色。

SwiftUI 为自定义 Light / Dark 配对创建主题：

```swift
let light = FlareColors.oceanLight.copy(
    primary: Color(red: 0, green: 0.34, blue: 0.72),
    messageOutgoingBackground: Color(red: 0, green: 0.34, blue: 0.72)
)
let acme = FlareBrandTheme(name: "acme", light: light, dark: .oceanDark)

ChatScreen().flareTheme(acme)
```

## 编辑规则

只编辑 `tokens/tokens.json` 与 `tokens/themes.json`。`tokens/dist/`、`FlareTokens.swift`、`FlareTokens.kt` 与 `flare_tokens.dart` 都是生成文件，运行 `npm run generate` 刷新，不要手工修改。
