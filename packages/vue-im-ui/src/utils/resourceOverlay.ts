/**
 * What a resource pack may change, the same on four kits (`spec/resource-overlay-vectors.json`). A pack is data read by
 * code already in the build: it replaces copy and colours that exist and adds emoji, and nothing else. Everything here
 * is pure; `applyFlareResourceOverlay` folds the result into the kit.
 */

export const FLARE_RESOURCE_SCHEMA = "flare.resource.v1";

/** One entry of `update.get_resources`, as the SDK returns it. */
export interface FlareResourcePack {
  id: string;
  kind: string;
  packVersion: number;
  contentJson: string;
}

export interface FlareResourceEmoji {
  key: string;
  url: string;
  previewUrl?: string;
  labels?: Record<string, string>;
}

export interface FlareResourceSticker {
  stickerId: string;
  url: string;
  previewUrl?: string;
  alt?: string;
}

export interface FlareResourceStickerPack {
  id: string;
  title: string;
  iconUrl?: string;
  stickers: FlareResourceSticker[];
}

export interface FlareResourceEmojiResult {
  emoji: FlareResourceEmoji[];
  stickerPacks: FlareResourceStickerPack[];
}

/** The packs a kit can use, in the order given, each cut down to what the rules read. */
export interface FlareResourceContents {
  /** The `locales` object of every strings pack. */
  stringPacks: unknown[];
  /** Every tokens pack. */
  tokenPacks: Record<string, unknown>[];
  /** The entries of every emoji pack's `packs`, one list. */
  emojiPacks: unknown[];
  /** Packs that were broken or of a kind no kit reads. A help pack is the host's, so it does not count. */
  ignored: number;
}

