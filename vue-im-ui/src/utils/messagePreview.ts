import { emojiPackLabel, formatPackKeysInPlainTextForPreview } from "./emojiPackI18n";
import { asRecord, readArray, readNumber, readString } from "./contentData";
import type { ContentElem, MessageContentLike } from "./contentElem";
import { normalizeToContentElem, pickNestedPayload, textBodyFromContent } from "./contentElem";
import { imageInfoIsMotion } from "./motionImage";
import { markdownToPlainText } from "./markdown";

export function getContentDecodedPreview(decoded: ContentElem | null | undefined, locale?: string): string {
  if (!decoded) return "";
  const type = decoded.contentType;
  const root = asRecord(decoded);

  switch (type) {
    case "text":
      return formatPreviewText(textBodyFromContent(decoded), locale);
    case "rich_text":
    case "richText": {
      const richOuter = pickNestedPayload(decoded, "rich_text");
      const richNested = asRecord(richOuter.rich_text ?? richOuter.richText);
      const rich = Object.keys(richNested).length ? richNested : richOuter;
      const sourcePayload = asRecord(
        rich.sourcePayload
          ?? rich.source_payload
          ?? richOuter.sourcePayload
          ?? richOuter.source_payload
          ?? root.sourcePayload
          ?? root.source_payload,
      );
      const markdown = readString(sourcePayload, "markdown", "md");
      const title = readString(rich, "title") || readString(richOuter, "title") || readString(root, "title");
      const plain = readString(rich, "plainText", "plain_text", "text")
        || readString(richOuter, "plainText", "plain_text", "text")
        || readString(root, "plainText", "plain_text", "text");
      const richText = markdown || (title && plain ? `${title} ${plain}` : title || plain);
      return formatPreviewText(richText, locale) || "[富文本]";
    }
    case "image": {
      const image = pickNestedPayload(decoded, "image");
      const payload = Object.keys(image).length ? image : root;
      if (imageInfoIsMotion(payload as { animated?: boolean; format?: number; mimeType?: string })) {
        return "[动图]";
      }
      return readString(payload, "description", "title") || "[图片]";
    }
    case "video":
      return readString(pickNestedPayload(decoded, "video"), "description", "title") || "[视频]";
    case "audio":
      return readString(pickNestedPayload(decoded, "audio"), "description", "title") || "[语音]";
    case "file": {
      const file = pickNestedPayload(decoded, "file");
      const name = readString(file, "fileName", "title");
      return name ? `[文件] ${name}` : "[文件]";
    }
    case "location": {
      const loc = pickNestedPayload(decoded, "location");
      const title = readString(loc, "title") || readString(root, "title");
      const address = readString(loc, "address") || readString(root, "address");
      return title || address ? `[位置] ${title || address}` : "[位置]";
    }
    case "card": {
      const card = pickNestedPayload(decoded, "card");
      const title = readString(card, "title") || readString(root, "title");
      const id = readString(card, "id");
      return title || id ? `[名片] ${title || id}` : "[名片]";
    }
    case "sticker":
      return "[贴纸]";
    case "emoji": {
      const emoji = pickNestedPayload(decoded, "emoji");
      const key = readString(emoji, "emoji", "key") || readString(root, "emoji", "key");
      return key ? emojiPackLabel(key, locale) : "[表情]";
    }
    case "quote": {
      const quote = pickNestedPayload(decoded, "quote");
      const current = quote.currentContent as ContentElem | undefined;
      if (current) return getContentDecodedPreview(current, locale) || readString(quote, "quotedTextPreview");
      return readString(quote, "quotedTextPreview", "preview") || readString(root, "text", "body") || "[引用]";
    }
    case "link_card":
      return readString(pickNestedPayload(decoded, "link_card"), "title") || "[链接]";
    case "forward": {
      const forward = pickNestedPayload(decoded, "forward");
      const items = readArray(forward, "items").length ? readArray(forward, "items") : readArray(root, "items");
      if (items.length > 1) return `[转发] ${items.length} 条消息`;
      if (items.length === 1) {
        const first = asRecord(items[0]);
        return formatPreviewText(readString(first, "plainText", "text"), locale) || "[转发]";
      }
      return readString(forward, "title") || "[转发]";
    }
    case "thread":
      return readString(pickNestedPayload(decoded, "thread"), "threadTitle", "title") || "[话题]";
    case "mini_program":
      return readString(pickNestedPayload(decoded, "mini_program"), "title") || "[小程序]";
    case "image_group":
      return `[多图] ${readArray(pickNestedPayload(decoded, "image_group"), "images").length || readArray(root, "images").length} 张`;
    case "system":
      return readString(pickNestedPayload(decoded, "system"), "body", "text") || "[系统消息]";
    case "notification":
      return (
        readString(pickNestedPayload(decoded, "notification"), "body", "text") ||
        readString(pickNestedPayload(decoded, "notification"), "title") ||
        "[通知]"
      );
    case "vote":
      return "[投票]";
    case "task":
      return readString(pickNestedPayload(decoded, "task"), "title") || "[任务]";
    case "schedule":
      return readString(pickNestedPayload(decoded, "schedule"), "title") || "[日程]";
    case "announcement":
      return readString(pickNestedPayload(decoded, "announcement"), "title", "body") || "[公告]";
    case "custom":
      return readString(pickNestedPayload(decoded, "custom"), "description", "text") || "[自定义]";
    case "placeholder":
      return readString(pickNestedPayload(decoded, "placeholder"), "fallbackText") || "[占位]";
    default:
      return "";
  }
}

