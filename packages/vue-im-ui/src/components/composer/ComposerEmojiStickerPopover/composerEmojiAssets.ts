/**
 * 表情资源：`src/chat/assets/emoji/<pack_key>.webp`。**pack_key** 即协议字段与 `[key]` 文本占位符。
 * 展示文案见 `emoji-locales.json`（`utils/emojiPackI18n.ts`）。
 */

import packLocales from "../../../assets/emoji-sticker/emoji-locales.json";
import { flareAssetUrl } from "../../../shared/assets";
import { reactive } from "vue";

type AssetUrlLoader = () => Promise<string>;

const EMOJI_KEYS = Object.keys((packLocales as { en?: Record<string, string> }).en ?? {}).sort((a, b) =>
  a.localeCompare(b, "en", { numeric: true }),
);

function assetUrl(path: string): string {
  return flareAssetUrl(path);
}

const keyToUrl = new Map<string, string>();
const knownKeys = new Set(EMOJI_KEYS);
const runtimeAssets = new Map<string, ComposerEmojiAssetRegistration>();

export interface ComposerEmojiAssetRegistration {
  /** Stable protocol key used by the wire-format token `[key]`. */
  key: string;
  /** Original asset URL. It may be animated and is used only by a standalone sent emoji. */
  url: string;
  /** Optional already-static thumbnail. Pickers/composers still freeze it defensively. */
  previewUrl?: string;
  /** Optional labels keyed by locale (`en`, `zh-Hans`, ...). */
  labels?: Readonly<Record<string, string>>;
}

export interface ComposerEmojiAssetItem {
  id: string;
  /** 与文件名一致，如 `pensive_face` */
  key: string;
  loadUrl: AssetUrlLoader;
  loadPreviewUrl: AssetUrlLoader;
  labels?: Readonly<Record<string, string>>;
}

const bundledEmojiItems: ComposerEmojiAssetItem[] = EMOJI_KEYS.map((key, i) => ({
  id: `composer-emoji-${String(i + 1).padStart(3, "0")}`,
  key,
  loadUrl: () => loadEmojiUrl(key),
  loadPreviewUrl: () => loadEmojiPreviewUrl(key),
}));

/** Reactive merged catalog: bundled entries plus user-installed runtime entries. */
export const COMPOSER_EMOJI_ITEMS = reactive<ComposerEmojiAssetItem[]>([...bundledEmojiItems]);

function isSafeEmojiKey(value: string): boolean {
  return /^[a-z][a-z0-9_]*$/.test(value);
}

function rebuildEmojiItems(): void {
  const runtime = [...runtimeAssets.values()].map((entry, index): ComposerEmojiAssetItem => ({
    id: `composer-emoji-runtime-${entry.key}-${index}`,
    key: entry.key,
    loadUrl: async () => entry.url,
    loadPreviewUrl: async () => entry.previewUrl?.trim() || entry.url,
    labels: entry.labels,
  }));
  const bundled = bundledEmojiItems.filter((item) => !runtimeAssets.has(item.key));
  COMPOSER_EMOJI_ITEMS.splice(0, COMPOSER_EMOJI_ITEMS.length, ...bundled, ...runtime);
}

/**
 * Adds or replaces user-installed emoji assets without changing the message protocol.
 * Call this again after account/session restore; call [clearComposerEmojiAssetRegistrations]
 * on account switch. Invalid keys and empty URLs are ignored.
 */
export function registerComposerEmojiAssets(entries: readonly ComposerEmojiAssetRegistration[]): void {
  for (const raw of entries) {
    const key = raw.key.trim();
    const url = raw.url.trim();
    if (!isSafeEmojiKey(key) || !url) continue;
    runtimeAssets.set(key, { ...raw, key, url, previewUrl: raw.previewUrl?.trim() || undefined });
    knownKeys.add(key);
  }
  rebuildEmojiItems();
}

export function unregisterComposerEmojiAsset(key: string): void {
  const normalized = key.trim();
  runtimeAssets.delete(normalized);
  if (!EMOJI_KEYS.includes(normalized)) knownKeys.delete(normalized);
  rebuildEmojiItems();
}

