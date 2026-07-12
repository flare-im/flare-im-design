# Unify emoji-pack + sticker management in flare-im-design + audit 5 client-sdk apps

## Goal
Two deliverables:
1. **Audit** the 5 `flare-im-core-client-sdk/examples/flare-core-{web,tauri,flutter,electron,android}-app`
   for `flare-im-design` coverage; identify gaps; enrich the kit where it's missing/incomplete.
2. **Unify emoji-pack (表情包) + sticker (贴纸) support**: one authoritative resource set + manifest
   living in `flare-im-design`, consumed by all platforms (Vue/Flutter/iOS/Android/Electron) instead of
   each app carrying its own copy. Kit exposes the pickers + renderers; apps stop bespoke-ing them.

Done = each app documented (kit coverage + gaps), the clear gaps closed in the kit, and a single
`flare-im-design`-owned emoji/sticker resource+manifest that platforms reference (no per-app dupes).

## Constraints & decisions
- flare-im-spec: product-neutral behavior → kit; resources centralized; no compat dup paths.
- User's git flow: commit flare-im-design (git repo) then `git branch -f dev HEAD; git push -f origin main; git push -f origin dev`. NO Co-Authored-By trailer.
- Apps in `flare-im-core-client-sdk` are **NOT a git repo** → working-tree edits only, uncommittable.
- Respond 中文. rtk proxy for shell. JDK17 for Android.
- Verify: kit `vue-tsc` 0 + `vitepress build` ✓ for Vue; platform compile for native.

## Status: IN PROGRESS
Current focus: gathering the 5-app audit (agents running) + mapping current emoji/sticker state per platform.

## Current emoji/sticker state (discovered)
- **Vue kit** (`vue-im-ui/src/`): FULL system already — components (EmojiView/StickerView/FlareEmojiMessage/
  FlareStickerMessage/MessageEmojiPickerPanel/ComposerEmojiStickerPanel/ComposerEmojiStickerPopover/
  FrozenStickerThumb/PlainTextEmojiRich) + data model (composerEmojiAssets.ts/composerStickers.ts/
  emojiPackI18n.ts) + assets `src/assets/emoji` (157 webp, 22MB) + `src/assets/stickers/{classic,default}`
  (94 files, 45MB) + i18n `shared/assets/i18n/emoji-locales.json`.
  - Runtime asset base = `/flare-im-ui-assets` (apps must SERVE the kit assets under that public path).
  - Kit package.json `files` EXCLUDES *.webp/png/jpg/gif → the npm package does NOT ship binaries; they're
    dev/source-only and apps provide them at `/flare-im-ui-assets`. **No copy/sync script exists in the kit.**
- **Flutter app** (design source, does NOT consume kit): its OWN copy — `assets/emoji/` 157 webp + manifest.json,
  `assets/stickers/compressed/` 93 webp + manifest.json, `assets/emoji-locales.json`. Manifests note
  `source: examples/flare-core-tauri/dist/assets`. Kit `flutter-im-ui` ships ZERO emoji/sticker assets/widgets
  (only an `onEmoji` callback stub). → biggest promotion candidate.
- **Manifest formats seen**:
  - emoji: `{kind:"emoji", items:[{id,label,asset}]}`; protocol key = lowercase filename stem, text `[key]`.
  - stickers: `{kind:"sticker_packs", packs:[{id,title,items:[{id,asset}]}]}`; identity = packageId+stickerId;
    disk `default/` ↔ protocol `packageId=gifs`.
- **Origin of truth**: the Tauri app's `dist/assets` is where both the Flutter copy and (likely) others derived.

