# flare-im-design-site

The **Flare IM Design** documentation site (Ant-Design-style), built with VitePress.

- Home / hero, **design tokens** (live swatches from the generated CSS vars), **guide**
  (getting started, spec), and a page per **component** (18) with a live preview, API
  table, four-platform code tabs, and per-platform package/symbol.
- The component pages, sidebar, and nav are **generated from the single source**
  `../spec/components.json` — run the generator after editing the spec.

## Develop

```bash
npm install
node scripts/gen-components.mjs   # (re)generate site/components/*.md from the spec
npm run dev                       # http://localhost:5173
npm run build                     # → .vitepress/dist  (static site)
npm run preview
```

## How it fits together

- **Tokens** — `.vitepress/theme/index.ts` imports the generated
  `../../tokens/dist/tokens.css`, so every swatch and demo uses the real design vars.
  A `MutationObserver` mirrors VitePress light/dark onto `data-flare-theme` so demos
  theme correctly.
- **Live demos** — token-styled Vue components in `.vitepress/theme/demos/` faithfully
  reproduce each component using the same tokens (no heavy SDK deps), registered
  globally and referenced by the generated pages.
- **API tables & code tabs** — emitted by `scripts/gen-components.mjs` straight from the
  spec (props/states/events, platform symbols, usage `code-group`).

## Deploy

`npm run build` produces a static site in `.vitepress/dist` — host it anywhere
(GitHub Pages, Netlify, S3, …). Set `base` in `.vitepress/config.mts` if serving under
a sub-path.
