/**
 * 表情 **pack key**（与 `assets/emoji/<key>.webp` 文件名一致）的展示文案。
 * 协议与存储：`EmojiContent.emoji = key`，正文用 `[key]`；此处相当于 i18n 的 `emoji.<key>` 列（按语言分桶）。
 */

import packLocales from "../shared/assets/i18n/emoji-locales.json";

export type EmojiPackLocaleColumn = "zh-Hans" | "en";

const LOCALES = packLocales as Record<EmojiPackLocaleColumn, Record<string, string>>;

export function resolveEmojiPackLocaleColumn(locale?: string): EmojiPackLocaleColumn {
  const l = (locale ?? (typeof navigator !== "undefined" ? navigator.language : "en")).toLowerCase();
  if (l.startsWith("zh")) return "zh-Hans";
  return "en";
}

/** 短名（用于括号内、列表摘要）；未知 key 回退为 key 本身 */
export function emojiPackLabel(key: string, locale?: string): string {
  const k = key.trim();
  if (!k) return "";
  const col = resolveEmojiPackLocaleColumn(locale);
  const primary = LOCALES[col]?.[k];
  if (typeof primary === "string" && primary.trim()) return primary.trim();
  const en = LOCALES.en?.[k];
  if (typeof en === "string" && en.trim()) return en.trim();
  return k;
}

/** 无资源或占位时的气泡展示：`[本地化名]` */
export function formatEmojiPackBracket(key: string, locale?: string): string {
  return `[${emojiPackLabel(key, locale)}]`;
}

export function isKnownEmojiPackKey(key: string): boolean {
  const k = key.trim();
  return Boolean(k && typeof LOCALES.en?.[k] === "string");
}

const PACK_KEY_TOKEN_RE = /\[([a-z][a-z0-9_]*)\]/g;

/**
 * 会话列表 / 摘要等纯文本行：把正文里的 `[pensive_face]` 换成当前语言的短名（与 `emoji-locales` 一致）。
 */
export function formatPackKeysInPlainTextForPreview(text: string, locale?: string): string {
  return text.replace(PACK_KEY_TOKEN_RE, (_m, key: string) => emojiPackLabel(String(key), locale));
}