## Audit results (4/5 in; android pending)
| App | Kit coverage | Emoji/sticker source | Gaps |
|---|---|---|---|
| **web** (Vue) | ~95% kit (thin shell, no local components) | 100% kit `/flare-im-ui-assets/` | inline banners/tabs/empty-states in views; msg-search panel + settings/more drawers in WorkbenchLayout bespoke |
| **tauri** (Vue) | ~95% kit (0 local .vue) | 100% kit `/flare-im-ui-assets/` | none of substance (orchestration only) |
| **electron** (Vue) | ~95% kit | 100% kit `/flare-im-ui-assets/` | ChatView banners/tabs/empty-state; 2 hardcoded 贴纸/表情 labels in WorkbenchLayout |
| **flutter** | **0% (design source, declared-but-unused dep)** | **100% LOCAL** (own `assets/emoji` 157 + `assets/stickers/compressed` 93 + manifests, from tauri dist) | flutter-im-ui has NO emoji/sticker widgets/assets at all; whole 22-view content set richer than kit |
| **android** | ~25-30% chat UI (kit: EmptyState/ConversationRow + 11 content leaves; bespoke: bubble/scaffold/composer, kit equivalents exist unused) | **100% LOCAL** (`app/src/main/assets/emoji` 157 + `stickers/{classic 25,default 68}` + manifest) | kit `StickerMessage/EmojiMessage` are unicode-glyph stubs (no pack support); MiniProgram/Schedule/RichDoc kit gaps |

**Synthesis so far:** The **Vue** side is already fully unified — 3 Vue apps consume the kit's emoji/sticker
(assets in `vue-im-ui/src/assets`, served at `/flare-im-ui-assets/` by the SDK devtools vite plugin
`flareVueImUiAssets` rooted at `<kit>/vue-im-ui/src/assets`). The **dupe/gap is on natives**: Flutter carries
its OWN 250 webp copy (derived from tauri dist) and `flutter-im-ui` ships zero emoji/sticker widgets. So
"unify + centralize" = (a) one platform-neutral resource+manifest source in flare-im-design, (b) natives
consume it + gain kit emoji/sticker widgets, (c) drop per-app native dupes.

## Steps
- [x] Kit emoji/sticker state mapped (components + data model + assets + serving mechanism).
- [x] Flutter app audited — 0% kit consume (design source); emoji/sticker 100% local, no kit equivalent.
- [x] web/tauri/electron audited — Vue side fully unified on kit; only minor bespoke view chrome.
- [x] Android audited — ~25-30% kit; emoji/sticker 100% LOCAL (`app/src/main/assets`), kit has only glyph stubs.

## KEY FINDING — the duplication + native-gap map
**Same ~157 emoji + ~93 stickers exist as 3-4 duplicate copies** (Vue kit `vue-im-ui/src/assets`, Flutter
app `assets/`, Android app `app/src/main/assets`, +iOS likely). All derived from the tauri dist. **The data
model already AGREES across platforms** (emoji key=filename stem=`[key]`; sticker=packageId+stickerId,
`default/`↔`gifs`, `classic/manifest.json`) — so unification is a plumbing/promotion job, not a redesign.
**Native kit emoji/sticker widgets**: Vue=full; Flutter=none (stub); Android=glyph-only stub; iOS=unknown.

- [x] **DECISION (user)**: (1) new top-level `flare-im-design/assets/` as the single cross-platform source;
  (2) scope THIS pass = **foundation only** — central resources + canonical manifest + repoint Vue kit.
  Native widget promotion (Flutter/Android/iOS) = follow-up passes.

## Foundation plan (this pass) — DONE
- [x] Central layout created: `flare-im-design/assets/emoji-sticker/` = `emoji/` (157 webp),
  `stickers/{classic(25),default(68)}/`, `emoji-locales.json`, `manifest.json` (canonical, generated),
  `build-manifest.mjs` (regenerator), `README.md` (cross-platform contract).
- [x] Assets moved via `git mv` from `vue-im-ui/src/assets/{emoji,stickers}` +
  `shared/assets/i18n/emoji-locales.json`; empty `src/assets` + `src/shared/assets` removed.
- [x] Canonical `manifest.json` generated: 157 emoji keys + 2 sticker packs (classic:25, gifs:68 with
  `default/`→`gifs` alias). `build-manifest.mjs` rederives it from the files.
- [x] Vue kit 3 build-time imports repointed to central (`emojiPackI18n.ts`, `composerStickers.ts`,
  `composerEmojiAssets.ts`). Runtime `/flare-im-ui-assets` base unchanged.
- [x] Devtools vite serving root repointed (`flareCoreWebAppVite.js` `vueImUiAssetRoot` →
  `flare-im-design/assets/emoji-sticker`) — **NON-git (flare-im-core-client-sdk), working-tree only**.
- [x] Verified: kit `vue-tsc` 0 (JSON import from outside src OK, no rootDir issue); `vitepress build` ✓;
  `flare-core-web-app` `vite build` ✓ with **250 webp copied into dist/flare-im-ui-assets from central**;
  `flare-social-tauri-app` `vue-tsc` 0 + `vite build` ✓ (different config, imports resolve via fs.allow).
