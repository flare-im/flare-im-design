// UI-owned content discriminators. The component package intentionally has no
// transport, session, or persistence dependency.
//
// ## 顺序是契约的一部分
//
// The order is part of the cross-platform component contract. Do not reorder:
// 数值型 contentType 是按声明下标解析的（见 messageContentTypeForUi），
// 插一个到中间会让所有后续类型静默错位。
//
// Drift is pinned by `messageContent.contract.test.ts`, which verifies this
// package-owned list and its stable numeric projection.
const MESSAGE_CONTENT_TYPES = [
  "text",
  "image",
  "video",
  "audio",
  "file",
  "location",
  "card",
  "sticker",
  "emoji",
  "quote",
  "link_card",
  "forward",
  "thread",
  "mini_program",
  "rich_text",
  "image_group",
  "system",
  "notification",
  "vote",
  "task",
  "schedule",
  "announcement",
  "custom",
  "placeholder",
] as const;

const CUSTOM = "custom";

const contentTypeValues = new Set<string>(MESSAGE_CONTENT_TYPES);

export function messageContentTypeForUi(value: unknown): string {
  // "system" / "notification" 也在上面的列表里（枚举本来就有），
  // 所以这里不需要额外的 UI 白名单 —— 它们照常命中 contentTypeValues，
  // isSystemLike 能正常触发，不会退化成 Custom 气泡。
  if (typeof value === "string" && contentTypeValues.has(value)) return value;
  if (typeof value === "number") {
    return MESSAGE_CONTENT_TYPES[value] ?? CUSTOM;
  }
  return CUSTOM;
}

export function buildUiTaggedMessageContent(input: {
  contentType: unknown;
  data?: Record<string, unknown>;
}): Record<string, unknown> {
  const contentType = messageContentTypeForUi(input.contentType);
  const data = input.data ?? {};
  return {
    contentType,
    ...data,
    [contentType]: data,
  };
}

export function normalizeEmojiPackKey(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) return "";
  const bracket = /^\[([a-z][a-z0-9_]*)\]$/.exec(trimmed);
  if (bracket) return bracket[1];
  return /^[a-z][a-z0-9_]*$/.test(trimmed) ? trimmed : "";
}

export function formatEmojiPackToken(value: string): string {
  const key = normalizeEmojiPackKey(value);
  return key ? `[${key}]` : "";
}

export function resolveLoneEmojiPackKey(value: string): string {
  const trimmed = value.trim();
  return /^\[[a-z][a-z0-9_]*\]$/.test(trimmed) ? normalizeEmojiPackKey(trimmed) : "";
}
