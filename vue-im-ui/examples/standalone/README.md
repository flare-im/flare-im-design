# Flare IM UI — standalone example

The kit used **on its own** — a plain in-memory "backend", **no Flare core, no SDK**.
It proves the components are pure presentation: data goes in via props, interactions
come back as events, so any data source works.

```bash
npm install
npm run dev      # http://localhost:5181
```

## What it shows

- `src/backend.ts` — your "backend": a plain reactive store (`conversations`,
  `threads`, `send()`). Swap it for your own API/WebSocket.
- `src/App.vue` — the UI: `FlareConversationList` + message bodies + a composer,
  wired with **props in / events out** (`@select`, `@send`). That's the whole
  integration surface.

## Using it in a real project

```bash
npm i @flare-im/vue-ui naive-ui vue
```

```ts
import "@flare-im/vue-ui/style.css";
import { FlareConversationList, FlareTextMessage } from "@flare-im/vue-ui/components";
import { useFlareI18nProvider } from "@flare-im/vue-ui/i18n"; // call once at the root
```

(Here we alias the imports to the workspace source in `vite.config.ts` so the
example runs without publishing — a real app just imports the package.)

To re-skin, override a few `--flare-color-*` variables — see the Theming guide.
