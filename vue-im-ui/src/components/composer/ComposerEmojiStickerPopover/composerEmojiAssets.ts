/**
 * 表情资源：`src/chat/assets/emoji/<pack_key>.webp`。**pack_key** 即协议字段与 `[key]` 文本占位符。
 * 展示文案见 `emoji-locales.json`（`utils/emojiPackI18n.ts`）。
 */

import packLocales from "../../../shared/assets/i18n/emoji-locales.json";

type AssetUrlLoader = () => Promise<string>;

const ASSET_BASE_PATH = "/flare-im-ui-assets";
const EMOJI_KEYS = Object.keys((packLocales as { en?: Record<string, string> }).en ?? {}).sort((a, b) =>
  a.localeCompare(b, "en", { numeric: true }),
);

function assetUrl(path: string): string {
  return `${ASSET_BASE_PATH}/${path.replace(/^\/+/, "")}`;
}

const keyToUrl = new Map<string, string>();
const knownKeys = new Set(EMOJI_KEYS);

export interface ComposerEmojiAssetItem {
  id: string;
  /** 与文件名一致，如 `pensive_face` */
  key: string;
  loadUrl: AssetUrlLoader;
}

export const COMPOSER_EMOJI_ITEMS: ComposerEmojiAssetItem[] = EMOJI_KEYS.map((key, i) => ({
  id: `composer-emoji-${String(i + 1).padStart(3, "0")}`,
  key,
  loadUrl: () => loadEmojiUrl(key),
}));

async function loadEmojiUrl(key: string): Promise<string> {
  const cached = keyToUrl.get(key);
  if (cached) return cached;
  if (!knownKeys.has(key)) return "";
  const url = assetUrl(`emoji/${encodeURIComponent(key)}.webp`);
  keyToUrl.set(key, url);
  return url;
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
      if (knownKeys.has(key)) out.push({ kind: "emoji", key, loadUrl: () => loadEmojiUrl(key) });
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
