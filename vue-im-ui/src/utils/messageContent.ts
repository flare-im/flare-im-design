import { MessageContentType } from "@flare-im/sdk";

const contentTypeValues = new Set<string>(Object.values(MessageContentType));

// Meta content types the kit renders as centered notices (group created, member
// joined, …). They aren't in the SDK's MessageContentType enum, but must pass
// through so `isSystemLike` fires instead of falling back to a Custom bubble.
const UI_NOTICE_TYPES = new Set(["system", "notification"]);

export function messageContentTypeForUi(value: unknown): string {
  if (typeof value === "string" && (contentTypeValues.has(value) || UI_NOTICE_TYPES.has(value))) return value;
  if (typeof value === "number") {
    return Object.values(MessageContentType)[value] ?? MessageContentType.Custom;
  }
  return MessageContentType.Custom;
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