const PLACEHOLDER = /\{[A-Za-z0-9_]+\}|%[sd@]/g;
const COLOR = /^#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$/;
const SAFE_ID = /^[A-Za-z0-9_-]+$/;
const EMOJI_KEY = /^[a-z][a-z0-9_]*$/;
const HTTPS_URL = /^https:\/\/[A-Za-z0-9.-]+(?::[0-9]+)?(?:[/?#][!-~]*)?$/;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isPresent(value: unknown): boolean {
  return value !== undefined && value !== null;
}

/** A string that says something, trimmed; anything else is nothing. */
function filled(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  return value.trim() || undefined;
}

/** The pack's content when it is the object its manifest entry promised, else null. */
export function flareResourceContent(kind: string, contentJson: string): Record<string, unknown> | null {
  let parsed: unknown;
  try {
    parsed = JSON.parse(contentJson);
  } catch {
    return null;
  }
  return isRecord(parsed) && parsed.schema === FLARE_RESOURCE_SCHEMA && parsed.kind === kind ? parsed : null;
}

export function flareResourceContents(packs: readonly FlareResourcePack[]): FlareResourceContents {
  const contents: FlareResourceContents = { stringPacks: [], tokenPacks: [], emojiPacks: [], ignored: 0 };
  for (const pack of packs) {
    const content = flareResourceContent(pack.kind, pack.contentJson);
    if (content && pack.kind === "strings") contents.stringPacks.push(content.locales);
    else if (content && pack.kind === "tokens") contents.tokenPacks.push(content);
    else if (content && pack.kind === "emoji") {
      if (Array.isArray(content.packs)) contents.emojiPacks.push(...content.packs);
    } else if (!content || pack.kind !== "help") contents.ignored += 1;
  }
  return contents;
}

/** The placeholders `text` carries, as a sorted set. */
export function flareResourcePlaceholders(text: string): string[] {
  return [...new Set(text.match(PLACEHOLDER) ?? [])].sort();
}

function samePlaceholders(a: string, b: string): boolean {
  return flareResourcePlaceholders(a).join("\n") === flareResourcePlaceholders(b).join("\n");
}

/** The entries of one language that may replace the built-in text `builtIn` answers for each key. */
export function flareResourceStrings(
  builtIn: (key: string) => string | undefined,
  entries: unknown,
): Record<string, string> {
  const accepted: Record<string, string> = {};
  if (!isRecord(entries)) return accepted;
  for (const [key, value] of Object.entries(entries)) {
    const current = builtIn(key);
    if (current === undefined || !filled(value)) continue;
    if (samePlaceholders(current, value as string)) accepted[key] = value as string;
  }
  return accepted;
}

function normalizedTag(tag: string): string {
  return tag.trim().toLowerCase().replace(/_/g, "-");
}

/** The tag of `available` that speaks for `requested`, or undefined: copy never crosses into another language. */
export function flareResourceLocale(requested: string, available: readonly string[]): string | undefined {
  const wanted = normalizedTag(requested);
  if (!wanted) return undefined;
  const tags = available.map((tag) => [normalizedTag(tag), tag] as const).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  for (let cut = wanted; cut; cut = cut.includes("-") ? cut.slice(0, cut.lastIndexOf("-")) : "") {
    const exact = tags.find(([tag]) => tag === cut);
    if (exact) return exact[1];
  }
  return tags.find(([tag]) => tag.startsWith(`${wanted}-`))?.[1];
}

/** What the strings packs say for `locale`, in pack order: a later pack wins a key. */
export function flareResourceStringsFor(
  stringPacks: readonly unknown[],
  locale: string,
  builtIn: (key: string) => string | undefined,
): Record<string, string> {
  const accepted: Record<string, string> = {};
  for (const locales of stringPacks) {
    if (!isRecord(locales)) continue;
    const tag = flareResourceLocale(locale, Object.keys(locales));
    if (tag !== undefined) Object.assign(accepted, flareResourceStrings(builtIn, locales[tag]));
  }
  return accepted;
}

/** The colours of one group whose key is known and whose value is `#RRGGBB` or `#RRGGBBAA`. */
export function flareResourceColors(known: ReadonlySet<string>, group: unknown): Record<string, string> {
  const accepted: Record<string, string> = {};
  if (!isRecord(group)) return accepted;
  for (const [key, value] of Object.entries(group)) {
    if (known.has(key) && typeof value === "string" && COLOR.test(value)) accepted[key] = value;
  }
  return accepted;
}

/** One group of the tokens packs, in pack order: a later pack wins a key. `colors` is light and `dark` dark; neither reaches the other. */
export function flareResourceColorsFor(
  tokenPacks: readonly Record<string, unknown>[],
  group: "colors" | "dark",
  known: ReadonlySet<string>,
): Record<string, string> {
  const accepted: Record<string, string> = {};
  for (const pack of tokenPacks) Object.assign(accepted, flareResourceColors(known, pack[group]));
  return accepted;
}

/** An image address the entry can keep: absent, or https. */
function optionalUrl(value: unknown): { ok: boolean; url?: string } {
  if (!isPresent(value)) return { ok: true };
  if (typeof value !== "string" || !HTTPS_URL.test(value)) return { ok: false };
  return { ok: true, url: value };
}

function stickerOf(raw: unknown, seen: Set<string>): FlareResourceSticker | undefined {
  if (!isRecord(raw)) return undefined;
  const { stickerId, url } = raw;
  if (typeof stickerId !== "string" || !SAFE_ID.test(stickerId) || seen.has(stickerId)) return undefined;
  if (typeof url !== "string" || !HTTPS_URL.test(url)) return undefined;
  const preview = optionalUrl(raw.previewUrl);
  if (!preview.ok) return undefined;
  seen.add(stickerId);
  const sticker: FlareResourceSticker = { stickerId, url };
  if (preview.url) sticker.previewUrl = preview.url;
  const alt = filled(raw.alt);
  if (alt) sticker.alt = alt;
  return sticker;
}

function emojiOf(raw: unknown, seen: Set<string>): FlareResourceEmoji | undefined {
  if (!isRecord(raw)) return undefined;
  const { key, url } = raw;
  if (typeof key !== "string" || !EMOJI_KEY.test(key) || seen.has(key)) return undefined;
  if (typeof url !== "string" || !HTTPS_URL.test(url)) return undefined;
  const preview = optionalUrl(raw.previewUrl);
  if (!preview.ok) return undefined;
  seen.add(key);
  const emoji: FlareResourceEmoji = { key, url };
  if (preview.url) emoji.previewUrl = preview.url;
  if (isRecord(raw.labels)) {
    const labels: Record<string, string> = {};
    for (const [tag, label] of Object.entries(raw.labels)) {
      const text = filled(label);
      if (text) labels[tag] = text;
    }
    if (Object.keys(labels).length) emoji.labels = labels;
  }
  return emoji;
}

/** The emoji and sticker packs that add to the catalog. Nothing here replaces what ships with the kit. */
export function flareResourceEmoji(
  builtInEmoji: Iterable<string>,
  builtInPacks: Iterable<string>,
  packs: unknown,
): FlareResourceEmojiResult {
  const result: FlareResourceEmojiResult = { emoji: [], stickerPacks: [] };
  if (!Array.isArray(packs)) return result;
  const seenKeys = new Set(builtInEmoji);
  const seenPacks = new Set(builtInPacks);
  for (const raw of packs) {
    if (!isRecord(raw)) continue;
    const { id } = raw;
    const title = filled(raw.title);
    const icon = optionalUrl(raw.iconUrl);
    if (typeof id !== "string" || !SAFE_ID.test(id) || seenPacks.has(id) || !title || !icon.ok) continue;
    const seenStickers = new Set<string>();
    const stickers = (Array.isArray(raw.stickers) ? raw.stickers : [])
      .map((item) => stickerOf(item, seenStickers))
      .filter((item): item is FlareResourceSticker => item !== undefined);
    const emoji = (Array.isArray(raw.emoji) ? raw.emoji : [])
      .map((item) => emojiOf(item, seenKeys))
      .filter((item): item is FlareResourceEmoji => item !== undefined);
    if (!stickers.length && !emoji.length) continue;
    seenPacks.add(id);
    result.emoji.push(...emoji);
    if (stickers.length) {
      const pack: FlareResourceStickerPack = { id, title, stickers };
      if (icon.url) pack.iconUrl = icon.url;
      result.stickerPacks.push(pack);
    }
  }
  return result;
}
