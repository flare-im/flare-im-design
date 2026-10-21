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

/**
 * The built-in features of the "+" panel (功能管理), in panel order — the same set and order on all
 * four platforms (contract `composerActions.defaults`). Shown when the host does not supply a list;
 * a host list replaces it whole.
 */
export const FLARE_DEFAULT_COMPOSER_ACTION_IDS: readonly FlareComposerActionId[] = [
  "image", "video", "file", "voice", "card", "poll",
];

/** The registry glyph of each unified action id; an action without its own icon draws it. */
export const FLARE_COMPOSER_ACTION_ICONS: Readonly<Record<FlareComposerActionId, string>> = {
  image: "image", camera: "camera", voice: "mic", video: "video", file: "file", location: "location",
  contact: "card", card: "card", poll: "poll", vote: "poll", task: "check", event: "calendar",
  schedule: "calendar", link: "link", announcement: "announcement", notification: "notification",
  miniApp: "mini-app", miniProgram: "mini-app", translate: "translate",
};

/** The kit string key of the unified action ids it can label; a host may leave `label` out for these. */
export const FLARE_COMPOSER_ACTION_LABEL_KEYS: Readonly<Partial<Record<FlareComposerActionId, string>>> = {
  image: "composer.image", camera: "composer.camera", voice: "composer.voice", video: "composer.video",
  file: "composer.file", location: "composer.location", contact: "composer.card", card: "composer.card",
  poll: "composer.poll", vote: "composer.vote", task: "composer.task", event: "composer.schedule",
  schedule: "composer.schedule", link: "composer.link", notification: "composer.notification",
  translate: "composer.translation",
};

/**
 * Where a "+" tile comes from: a built-in `feature` the tenant's feature switches control, or a
 * `plugin` — the composer-action an authorised plugin declares. Hosts may leave it out.
 */
export type FlareComposerActionKind = "feature" | "plugin";
export const FLARE_COMPOSER_ACTION_KINDS: readonly FlareComposerActionKind[] = ["feature", "plugin"];

/** The generic plugin glyph: a "+" tile whose icon is not a registry name draws this instead. */
export const FLARE_COMPOSER_PLUGIN_ICON = "plugin";

/**
 * The composer toolbar's tools, the same ids on all four platforms. `attachments` is the "+" button
 * that opens the action panel.
 */
export type FlareComposerToolId = "emoji" | "mention" | "voice" | "image" | "richText" | "attachments";
export const FLARE_COMPOSER_TOOL_IDS: readonly FlareComposerToolId[] = [
  "emoji", "mention", "voice", "image", "richText", "attachments",
];

/**
 * One action tile in MessageActionSheet / composer action panels. `label` may be left out for a
 * unified id the kit labels itself (`FLARE_COMPOSER_ACTION_LABEL_KEYS`), so a host can pass the
 * built-in items of a composer menu through as they come.
 */
export interface FlareComposerAction<TIcon = string> extends Omit<FlareActionItem<TIcon>, "label"> {
  label?: string;
  /** Optional secondary line under the label. */
  hint?: string;
  /** `feature`, `plugin`, or omitted for a host's own tile. An unknown icon name draws `plugin`. */
  kind?: FlareComposerActionKind;
}

/** Business availability supplied by the host; omitted means all actions are available. */
export interface FlareComposerCapabilities {
  availableActionIds?: readonly string[];
  /**
   * The toolbar tools to show (`FlareComposerToolId`). Omitted shows every tool; a list shows only
   * the tools it names. Host-owned presentation, not an authorization decision.
   */
  availableToolIds?: readonly string[];
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

/**
 * Fills each missing label from the kit strings by unified id (`translate` resolves a string key);
 * an id the kit cannot label keeps the id itself so a tile never renders blank.
 */
export function labelComposerActions<TAction extends FlareComposerAction<unknown>>(
  actions: readonly TAction[],
  translate: (key: string) => string,
): Array<TAction & { label: string }> {
  return actions.map((action) => {
    const own = action.label?.trim();
    if (own) return action as TAction & { label: string };
    const key = FLARE_COMPOSER_ACTION_LABEL_KEYS[action.id as FlareComposerActionId];
    return { ...action, label: key ? translate(key) : action.id };
  });
}

/** Whether the toolbar shows `tool`: every tool when the host names none, otherwise only the named ones. */
export function composerToolAvailable(
  capabilities: FlareComposerCapabilities | undefined,
  tool: FlareComposerToolId,
): boolean {
  return capabilities?.availableToolIds?.includes(tool) ?? true;
}

/**
 * The glyph name a "+" tile draws, the same rule on all four platforms: a registry name
 * (`isIconName`) draws itself, any other name draws the generic `plugin` glyph. Vue additions: a
 * non-plugin tile without an icon draws its unified id's kit glyph, and one whose icon is an emoji or
 * a single character keeps it for FlareGlyph to draw as text.
 */
export function resolveComposerActionIcon(
  action: { id: string; icon?: unknown; kind?: FlareComposerActionKind },
  isIconName: (name: string) => boolean,
): string {
  const icon = typeof action.icon === "string" ? action.icon.trim() : "";
  if (icon && isIconName(icon)) return icon;
  if (action.kind !== "plugin") {
    if (!icon) return FLARE_COMPOSER_ACTION_ICONS[action.id as FlareComposerActionId] ?? FLARE_COMPOSER_PLUGIN_ICON;
    if (!/^[A-Za-z][A-Za-z0-9-]*$/.test(icon)) return icon;
  }
  return FLARE_COMPOSER_PLUGIN_ICON;
}