- [ ] Commit+push kit (flare-im-design). Note: the devtools-plugin edit is uncommittable (client-sdk not git);
  its behavior is inherited by all flare-core Vue apps automatically.

## Follow-up passes (native)
### Pass 2 — Flutter kit emoji/sticker — DONE
- [x] Investigated flutter-im-ui (empty assets, glyph stubs) + the app's Dart impl (resolver/i18n/views/segments).
- [x] Bundled central assets via **symlink** `flutter-im-ui/assets/emoji-sticker → ../../assets/emoji-sticker`
  (true single source, no dup) + pubspec `assets:` (manifest/locales/emoji/classic/default). CLEAN names.
- [x] Ported kit APIs → `lib/src/emoji_sticker/`: `FlareEmojiStickerCatalog` (manifest loader + resolver:
  emoji key→asset, sticker packageId+id→asset with default→gifs, hasEmojiKey, i18n labels),
  `FlareStaticAssetImage` (first-frame decode for pickers).
- [x] Ported kit widgets: `FlareEmojiPackMessage`, `FlareStickerPackMessage`, `FlarePlainTextEmojiRich`
  (inline `[key]`), `FlareEmojiStickerPicker` (tabs: emoji + sticker packs). Wired into
  `FlareMessageContentView` (emoji/sticker cases now use pack widgets); extended `FlareStickerContent`
  with optional packageId/stickerId/width/height (non-breaking); exported from barrel.
- [x] Verified: `flutter analyze` (lib + example) **No issues found**; `flutter build bundle` ✓ with **250
  webp bundled from the symlinked central source** into flutter_assets — single-source works end-to-end.
- Note: the design-source app still has its own copy; switching it to the kit widgets/central assets is
  optional app-side follow-up (app is non-git, and is the reference impl).

### Pass 3 — Android kit emoji/sticker — DONE
- [x] Symlink `android-im-ui/src/main/assets/emoji-sticker → ../../../../assets/emoji-sticker`; AGP bundles it.
- [x] `EmojiStickerCatalog.kt`: `FlareEmojiStickerCatalog` (reads manifest.json + emoji-locales.json from
  `assets` via org.json; emoji keys/packs, hasEmojiKey, i18n labels, `file:///android_asset/...` URIs,
  default→gifs) + `flareEmojiStickerImageLoader` (Coil + ImageDecoderDecoder for animated webp, API 28+).
- [x] `EmojiStickerViews.kt`: `FlareEmojiPackMessage`, `FlareStickerPackMessage` (Coil SubcomposeAsyncImage
  + fallbacks), `FlarePlainTextEmojiRich` (inline `[key]` via InlineTextContent), `FlareEmojiStickerPicker`
  (tabs + LazyVerticalGrid). Added `coil-gif:2.7.0` dep.
- [x] Wired `MessageContentView` emoji/sticker → pack widgets; extended `FlareStickerContent` with
  packageId/stickerId/width/height (defaults, non-breaking).
- [x] Verified: `compileReleaseKotlin` ✓, `assembleRelease` ✓ with **250 webp bundled in the AAR from the
  symlinked source**; `publishToMavenLocal` ✓ (JDK17). Only pre-existing deprecation warnings.

### Pass 4 — iOS kit emoji/sticker — DONE
- [x] Resources: SPM's `.copy` does NOT follow symlinks (verified: symlink → 0 webp bundled), so iOS keeps a
  **committed real mirror** `Sources/FlareIMUI/Resources/emoji-sticker` (250 webp) regenerated by
  `sync-resources.sh` (rsync from central). Package.swift target `resources: [.copy("Resources/emoji-sticker")]`.
- [x] `EmojiSticker/EmojiStickerCatalog.swift`: `FlareEmojiStickerCatalog` (lazy-sync load from `Bundle.module`,
  emoji keys/packs, hasEmojiKey, i18n, `Bundle.module.url(forResource:…subdirectory:)` resolver, default→gifs)
  + cross-platform `FlarePlatformImage` (UIImage/NSImage) + `Image(flarePlatformImage:)`. Static webp (iOS
  native webp decode; animation is a follow-up — no third-party dep).