type StoredPreviewPayload = {
  k?: unknown;
  a?: unknown;
};

export type MessagePreviewVisual =
  | { kind: "text"; text: string }
  | { kind: "emoji"; key: string; label: string }
  | { kind: "sticker"; label: string; packageId?: string; stickerId?: string; url?: string };

export function displayTextFromStoredPreview(raw?: string | null, locale?: string): string {
  const text = raw?.trim() ?? "";
  if (!text) return "";
  const payload = parseStoredPreview(text);
  if (!payload) return formatPreviewText(text, locale);
  return formatPreviewText(storedPreviewPayloadText(payload, locale) || text, locale);
}

export function previewVisualFromStoredPreview(raw?: string | null, locale?: string): MessagePreviewVisual | null {
  const text = raw?.trim() ?? "";
  if (!text) return null;
  const payload = parseStoredPreview(text);
  if (!payload) return textPreview(text);
  return storedPreviewPayloadVisual(payload, locale);
}

export function previewVisualFromMessageContent(
  content?: MessageContentLike | ContentElem | null,
  locale?: string,
): MessagePreviewVisual | null {
  if (!content) return null;
  const elem = "data" in content ? normalizeToContentElem(content as MessageContentLike) : (content as ContentElem);
  const type = elem?.contentType;
  if (!type) return null;
  const root = asRecord(elem);
  if (type === "emoji") {
    const emoji = pickNestedPayload(elem, "emoji");
    const key = readString(emoji, "emoji", "key") || readString(root, "emoji", "key");
    if (!key) return { kind: "text", text: "[表情]" };
    return { kind: "emoji", key, label: emojiPackLabel(key, locale) };
  }
  if (type === "sticker") {
    const sticker = pickNestedPayload(elem, "sticker");
    return {
      kind: "sticker",
      label: locale?.toLowerCase().startsWith("en") ? "Sticker" : "贴纸",
      stickerId: readString(sticker, "stickerId", "sticker_id", "id") || readString(root, "stickerId", "sticker_id", "id"),
      packageId: readString(sticker, "packageId", "package_id") || readString(root, "packageId", "package_id"),
      url: readString(sticker, "url") || readString(root, "url"),
    };
  }
  const text = getContentDecodedPreview(elem, locale).trim();
  return text ? { kind: "text", text } : null;
}

function parseStoredPreview(text: string): StoredPreviewPayload | null {
  if (!text.startsWith("{")) return null;
  try {
    const parsed = JSON.parse(text) as unknown;
    if (!parsed || typeof parsed !== "object") return null;
    const payload = parsed as StoredPreviewPayload;
    return typeof payload.k === "string" ? payload : null;
  } catch {
    return null;
  }
}

function storedPreviewPayloadText(payload: StoredPreviewPayload, locale?: string): string {
  const visual = storedPreviewPayloadVisual(payload, locale);
  if (visual?.kind === "emoji") return visual.label;
  if (visual?.kind === "sticker") return `[${visual.label}]`;
  if (visual?.kind === "text") return visual.text;
  return "";
}

