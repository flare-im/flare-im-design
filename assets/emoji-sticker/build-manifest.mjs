#!/usr/bin/env node
/**
 * Regenerates `manifest.json` — the single cross-platform source of truth for
 * emoji packs + sticker packs. Every platform (Vue / Flutter / Android / iOS)
 * reads this one file to know which keys/packs exist and how to resolve assets.
 *
 * Run: `node assets/emoji-sticker/build-manifest.mjs` from the flare-im-design root
 * (or anywhere — paths are resolved relative to this file).
 *
 * Contract:
 *  - Emoji: pack key == webp filename stem == protocol field == the `[key]` text token.
 *    Display names live in `emoji-locales.json` (per-locale key→label maps).
 *  - Sticker: identity == packageId + stickerId. Disk dir `default/` maps to the
 *    protocol packageId `gifs`; other dir names are their own packageId 1:1.
 */
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(fileURLToPath(import.meta.url));
const ASSET_BASE_PATH = "/flare-im-ui-assets";

// packageId aliasing: on-disk directory name -> protocol packageId.
const DIR_TO_PACKAGE_ID = { default: "gifs" };
const PACK_TITLES = { classic: "Classic", default: "Default" };

function listWebp(dir) {
  return readdirSync(dir)
    .filter((f) => f.toLowerCase().endsWith(".webp"))
    .sort((a, b) => a.localeCompare(b, "en", { numeric: true }));
}

function stem(file) {
  return file.replace(/\.webp$/i, "");
}

// --- emoji ---
const locales = JSON.parse(readFileSync(join(ROOT, "emoji-locales.json"), "utf8"));
const emojiKeys = Object.keys(locales.en ?? {}).sort((a, b) =>
  a.localeCompare(b, "en", { numeric: true }),
);

// --- sticker packs ---
const stickersRoot = join(ROOT, "stickers");
const packDirs = readdirSync(stickersRoot, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)
  .sort();

const stickerPacks = packDirs.map((dir) => {
  const packageId = DIR_TO_PACKAGE_ID[dir] ?? dir;
  const files = listWebp(join(stickersRoot, dir));
  // Optional per-pack manifest carrying server media handles.
  let mediaByFile = {};
  try {
    const raw = JSON.parse(readFileSync(join(stickersRoot, dir, "manifest.json"), "utf8"));
    const entries = Array.isArray(raw) ? raw : raw.items ?? [];
    for (const e of entries) {
      if (e && e.filename) mediaByFile[e.filename] = e.media_path ?? e.mediaPath ?? "";
    }
  } catch {
    /* no per-pack manifest — resolve by path convention */
  }
  return {
    id: packageId,
    dir: `stickers/${dir}`,
    title: PACK_TITLES[dir] ?? packageId,
    format: "webp",
    items: files.map((file) => {
      const item = { id: stem(file), file };
      if (mediaByFile[file]) item.mediaPath = mediaByFile[file];
      return item;
    }),
  };
});

const manifest = {
  version: 1,
  description:
    "Canonical cross-platform emoji-pack + sticker manifest for flare-im-design. Consumed by Vue/Flutter/Android/iOS kits.",
  assetBasePath: ASSET_BASE_PATH,
  emoji: {
    format: "webp",
    dir: "emoji",
    localesFile: "emoji-locales.json",
    count: emojiKeys.length,
    keys: emojiKeys,
  },
  stickerPacks,
};

writeFileSync(join(ROOT, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
const totalStickers = stickerPacks.reduce((n, p) => n + p.items.length, 0);
console.log(
  `manifest.json written: ${emojiKeys.length} emoji, ${stickerPacks.length} sticker packs (${totalStickers} stickers).`,
);