- [x] `EmojiSticker/EmojiStickerViews.swift`: `FlareBundleImage`, `FlareEmojiPackMessage`,
  `FlareStickerPackMessage`, `FlarePlainTextEmojiRich` (inline `[key]` via Text concatenation), `FlareEmojiStickerPicker`.
- [x] Wired `MessageContentView` emoji/sticker → pack widgets (removed dead `mediaThumb`); extended
  `FlareStickerContent` with packageId/stickerId/width/height (non-breaking).
- [x] Verified: `swift build` ✓ (250 webp bundled), `swift test` 14/14, no warnings.

### Pass 5 — Docs site validation + showcase — DONE
- [x] Added a vite plugin to `site/.vitepress/config.mts` serving `/flare-im-ui-assets/` from the central
  `assets/emoji-sticker` (dev middleware + build writeBundle copy → 250 webp into dist).
- [x] Added `EmojiStickerPanelDemo.vue` (the real `FlareComposerEmojiStickerPanel`), registered + embedded
  in `components/sticker-message.md` (+ en).
- [x] Verified: `vitepress build` ✓ (250 webp in dist). Runtime (in-app browser): `/flare-im-ui-assets/
  emoji/red_heart.webp` → **200 image/webp, decodes 240×240**; the exact freeze pipeline (fetch→blob→
  createImageBitmap→canvas→PNG dataURL) succeeds; the panel renders 157 emoji buttons with localized titles
  (外星人 …) from the central manifest. Thumbnails don't paint ONLY because this pane's viewport is 0×0 so
  the IntersectionObserver lazy-load can't fire — a pane limitation, not a kit/unification issue.

