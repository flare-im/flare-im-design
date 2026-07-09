# Theming

Themes are **customizable, composable, and ready to use**. Every component's look comes from one set of CSS variables (`--flare-color-*`); override a few, or **derive a whole theme** from a single primary color — the components follow immediately.

## Try it live

Pick a primary color or a preset and the components below re-theme in real time (each theme is derived by `deriveFlareTheme` from one primary — hover/active/bubble/link/selected are all computed):

<ThemePlayground />

## Drop-in (plain CSS · any project)

The most universal path: import the stylesheet once, then override a few variables with plain CSS — **no JS, no SDK, framework-agnostic**.

```ts
// 1) Import the base stylesheet once, at your app entry
import "flare-core-vue-im-ui/style.css";
```

```css
/* 2) Override the authoritative variables to re-skin everything —
      every color in every component ultimately resolves to these --flare-color-* */
:root {
  --flare-color-primary: #0d9488;      /* brand: unread badge / send button / selection / accents */
  --flare-color-bubble-self: #0d9488;  /* own message bubble */
  --flare-color-text-link: #0d9488;    /* links */
  --flare-color-bg-selected: #d5f5f0;  /* selected row background */
}

/* Want to re-skin only part of the UI? Scope it to a container — themes can coexist */
.brand-b {
  --flare-color-primary: #e11d48;
  --flare-color-bubble-self: #e11d48;
}
```

Want to **derive the whole ramp** (hover / active / bubble / link / selected) from one primary? Use `deriveFlareTheme` below.

### Authoritative override variables

| Variable | Controls |
|---|---|
| `--flare-color-primary` · `-hover` · `-active` | Brand color + its hover / pressed states |
| `--flare-color-bubble-self` | Own message bubble fill |
| `--flare-color-text-link` · `-link-hover` | Link color |
| `--flare-color-bg-primary` · `-secondary` · `-tertiary` | Background layers |
| `--flare-color-bg-selected` · `-hover` | Selected / hover background |
| `--flare-color-text-primary` · `-secondary` · `-tertiary` | Text layers |
| `--flare-color-border-primary` · `-secondary` | Borders |
| `--flare-color-success` · `error` · `warning` | Semantic colors (usually kept when rebranding) |

Full list on the [Design Tokens](/en/guide/tokens) page.

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
