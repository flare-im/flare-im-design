export type FlareComposerState =
  | "idle"
  | "typing"
  | "sending"
  | "failed"
  | "disabled"
  | "offline"
  | "permissionDenied"
  | "capabilityUnavailable"
  | "runtimeUnavailable";

/** A single canned reply. */
export interface FlareQuickPhrase {
  id: string;
  text: string;
}

/** A titled group of quick phrases (e.g. 常用 / 售后). */
export interface FlareQuickPhraseGroup {
  key: string;
  title: string;
  phrases: FlareQuickPhrase[];
}

/** A slash command surfaced by the composer's "/" menu. */
export interface FlareSlashCommand {
  /** The command token without the leading slash, e.g. "mute". */
  command: string;
  /** One-line description of what it does. */
  description?: string;
  /** Optional usage hint, e.g. "@user 10m". */
  hint?: string;
}

/** A named category of emoji in the full emoji picker. */
export interface FlareEmojiCategory {
  key: string;
  label: string;
  /** Emoji shown as the category tab glyph (falls back to the first emoji). */
  symbol?: string;
  emojis: string[];
}

/** One sticker in a pack. */
export interface FlareStickerItem {
  id: string;
  url?: string;
  /** Placeholder glyph when no image is resolved yet. */
  placeholder?: string;
}

/** A sticker pack shown in the sticker panel. */
export interface FlareStickerPack {
  key: string;
  label: string;
  /** Pack-rail cover image. */
  coverUrl?: string;
  /** Pack-rail cover glyph when no image. */
  coverEmoji?: string;
  stickers: FlareStickerItem[];
}
