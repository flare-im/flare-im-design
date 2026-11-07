import { bundledComposerEmojiKeys, registerComposerEmojiAssets } from "../../components/composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { bundledComposerStickerPackIds, registerComposerStickerPacks } from "../../components/composer/ComposerEmojiStickerPopover/composerStickers";
import { flareResourceColorKeys, setFlareResourceColors } from "../../design-system/theme/resource-colors";
import {
  flareResourceColorsFor,
  flareResourceContents,
  flareResourceEmoji,
  flareResourceStringsFor,
  type FlareResourcePack,
} from "../../utils/resourceOverlay";
import {
  FLARE_DEFAULT_LOCALE,
  flareMessages,
  isFlarePluralMessage,
  listFlareLocales,
  registerFlareMessages,
  type FlareLocale,
  type FlareMessageTree,
} from "./messages";

/** How much of the packs took effect, for the host's log. */
export interface FlareResourceOverlayResult {
  /** Entries replaced, counted once per language. */
  strings: number;
  /** Colours set, counted once per mode. */
  colors: number;
  emoji: number;
  stickerPacks: number;
  /** Packs that were broken or of a kind no kit reads. */
  ignoredPacks: number;
}

/** A set of plural forms is one message with no plain text to replace, so it is left out, here and under a fallback. */
function collectStrings(tree: FlareMessageTree, prefix: string, out: Map<string, string>): void {
  for (const [key, value] of Object.entries(tree)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (typeof value === "string") out.set(path, value);
    else if (isFlarePluralMessage(value)) out.delete(path);
    else collectStrings(value, path, out);
  }
}

/** The plain text a lookup in `locale` lands on: its own, then the default language's. */
function builtInStrings(locale: FlareLocale): Map<string, string> {
  const strings = new Map<string, string>();
  collectStrings(flareMessages[FLARE_DEFAULT_LOCALE], "", strings);
  if (locale !== FLARE_DEFAULT_LOCALE) collectStrings(flareMessages[locale], "", strings);
  return strings;
}

function messageTree(entries: Record<string, string>): FlareMessageTree {
  const tree: FlareMessageTree = {};
  for (const [key, value] of Object.entries(entries)) {
    const parts = key.split(".");
    const leaf = parts.pop() as string;
    let cursor = tree;
    for (const part of parts) cursor = (cursor[part] ??= {}) as FlareMessageTree;
    cursor[leaf] = value;
  }
  return tree;
}

/**
 * Folds the packs `update.get_resources` returned into the kit: copy into every registered language, colours into the
 * custom properties and the Naive theme, emoji into the runtime catalog. What is on screen follows without a remount.
 * An entry or a pack the rules refuse (`spec/resource-overlay-vectors.json`) is left out and the rest stands, so this
 * never throws. Help packs stay with the host.
 */
export function applyFlareResourceOverlay(packs: readonly FlareResourcePack[]): FlareResourceOverlayResult {
  const contents = flareResourceContents(packs);

  let strings = 0;
  for (const locale of listFlareLocales()) {
    const builtIn = builtInStrings(locale);
    const accepted = flareResourceStringsFor(contents.stringPacks, locale, (key) => builtIn.get(key));
    const count = Object.keys(accepted).length;
    if (count) registerFlareMessages(locale, messageTree(accepted));
    strings += count;
  }

  const known = flareResourceColorKeys();
  const light = flareResourceColorsFor(contents.tokenPacks, "colors", known);
  const dark = flareResourceColorsFor(contents.tokenPacks, "dark", known);
  setFlareResourceColors({ light, dark });

  const { emoji, stickerPacks } = flareResourceEmoji(
    bundledComposerEmojiKeys(),
    bundledComposerStickerPackIds(),
    contents.emojiPacks,
  );
  if (emoji.length) registerComposerEmojiAssets(emoji);
  if (stickerPacks.length) {
    registerComposerStickerPacks(stickerPacks.map(({ id, ...pack }) => ({ ...pack, packageId: id })));
  }

  return {
    strings,
    colors: Object.keys(light).length + Object.keys(dark).length,
    emoji: emoji.length,
    stickerPacks: stickerPacks.length,
    ignoredPacks: contents.ignored,
  };
}
