# Theming

Flare IM has one theme flow:

```text
Theme Palette
  ↓
Semantic Tokens
  ↓
Component Tokens
  ↓
Components
```

Components consume semantic or component tokens only. Message bubbles, read receipts, conversation selection, and send actions must never reference Violet, Purple, or a raw palette value directly.

## Live demo

<ThemePlayground />

## Built-in themes

The built-ins are `violet`, `ocean`, `forest`, `sunset`, `rose`, and `graphite`, each with Light and Dark definitions. Changing the theme updates:

- primary actions and focus rings
- conversation hover and selection
- outgoing, selected, and failed messages
- sent, delivered, read, and failed status
- reply and selected reaction surfaces
- Composer border, focus, and send action

Incoming messages intentionally remain neutral; that is not a theme propagation failure.

## Web runtime

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

`applyFlareTheme(theme, mode, element?)` targets `document.documentElement` by default. Pass a container to scope the theme to a subtree.

Use the Vue provider for a local subtree:

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

## Custom themes

A web `CustomTheme` supplies both Light and Dark definitions and must cover primary, surface, text, border, focus, message outgoing, message read, and danger semantics. Start from the closest built-in theme, then override semantic fields:

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

## Native platforms

Flutter copies a built-in semantic map and injects it with `FlareTheme`:

```dart
final colors = FlareColors.oceanLight.copyWith(
  primary: const Color(0xFF0057B8),
  messageOutgoingBackground: const Color(0xFF0057B8),
);
FlareTheme(colors: colors, child: const ChatScreen());
```

Compose uses the data class `copy` and provider:

```kotlin
val colors = FlareColors.OceanLight.copy(
    primary = Color(0xFF0057B8),
    messageOutgoingBackground = Color(0xFF0057B8),
)
FlareThemeProvider(dark = false, colors = colors) { ChatScreen() }
```

The provider supplies Flare semantic colors and the corresponding MaterialTheme
colors and typography. Use `MaterialTheme.typography` in page composition instead
of copying a type scale or nesting a second Material theme in the app. Pass the
matching `dark` value with custom colors and supply a complete light/dark palette.

SwiftUI creates a custom Light/Dark theme pair:

```swift
let light = FlareColors.oceanLight.copy(
    primary: Color(red: 0, green: 0.34, blue: 0.72),
    messageOutgoingBackground: Color(red: 0, green: 0.34, blue: 0.72)
)
let acme = FlareBrandTheme(name: "acme", light: light, dark: .oceanDark)

ChatScreen().flareTheme(acme)
```

## Editing rules

Edit only `tokens/tokens.json` and `tokens/themes.json`. `tokens/dist/`, `FlareTokens.swift`, `FlareTokens.kt`, and `flare_tokens.dart` are generated. Refresh them with `npm run generate`; do not edit them by hand.