function storedPreviewPayloadVisual(payload: StoredPreviewPayload, locale?: string): MessagePreviewVisual | null {
  const key = typeof payload.k === "string" ? payload.k : "";
  const args = asRecord(payload.a);
  switch (key) {
    case "im.preview.user_text":
      return textPreview(readString(args, "t"));
    case "im.preview.rich_text":
      return textPreview(joinText(readString(args, "title"), readString(args, "body"), readString(args, "markdown")) || "[富文本]");
    case "im.preview.file": {
      const name = readString(args, "n");
      return textPreview(name ? `[文件] ${name}` : "[文件]");
    }
    case "im.preview.image":
      return textPreview(readBool(args, "m") ? "[动图]" : readString(args, "d") || "[图片]");
    case "im.preview.video":
      return textPreview(readString(args, "d") || "[视频]");
    case "im.preview.audio":
      return textPreview(readString(args, "d") || "[语音]");
    case "im.preview.location":
      return textPreview(readString(args, "label") ? `[位置] ${readString(args, "label")}` : "[位置]");
    case "im.preview.card":
      return textPreview(readString(args, "label") ? `[名片] ${readString(args, "label")}` : "[名片]");
    case "im.preview.sticker":
      return {
        kind: "sticker",
        label: locale?.toLowerCase().startsWith("en") ? "Sticker" : "贴纸",
        stickerId: readString(args, "sid", "stickerId", "sticker_id", "id", "s"),
        packageId: readString(args, "pid", "packageId", "package_id"),
        url: readString(args, "u", "url"),
      };
    case "im.preview.emoji":
      return emojiPreviewVisual(args, locale);
    case "im.preview.quote":
      return textPreview(storedPreviewPayloadText(asRecord(args.inner) as StoredPreviewPayload, locale) || "[引用]");
    case "im.preview.link":
      return textPreview(readString(args, "t") || "[链接]");
    case "im.preview.forward_empty":
      return textPreview("[转发]");
    case "im.preview.forward_many": {
      const count = readNumber(args, 0, "n");
      return textPreview(count > 0 ? `[转发] ${count} 条消息` : "[转发]");
    }
    case "im.preview.thread":
      return textPreview(readString(args, "t") || "[话题]");
    case "im.preview.mini_program":
      return textPreview(readString(args, "t") || "[小程序]");
    case "im.preview.image_group":
      return textPreview("[多图]");
    case "im.preview.system":
      return textPreview(readString(args, "fb", "t", "body", "title", "ik", "ek") || "[系统消息]");
    case "im.preview.notification":
      return textPreview(readString(args, "fb", "body", "title", "ik") || "[通知]");
    case "im.preview.vote":
      return textPreview("[投票]");
    case "im.preview.task":
      return textPreview(readString(args, "t") || "[任务]");
    case "im.preview.schedule":
      return textPreview("[日程]");
    case "im.preview.announcement":
      return textPreview(readString(args, "t") || "[公告]");
    case "im.preview.custom":
      return textPreview(readString(args, "d") || "[自定义]");
    case "im.preview.placeholder":
      return textPreview(readString(args, "t") || "[占位]");
    case "im.preview.unknown":
      return textPreview("[未知]");
    default:
      return null;
  }
}

function textPreview(text: string): MessagePreviewVisual | null {
  const t = markdownToPlainText(text).trim();
  return t ? { kind: "text", text: t } : null;
}

function readBool(record: Record<string, unknown>, key: string): boolean {
  return record[key] === true;
}

function joinText(...values: string[]): string {
  return values.map((value) => value.trim()).filter(Boolean).join(" ");
}

function formatPreviewText(text: string, locale?: string): string {
  return formatPackKeysInPlainTextForPreview(markdownToPlainText(text), locale);
}

export function previewTextFromMessageContent(content?: MessageContentLike | null, locale?: string): string {
  if (!content) return "";
  return getContentDecodedPreview(normalizeToContentElem(content), locale);
}

export function hasRenderableMessageContent(content?: MessageContentLike | null): boolean {
  if (!content) return false;
  return previewTextFromMessageContent(content).trim().length > 0;
}

export type MessageTextSource = {
  serverId: string;
  clientMsgId: string;
  content?: MessageContentLike | null;
  lastMessagePreview?: string;
};

/** Plain-text extraction for copy/reply preview — no SDK runtime dependency. */
export function getMessageText(message: MessageTextSource): string {
  const data = (message.content as { data?: Record<string, unknown> } | undefined)?.data ?? {};
  const text = data.text ?? data.emoji ?? data.title ?? data.description;
  if (typeof text === "string" && text.trim()) return formatPreviewText(text);
  const preview = previewTextFromMessageContent(message.content);
  if (preview.trim()) return preview;
  const storedPreview = displayTextFromStoredPreview(message.lastMessagePreview);
  if (storedPreview) return storedPreview;
  return message.serverId || message.clientMsgId || "";
}

function emojiPreviewText(args: Record<string, unknown>, locale?: string): string {
  const visual = emojiPreviewVisual(args, locale);
  if (!visual) return "[表情]";
  return visual.kind === "emoji" ? visual.label : visual.text;
}

function emojiPreviewVisual(
  args: Record<string, unknown>,
  locale?: string,
): Extract<MessagePreviewVisual, { kind: "text" | "emoji" }> {
  const key = readString(args, "e", "emoji", "key");
  if (!key) return { kind: "text", text: "[表情]" };
  return { kind: "emoji", key, label: emojiPackLabel(key, locale) };
}