export function clearComposerEmojiAssetRegistrations(): void {
  for (const key of runtimeAssets.keys()) {
    if (!EMOJI_KEYS.includes(key)) knownKeys.delete(key);
  }
  runtimeAssets.clear();
  rebuildEmojiItems();
}

async function loadEmojiUrl(key: string): Promise<string> {
  const runtime = runtimeAssets.get(key);
  if (runtime) return runtime.url;
  const cached = keyToUrl.get(key);
  if (cached) return cached;
  if (!knownKeys.has(key)) return "";
  const url = assetUrl(`emoji/${encodeURIComponent(key)}.webp`);
  keyToUrl.set(key, url);
  return url;
}

async function loadEmojiPreviewUrl(key: string): Promise<string> {
  const runtime = runtimeAssets.get(key);
  return runtime?.previewUrl?.trim() || loadEmojiUrl(key);
}

export function hasEmojiPackAssetKey(packKey: string): boolean {
  const k = packKey.trim();
  return k.length > 0 && knownKeys.has(k);
}

export async function resolveEmojiPackAssetUrlByKey(packKey: string): Promise<string | undefined> {
  const k = packKey.trim();
  if (!k || !knownKeys.has(k)) return undefined;
  return loadEmojiUrl(k);
}

/** Static-preview source. The renderer must still decode only frame zero. */
export async function resolveEmojiPackPreviewUrlByKey(packKey: string): Promise<string | undefined> {
  const k = packKey.trim();
  if (!k || !knownKeys.has(k)) return undefined;
  return loadEmojiPreviewUrl(k);
}

export function emojiAssetRuntimeLabel(key: string, locale: string): string | undefined {
  const labels = runtimeAssets.get(key.trim())?.labels;
  if (!labels) return undefined;
  const normalized = locale.toLowerCase();
  const exact = Object.entries(labels).find(([candidate]) => candidate.toLowerCase() === normalized)?.[1];
  if (exact?.trim()) return exact.trim();
  const language = normalized.split("-")[0];
  const compatible = Object.entries(labels).find(([candidate]) => candidate.toLowerCase().split("-")[0] === language)?.[1];
  return compatible?.trim() || labels.en?.trim() || undefined;
}

export type PlainTextEmojiDisplaySegment =
  | { kind: "text"; text: string }
  | { kind: "emoji"; key: string; loadUrl: AssetUrlLoader }
  /** `[key]` 但本地包无此 webp */
  | { kind: "emojiUnknown"; key: string };

const BRACKET_TOKEN_RE = /(\[[a-z][a-z0-9_]*\])/g;

/**
 * 解析正文里的 `[pack_key]`；其余保持纯文本。仅小写 snake 形式 key 参与匹配。
 */
export function splitPlainTextForEmojiDisplay(text: string): PlainTextEmojiDisplaySegment[] {
  const chunks = text.split(BRACKET_TOKEN_RE);
  const out: PlainTextEmojiDisplaySegment[] = [];
  for (const chunk of chunks) {
    if (chunk === "") continue;
    const m = /^\[([a-z][a-z0-9_]*)\]$/.exec(chunk);
    if (m) {
      const key = m[1];
      if (knownKeys.has(key)) out.push({ kind: "emoji", key, loadUrl: () => loadEmojiPreviewUrl(key) });
      else out.push({ kind: "emojiUnknown", key });
      continue;
    }
    const last = out[out.length - 1];
    if (last?.kind === "text") last.text += chunk;
    else out.push({ kind: "text", text: chunk });
  }
  return out;
}

/** trim 后整段为单个 `[key]` 且包内有 webp → 大图首帧 */
export function resolveLoneEmojiPackInText(text: string): { key: string; loadUrl: AssetUrlLoader } | null {
  const t = text.trim();
  if (!t) return null;
  const m = /^\[([a-z][a-z0-9_]*)\]$/.exec(t);
  if (!m) return null;
  const key = m[1];
  if (!knownKeys.has(key)) return null;
  return { key, loadUrl: () => loadEmojiUrl(key) };
}