### Pass 6 — Android APP adopts the kit + dedup (IN PROGRESS)
- [x] Rewired the app to the kit emoji/sticker widgets (NON-git app, working-tree only):
  - `EmojiMessageView.kt` → `FlareEmojiPackMessage(content.str("emoji","key"))`.
  - `StickerMessageView.kt` → `FlareStickerPackMessage(stickerId, packageId)`.
  - `TextMessageView.kt` lone-emoji → `FlareEmojiPackMessage`.
  - `ComposerView.kt` `EmojiStickerPanel` → kit `FlareEmojiStickerPicker` (upgrade: full 157 emoji + all packs
    vs the app's old 21-emoji/12-sticker subset). Dropped the app's `FlowGrid` helper.
- [x] Deleted the app's local dupe: `app/src/main/assets/{emoji,stickers}` (250 webp) — now provided by the
  kit AAR at `emoji-sticker/`.
- [x] **Verified end-to-end**: `:app:assembleDebug` BUILD SUCCESSFUL (JDK17). The APK merges **250
  emoji-sticker webp from the kit AAR** (central source) and has **0 old `assets/emoji/` or
  `assets/stickers/` paths** — the app's local dupe is fully eliminated. Chain proven: central source →
  kit → AAR → app APK. (App is non-git → uncommittable working-tree change; kit already committed.)

### Pass 7 — iOS animated webp — DONE
- [x] `flareDecodeAnimatedWebp(url:)` in the catalog decodes every webp frame + per-frame duration via
  ImageIO (`kCGImagePropertyWebPDictionary`/`…DelayTime`) — no third-party dep. `FlareAnimatedBundleImage`
  cycles frames at each frame's own duration (`.task` + `Task.sleep`, cancels on disappear).
- [x] `FlareEmojiPackMessage` + `FlareStickerPackMessage` use it (picker stays static-first-frame by design).
- [x] Verified: `swift build` clean; `swift test` **17/17** (+3: catalog-loads-from-central, gifs alias,
  bundled-webp-decodes-to-frames). iOS now animates → parity with Flutter/Android/Vue.

### Pass 8 — iOS APP dedup + kit hardening — DONE
- [x] iOS app (NON-git) `EmojiPresentation.emojiURL`/`stickerURL` repointed to `FlareEmojiStickerCatalog`
  (kit's bundled central source); deleted the app's local `Resources/FlareAssets/{emoji,stickers}` (250
  webp) + removed the `.copy` resource decl. **Non-downgrade**: the app keeps its richer animated
  `FlareAssetImageView` rendering (travel/rotation) + inline composer emoji — only the resource source moved.
- [x] **KIT hardened (committable)**: `emojiImageURL`/`stickerImageURL` now guard components against path
  traversal/injection (`^[A-Za-z0-9_-]+$`) → nil for `../001` etc.
- [x] Verified: `swift build` (app) clean; app `swift test` **43/43** incl. the repointed
  `testEmojiPresentationResolvesKitBundledAssets` (emojiURL resolves from the FlareIMUI bundle, `../001`→nil);
  kit `swift test` still 17/17.

### Remaining passes
- **ALL FOUR PLATFORM KITS support emoji/sticker from the central source (all animated); docs serve + showcase it; Android + iOS apps both consume the kit with their dupes removed.**

### Pass 9 — Vue view-chrome → reusable kit components (IN PROGRESS)
- [x] Added 2 reusable kit components (committable, close the audit's recurring Vue-chrome gaps):
  - `FlareStatusBanner` (general/) — tone (info/success/warning/danger/neutral) + optional pulsing dot +
    optional inline action. Replaces the 3 bespoke banner variants (runtime/connection/message-sync).
  - `FlareFilterTabs` (general/) — scrollable tablist ({value,label,badge?}) + v-model active + `change`.
    Replaces the bespoke conversation-filter rows.
  - Both use kit design tokens (semantic colors via color-mix), a11y (role=tab/status, focus-visible,
    reduced-motion). Exported from the barrel. Kit `vue-tsc` 0 + `vitepress build` ✓.
- [x] Wired the **web app**: `ConversationsView` filter row → `FlareFilterTabs`, runtime banner →
  `FlareStatusBanner`; `ChatView` connection + message-sync banners → `FlareStatusBanner` (action slot for
  retry). Added a defensive `statusTone` mapper. **Verified**: web app `vue-tsc` 0 + `vite build` ✓.
- [x] Wired the **electron app** (same banners/filter, mirrors web). `vue-tsc` 0. (`vite build` fails on a
  PRE-EXISTING, unrelated `wa-sqlite` resolution issue in the storage worker — not my change.)
- [x] **Docs**: added `StatusBanner` + `FilterTabs` to `spec/components.json` (Vue-only), demos +
  registration, and **hardened `gen-components.mjs`** to support components without native platforms
  (was crashing on `platforms.flutter.symbol`). Generated zh+en pages; restored the Pass-5
  `EmojiStickerPanelDemo` section on sticker-message (gen overwrites it — it's a manual post-gen add).
  `vitepress build` ✓.
- [ ] Optional (deferred — larger, app-specific): in-conversation search panel, settings/more drawers.
- [ ] Optional: iOS animated-webp (needs a decoder lib or manual frame animation).
- [ ] Android kit (`im-ui-compose`): real pack-based emoji/sticker (replace glyph stubs); bundle central.
- [ ] iOS kit (`FlareIMUI`): emoji/sticker components + bundle central.
- [ ] Each native app: consume the kit widgets + central assets; delete per-app dupes.
- [ ] Optional Vue view-chrome gaps (web/electron bespoke banners/tabs/search-panel/settings drawers).
- [ ] Synthesize: per-app coverage table + gap list + where each app's emoji/sticker assets live (dupe map).
- [ ] **Decide unified-resource architecture**: one `flare-im-design/<assets>` location + manifest schema all platforms read; how each platform consumes (Vue serve, Flutter pubspec assets, Android res/assets, iOS bundle, Electron). Record decision here before building.
- [ ] Centralize the authoritative emoji + sticker resource set + manifest in flare-im-design.
- [ ] Close clear kit gaps (esp. flutter-im-ui emoji/sticker widgets; other per-app gaps as found).
- [ ] Verify per platform; commit+push kit; document app-side wiring (uncommittable apps → note in each app's MIGRATION doc).

## Notes / open questions
- Does the user want a NEW top-level shared dir (e.g. `flare-im-design/assets/` like `tokens/`) or keep them in `vue-im-ui/src/assets` and have natives reference that? Lean: a shared top-level `assets/` (or `emoji-sticker-kit/`) package with the manifest, so it's platform-neutral — but confirm the serving story per platform first from the audits.
- iOS not in the user's 5-list this round (they listed web/tauri/flutter/electron/android). Still, unified resource should serve iOS too.
- Watch bundle size: 67MB of webp. Natives bundling all of it may be heavy — consider on-demand/remote for large sticker packs, bundle the emoji + one default sticker pack.
