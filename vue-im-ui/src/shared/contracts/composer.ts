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

/**
 * Unified attachment / feature action ids shared by all four platforms (no
 * `create_` prefix). Hosts may use any string id; these are the ones the kit
 * knows how to label and icon by default.
 */
export type FlareComposerActionId =
  | "image"
  | "camera"
  | "video"
  | "file"
  | "location"
  | "card"
  | "vote"
  | "task"
  | "schedule"
  | "link"
  | "announcement"
  | "notification"
  | "miniProgram"
  | "translate";

export const FLARE_COMPOSER_ACTION_IDS: readonly FlareComposerActionId[] = [
  "image", "camera", "video", "file", "location", "card", "vote", "task",
  "schedule", "link", "announcement", "notification", "miniProgram", "translate",
];

/** Core default set the native kits show without configuration. */
export const FLARE_COMPOSER_CORE_ACTION_IDS: readonly FlareComposerActionId[] = [
  "image", "camera", "file", "location", "card", "vote", "task", "schedule",
];

/** One action tile in MessageActionSheet / composer action panels. */
export interface FlareComposerAction {
  /** Stable id (first callback argument); see {@link FlareComposerActionId} for the shared table. */
  id: string;
  label: string;
  /** Optional secondary line under the label. */
  hint?: string;
  /** Canonical Flare semantic icon name (preferred) or any raw string / emoji. */
  icon?: string;
}

const LEGACY_COMPOSER_OPS: Record<string, string> = {
  link: "create_link_card",
  miniProgram: "create_mini_program",
  translate: "create_text",
};

/**
 * Legacy `build(op)` operation name for a unified action id — what the sheet
 * emitted before `action(action)` existed (`file` → `create_file`,
 * `link` → `create_link_card`, ...). Unknown / host-defined ids pass through unchanged.
 */
export function composerActionLegacyOp(id: string): string {
  if (LEGACY_COMPOSER_OPS[id]) return LEGACY_COMPOSER_OPS[id];
  return (FLARE_COMPOSER_ACTION_IDS as readonly string[]).includes(id) ? `create_${id}` : id;
}
