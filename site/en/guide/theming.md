# Theming

Themes are **customizable, composable, and ready to use**. Every component's look comes from one set of CSS variables (`--flare-color-*`); override a few, or **derive a whole theme** from a single primary color — the components follow immediately.

## Try it live

Pick a primary color or a preset and the components below re-theme in real time (each theme is derived by `deriveFlareTheme` from one primary — hover/active/bubble/link/selected are all computed):

<ThemePlayground />

## Usage

`flare-im-design-tokens/theme` exposes a framework-agnostic runtime API:

```ts
import {
  applyFlareTheme,
  deriveFlareTheme,
  flarePresets,
} from "flare-im-design-tokens/theme";

// 1) Derive a whole theme from one primary, applied to the whole page
applyFlareTheme(deriveFlareTheme({ primary: "#2563EB" }));

// 2) Use a built-in preset (violet / ocean / forest / sunset / rose / graphite)
applyFlareTheme(flarePresets.forest);

// 3) Override only the few you want (key = suffix after --flare-color-)
applyFlareTheme({ "bubble-self": "#111827", "primary": "#111827" });

// 4) Scope to a subtree (multiple themes coexist)
applyFlareTheme(flarePresets.rose, document.querySelector("#panel-a"));
```

You can also override just the semantic colors:

```ts
applyFlareTheme(deriveFlareTheme({
  primary: "#7C3AED",
  success: "#10B981",
  error: "#F43F5E",
}));
```

## Vue: theme provider

In Vue, `FlareThemeProvider` scopes a theme to a subtree (nestable, local):

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

## Per platform

- **Web / Vue**: override CSS variables (the API above), or scope with `FlareThemeProvider`.
- **Flutter**: `FlareColors` is an immutable value object — pass your own instance (or `copyWith` a few fields) down via `InheritedWidget`/Provider.
- **iOS**: put a customized `FlareColors` into `@Environment`, or pass it into the component directly.
- **Android**: `FlareColors` is a data class — `FlareColors.Light.copy(primary = …)` and dispatch it through a `CompositionLocal`.

> Underneath is **the same tokens.json single source**: the dark theme is built in (`[data-flare-theme="dark"]`), and a runtime override just layers your brand color on top.
