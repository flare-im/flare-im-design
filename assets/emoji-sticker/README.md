# Emoji & Sticker resources (cross-platform source of truth)

This directory is the **single, platform-neutral source** for flare-im-design's
emoji packs (表情包) and sticker packs (贴纸). Every platform kit — Vue
(`flare-core-vue-im-ui`), Flutter (`flare_im_ui`), Android (`im-ui-compose`), iOS
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

## Regenerating the manifest

After adding/removing emoji or sticker files, run:

```
node assets/emoji-sticker/build-manifest.mjs
```

It rederives `manifest.json` from `emoji-locales.json` (emoji keys) and the sticker
directories. Do not hand-edit `manifest.json`.
