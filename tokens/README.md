# @flare-im/tokens

> **注意：包名已变更**：`flare-im-design-tokens` → `@flare-im/tokens`
>
> 旧包名最后发布到 **1.0.4**，之后不再更新。请改用：
>
> ```bash
> npm uninstall flare-im-design-tokens
> npm install @flare-im/tokens
> ```
>
> 导入路径与 API 完全不变，只需替换包名。改名是为了把 Flare IM 的 npm 包统一到
> `@flare-im/` scope 下，避免无 scope 名字被抢注、也让同项目的包一眼可辨。

L3 design tokens for the [Flare IM UI Kit](https://github.com/flare-im/flare-im-design) — one neutral source of visual truth
(`tokens.json`), generated into per-platform outputs. Web ships here (CSS variables + a typed token object);
Dart / Swift / Compose outputs are added alongside their component packages.

## Install
```bash
npm i @flare-im/tokens
```

## Use (web)
```css
/* CSS custom properties: --flare-color-*, --flare-size-*, --flare-shadow-*, --flare-transition-* */
@import "@flare-im/tokens/tokens.css";
/* light in :root, dark under [data-flare-theme="dark"] */
```
```ts
import { flareDesignTokens } from "@flare-im/tokens";
flareDesignTokens.colors.primary; // "#7C3AED"
```

## Regenerate
```bash
node build.mjs   # tokens.json → dist/tokens.{css,js,ts,d.ts}
```
`tokens.json` is the only edit surface; `dist/*` is generated.
