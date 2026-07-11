# Showcase demos → real kit components (kill the mockup drift)

## Goal
Every `site/.vitepress/theme/demos/*.vue` (42 files) renders the REAL `flare-core-vue-im-ui`
components instead of a hand-coded HTML/CSS mockup, so the docs can never drift from the shipped
components again. Done = `vitepress build` passes and demos show the actual components.

## Root cause (why we're here)
All 42 demos are mockups; 0 import the kit. The tauri app uses the real components, so docs and app
diverged (e.g. MessageBubble: mockup radius 16/4 flat-self vs real 14/10 gradient-self).

## Constraints / gotchas
- The kit is a **source package** (ships `.vue`, `main: src/index.ts`) → VitePress SSR must transform it:
  `vite.ssr.noExternal` must include `flare-core-vue-im-ui` (+ `naive-ui`), and `vite.resolve.alias`
  must point the bare specifier at the source, with `dedupe: [vue, naive-ui, vue-router]` and
  `server.fs.allow` covering the design root.
- Kit components call `useFlareI18n()` which **throws without a provider** → demos must have
  `FlareUiProvider` as an ancestor (mount once in a theme `Layout.vue` wrapper).
- SSR: `FlareUiProvider`/naive-ui may touch `window`/`document`. Guard with `<ClientOnly>` around demos
  (or make the demo root client-only) if the build errors on SSR.
- Kit needs its token CSS: import `flare-core-vue-im-ui/style.css` in the theme.
- The mockups use `--flare-color-*`; real components use `--im-*` — the tokens css must define both
  (tokens/dist already provides `--flare-color-*`; the kit's style.css provides `--im-*`).

## Status: DONE ✅
Every demo now renders the REAL `flare-core-vue-im-ui` components (`vitepress build` clean; home hero
DOM-verified: 3 real `.message-bubble`, 0 mockup `.bubble`). The mockup message-body copies under
`demos/messages/` were deleted; message demos + `MessageContentViewDemo` repoint to the kit's
`standalone/` components. The ONLY non-kit file is `ThemePlayground.vue` — a design-token editor TOOL
(sliders → `applyFlareTheme`), which has no single component to showcase, so it's intentionally exempt.
`HomeShowcase` (landing hero) was converted too (chat canvas → real `FlareMessageBubble`, theme chips kept).

## Proven pattern (Phase 0+1 DONE, `vitepress build` clean)
- **Wiring**: site/package.json has `flare-core-vue-im-ui` + `flare-im-design-tokens` + `naive-ui` +
  `vue-router` + `@vicons/ionicons5` + `markdown-it` (file:/deps). config.mts `vite`: deep-import alias
  (`flare-core-vue-im-ui/(.+) → src/$1`, style.css special-cased), `dedupe`, `server.fs.allow`, and
  `ssr.noExternal` = the kit + the **naive-ui SSR set** (`naive-ui,vueuc,css-render,@css-render/vue3-ssr,
  date-fns,@juggle/resize-observer,seemly,treemate,vooks,evtd`). theme/index.ts imports the kit `style.css`.
- **`DemoStage.vue`** (`demos/DemoStage.vue`) = `<ClientOnly><FlareUiProvider><slot/></FlareUiProvider>`.
  Every demo wraps its real components in `<DemoStage>`: ClientOnly avoids the kit's SSR `document`
  access (naive-ui), FlareUiProvider supplies i18n/theme/media/adaptive so components don't throw.
- **Convert recipe per demo**: import the real `Flare*` via deep path
  (`flare-core-vue-im-ui/components/.../X.vue`, NOT the barrel — barrel drags the optional SDK) + import
  `DemoStage`; replace the mockup markup with `<DemoStage><real component :props="mock"/></DemoStage>`;
  build mock data matching the component's props (loose JS — demos have no `lang="ts"`).
- [x] **Phase 0 · wire** — DONE. [x] **Phase 1 · proof** — MessageBubbleDemo → real `FlareMessageBubble`
  (mock thread), `vitepress build` clean. (Old `Layout.vue` approach dropped — wrapping the whole layout
  broke doc SSR; per-demo DemoStage is the fix.)
- [~] **Phase 2 · batch** — 10/41 done, `vitepress build` clean, 2 visually confirmed.
  Batch 2 (build green): `SearchBarDemo`→`FlareSearchBar`, `VoiceHoldButtonDemo`→`FlareVoiceHoldButton`,
  `ComposerSendButtonDemo`→`FlareComposerSendButton`, `ContactItemDemo`→`FlareContactItem`.
  Batch 1:
  - `MessageBubbleDemo` → `FlareMessageBubble` (gradient self-bubble matches the app; visual ✓)
  - `AvatarDemo` → `FlareAvatar` · `MessageStatusDemo` → `FlareMessageStatus` ·
    `EmptyStateDemo` → `FlareEmptyState` · `TimeStampDemo` → `TimeStamp` ·
    `ConversationRowDemo` → `FlareConversationRow` (pastel avatar + purple unread badge; visual ✓)
  - **Remaining ~34** (same recipe): messages (TextMessage/Sticker/Location/Voice/File/Image/Video/
    LinkCard/RichText/MessageContentView/MessageMenu/...), conversation (ConversationList/Details/
    StartConversationDialog/PinnedMessageBar), composer (Composer/ComposerParts/EmojiSticker),
    general (SearchBar/Input), calls (CallControls/IncomingCall), shells. Build after each group; a few
    (full ChatWindow/Composer) may need richer mock data or `<ClientOnly>`-only interactivity.
- [ ] **Phase 3 · cleanup** — delete now-dead mockup CSS/`tint.js`/`DemoIcon` if unused; confirm the
  demos visually match the app.

## Notes
- Demo→component map is in each page's `::: code-group` (already lists FlareX per platform) and in
  `spec/components.json`.
- If a real component is too heavy/interactive for a static doc (e.g. full ChatWindow), a minimal real
  instance with mock data is still the goal — NOT a mockup.
