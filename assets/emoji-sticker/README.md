# Emoji & Sticker resources (cross-platform source of truth)

This directory is the **single, platform-neutral source** for flare-im-design's
emoji packs (表情包) and sticker packs (贴纸). Every platform kit — Vue
(`@flare-im/vue-ui`), Flutter (`flare_im_ui`), Android (`im-ui-compose`), iOS
(`FlareIMUI`) — and every example app reads from here instead of carrying its own
copy.

## Layout

```
assets/emoji-sticker/
  emoji/<key>.webp            # 157 animated emoji; filename stem == pack key
  stickers/<dir>/<id>.webp    # sticker packs, one dir per pack
  stickers/<dir>/manifest.json # optional: per-pack server media handles
  emoji-locales.json          # per-locale key -> display name maps
  manifest.json               # canonical unified manifest (GENERATED)
  build-manifest.mjs          # regenerates manifest.json from the files above
```

## Contract (identical on every platform)

- **Emoji**: the pack **key** is the webp filename stem (`snake_case`), and is
  simultaneously the protocol field, the display-name key in `emoji-locales.json`,
  and the inline text token `[key]`. Asset URL: `/flare-im-ui-assets/emoji/<key>.webp`.
- **Sticker**: identity is `packageId` + `stickerId` (stickerId = filename stem).
  On-disk dir `default/` maps to the protocol `packageId = "gifs"`; every other dir
  name is its own `packageId` 1:1. Asset URL:
  `/flare-im-ui-assets/stickers/<dir>/<stickerId>.webp`.

`/flare-im-ui-assets` is the runtime base path each platform serves this directory
under (Vue: the SDK devtools vite plugin; natives: bundle these files).

### Playback policy

The playback rule is part of the shared UI contract, not an app-level option:

- Composer/editor content, inline `[key]` tokens, emoji/sticker pickers, previews,
  and sticker cards render a **static first frame**.
- A sent message animates only when its complete trimmed body is one known
  `[key]` token, or when the protocol explicitly identifies standalone emoji
  content.
- Mixed text such as `hello [key]` stays static. Unknown keys stay visible as
  their original bracket text.
- Static surfaces must never fall back to an animated source after a decode or
  network failure. They show their normal fallback/empty state instead.

### Per-user runtime extensions

All four kits expose a process-local runtime catalog so applications can install
emoji and sticker packs after login without rebuilding the SDK:

- Vue/Tauri: `registerComposerEmojiAssets` and
  `registerComposerStickerPacks` from `@flare-im/vue-ui`.
- Flutter: `FlareEmojiStickerCatalog.instance.registerEmojiAssets` and
  `registerStickerPacks`.
- Android: `FlareEmojiStickerCatalog.registerEmojiAssets` and
  `registerStickerPacks`.
- iOS: `FlareEmojiStickerCatalog.shared.registerEmojiAssets` and
  `registerStickerPacks`.

Registration replaces a bundled or previously registered entry with the same
stable identity. Emoji retain their `[key]` protocol token; stickers retain
`packageId` + `stickerId`. Catalog-backed pickers and message views update when
registrations change.

Each runtime entry supplies the original URL/provider used by a standalone sent
emoji and a static preview (or a source from which the kit can safely decode only
frame zero). Android registrations require `staticPreviewBytes`; the other kits
accept an explicit preview and otherwise freeze the first frame defensively.
Byte-oriented loaders bound encoded previews to 8 MiB, and all renderers bound
or resize decoded output. Hosts must also validate provider-backed source size,
MIME type, ownership and authorization before registration.

Runtime entries are scoped to the current signed-in user. On logout/account
switch, call the matching `clear…Registrations` / `clearRegistered…` APIs before
loading the next user's catalog. Do not persist resolved local paths or object
URLs in messages; persist only the stable protocol identities.

## Regenerating the manifest

After adding/removing emoji or sticker files, run:

```
node assets/emoji-sticker/build-manifest.mjs
```

It rederives `manifest.json` from `emoji-locales.json` (emoji keys) and the sticker
directories. Do not hand-edit `manifest.json`.
