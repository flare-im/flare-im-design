import type { FlareActionItem } from "./action-menu";

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
  | "voice"
  | "video"
  | "file"
  | "location"
  | "contact"
  | "card"
  | "poll"
  | "vote"
  | "task"
  | "event"
  | "schedule"
  | "link"
  | "announcement"
  | "notification"
  | "miniApp"
  | "miniProgram"
  | "translate";

export const FLARE_COMPOSER_ACTION_IDS: readonly FlareComposerActionId[] = [
  "image", "camera", "voice", "video", "file", "location", "contact", "card",
  "poll", "vote", "task", "event", "schedule", "link", "announcement",
  "notification", "miniApp", "miniProgram", "translate",
];

/** Default attachment set shown when the host does not supply one. */
export const FLARE_DEFAULT_COMPOSER_ACTION_IDS: readonly FlareComposerActionId[] = [
  "image", "video", "file", "voice", "location", "contact",
];

/** One action tile in MessageActionSheet / composer action panels. */
export interface FlareComposerAction<TIcon = string> extends FlareActionItem<TIcon> {
  /** Optional secondary line under the label. */
  hint?: string;
}

/** Business availability supplied by the host; omitted means all actions are available. */
export interface FlareComposerCapabilities {
  availableActionIds?: readonly string[];
  /**
   * 这个会话**支持不支持** @ 某个人。缺省 = 支持;单聊传 false。
   *
   * 与「名册到了没有」是两件事:群聊的名册在加载中同样是空的,拿 `mentionCandidates.length`
   * 当开关会让按钮闪进闪出,而在单聊里点开只会得到一个「所有人」—— 两个人的会话 @所有人
   * 没有意义。所以要一个独立的能力位,不能塞进 `availableActionIds`:宿主一旦给了那份白名单
   * (这个示例 app 就给了),@ 会跟着被静默摘掉。
   */
  mentions?: boolean;
}

export interface ResolveComposerActionsOptions<TIcon = string> {
  defaults: readonly FlareComposerAction<TIcon>[];
  capabilities?: FlareComposerCapabilities;
  /** A host list is a full replacement, so removal and reordering stay obvious. */
  actions?: readonly FlareComposerAction<TIcon>[];
}

/**
 * Defaults -> capabilities -> host configuration. The result is stable, deduplicated,
 * and ready for either a desktop menu or mobile sheet.
 */
export function resolveComposerActions<TIcon = string>({
  defaults,
  capabilities,
  actions,
}: ResolveComposerActionsOptions<TIcon>): FlareComposerAction<TIcon>[] {
  const source = actions ?? defaults;
  const available = capabilities?.availableActionIds
    ? new Set(capabilities.availableActionIds)
    : undefined;
  const seen = new Set<string>();
  return source
    .map((action, index) => ({ action, index }))
    .filter(({ action }) => {
      if (!action.id || seen.has(action.id) || action.visible === false) return false;
      if (available && !available.has(action.id)) return false;
      seen.add(action.id);
      return true;
    })
    .sort((left, right) =>
      (left.action.order ?? left.index) - (right.action.order ?? right.index)
      || left.index - right.index)
    .map(({ action }) => action);
}
