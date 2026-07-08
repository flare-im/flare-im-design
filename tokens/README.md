# flare-im-design-tokens

L3 design tokens for the [Flare IM UI Kit](https://github.com/) — one neutral source of visual truth
(`tokens.json`), generated into per-platform outputs. Web ships here (CSS variables + a typed token object);
Dart / Swift / Compose outputs are added alongside their component packages.

## Install
```bash
npm i flare-im-design-tokens
```

## Use (web)
```css
/* CSS custom properties: --flare-color-*, --flare-size-*, --flare-shadow-*, --flare-transition-* */
@import "flare-im-design-tokens/tokens.css";
/* light in :root, dark under [data-flare-theme="dark"] */
```
```ts
import { flareDesignTokens } from "flare-im-design-tokens";
flareDesignTokens.colors.primary; // "#7C3AED"
```

## Regenerate
```bash
node build.mjs   # tokens.json → dist/tokens.{css,js,ts,d.ts}
```
`tokens.json` is the only edit surface; `dist/*` is generated.
