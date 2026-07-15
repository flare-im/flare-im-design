import { emojiPackLabel, formatPackKeysInPlainTextForPreview } from "./emojiPackI18n";
import { asRecord, readArray, readNumber, readString } from "./contentData";
import type { ContentElem, MessageContentLike } from "./contentElem";
import { normalizeToContentElem, pickNestedPayload, textBodyFromContent } from "./contentElem";
import { imageInfoIsMotion } from "./motionImage";
import { markdownToPlainText } from "./markdown";
import { resolveFlareMessage } from "../shared/i18n/messages";

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
      return formatPreviewText(richText, locale) || resolveFlareMessage(locale, "preview.richText");
    }
    case "image": {
      const image = pickNestedPayload(decoded, "image");
      const payload = Object.keys(image).length ? image : root;
      if (imageInfoIsMotion(payload as { animated?: boolean; format?: number; mimeType?: string })) {
        return resolveFlareMessage(locale, "preview.gif");
      }
      return readString(payload, "description", "title") || resolveFlareMessage(locale, "preview.image");
    }
    case "video":
      return readString(pickNestedPayload(decoded, "video"), "description", "title") || resolveFlareMessage(locale, "preview.video");
    case "audio":
      return readString(pickNestedPayload(decoded, "audio"), "description", "title") || resolveFlareMessage(locale, "preview.audio");
    case "file": {
      const file = pickNestedPayload(decoded, "file");
      const name = readString(file, "fileName", "title");
      return name ? resolveFlareMessage(locale, "preview.fileNamed", { name }) : resolveFlareMessage(locale, "preview.file");
    }
    case "location": {
      const loc = pickNestedPayload(decoded, "location");
      const title = readString(loc, "title") || readString(root, "title");
      const address = readString(loc, "address") || readString(root, "address");
      return title || address ? resolveFlareMessage(locale, "preview.locationNamed", { label: title || address }) : resolveFlareMessage(locale, "preview.location");
    }
    case "card": {
      const card = pickNestedPayload(decoded, "card");
      const title = readString(card, "title") || readString(root, "title");
      const id = readString(card, "id");
      return title || id ? resolveFlareMessage(locale, "preview.cardNamed", { label: title || id }) : resolveFlareMessage(locale, "preview.card");
    }
    case "sticker":
      return resolveFlareMessage(locale, "preview.sticker");
    case "emoji": {
      const emoji = pickNestedPayload(decoded, "emoji");
      const key = readString(emoji, "emoji", "key") || readString(root, "emoji", "key");
      return key ? emojiPackLabel(key, locale) : resolveFlareMessage(locale, "preview.emoji");
    }
    case "quote": {
      const quote = pickNestedPayload(decoded, "quote");
      const current = quote.currentContent as ContentElem | undefined;
      if (current) return getContentDecodedPreview(current, locale) || readString(quote, "quotedTextPreview");
      return readString(quote, "quotedTextPreview", "preview") || readString(root, "text", "body") || resolveFlareMessage(locale, "preview.quote");
    }
    case "link_card":
      return readString(pickNestedPayload(decoded, "link_card"), "title") || resolveFlareMessage(locale, "preview.link");
    case "forward": {
      const forward = pickNestedPayload(decoded, "forward");
      const items = readArray(forward, "items").length ? readArray(forward, "items") : readArray(root, "items");
      if (items.length > 1) return resolveFlareMessage(locale, "preview.forwardCount", { count: items.length });
      if (items.length === 1) {
        const first = asRecord(items[0]);
        return formatPreviewText(readString(first, "plainText", "text"), locale) || resolveFlareMessage(locale, "preview.forward");
      }
      return readString(forward, "title") || resolveFlareMessage(locale, "preview.forward");
    }
    case "thread":
      return readString(pickNestedPayload(decoded, "thread"), "threadTitle", "title") || resolveFlareMessage(locale, "preview.thread");
    case "mini_program":
      return readString(pickNestedPayload(decoded, "mini_program"), "title") || resolveFlareMessage(locale, "preview.miniProgram");
    case "image_group":
      return resolveFlareMessage(locale, "preview.imageGroupCount", { count: readArray(pickNestedPayload(decoded, "image_group"), "images").length || readArray(root, "images").length });
    case "system":
      return readString(pickNestedPayload(decoded, "system"), "body", "text") || resolveFlareMessage(locale, "preview.system");
    case "notification":
      return (
        readString(pickNestedPayload(decoded, "notification"), "body", "text") ||
        readString(pickNestedPayload(decoded, "notification"), "title") ||
        resolveFlareMessage(locale, "preview.notification")
      );
    case "vote":
      return resolveFlareMessage(locale, "preview.vote");
    case "task":
      return readString(pickNestedPayload(decoded, "task"), "title") || resolveFlareMessage(locale, "preview.task");
    case "schedule":
      return readString(pickNestedPayload(decoded, "schedule"), "title") || resolveFlareMessage(locale, "preview.schedule");
    case "announcement":
      return readString(pickNestedPayload(decoded, "announcement"), "title", "body") || resolveFlareMessage(locale, "preview.announcement");
    case "custom":
      return readString(pickNestedPayload(decoded, "custom"), "description", "text") || resolveFlareMessage(locale, "preview.custom");
    case "placeholder":
      return readString(pickNestedPayload(decoded, "placeholder"), "fallbackText") || resolveFlareMessage(locale, "preview.placeholder");
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
    if (!key) return { kind: "text", text: resolveFlareMessage(locale, "preview.emoji") };
    return { kind: "emoji", key, label: emojiPackLabel(key, locale) };
  }
  if (type === "sticker") {
    const sticker = pickNestedPayload(elem, "sticker");
    return {
      kind: "sticker",
      label: resolveFlareMessage(locale, "preview.stickerLabel"),
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
      return textPreview(joinText(readString(args, "title"), readString(args, "body"), readString(args, "markdown")) || resolveFlareMessage(locale, "preview.richText"));
    case "im.preview.file": {
      const name = readString(args, "n");
      return textPreview(name ? resolveFlareMessage(locale, "preview.fileNamed", { name }) : resolveFlareMessage(locale, "preview.file"));
    }
    case "im.preview.image":
      return textPreview(readBool(args, "m") ? resolveFlareMessage(locale, "preview.gif") : readString(args, "d") || resolveFlareMessage(locale, "preview.image"));
    case "im.preview.video":
      return textPreview(readString(args, "d") || resolveFlareMessage(locale, "preview.video"));
    case "im.preview.audio":
      return textPreview(readString(args, "d") || resolveFlareMessage(locale, "preview.audio"));
    case "im.preview.location":
      return textPreview(readString(args, "label") ? resolveFlareMessage(locale, "preview.locationNamed", { label: readString(args, "label") }) : resolveFlareMessage(locale, "preview.location"));
    case "im.preview.card":
      return textPreview(readString(args, "label") ? resolveFlareMessage(locale, "preview.cardNamed", { label: readString(args, "label") }) : resolveFlareMessage(locale, "preview.card"));
    case "im.preview.sticker":
      return {
        kind: "sticker",
        label: resolveFlareMessage(locale, "preview.stickerLabel"),
        stickerId: readString(args, "sid", "stickerId", "sticker_id", "id", "s"),
        packageId: readString(args, "pid", "packageId", "package_id"),
        url: readString(args, "u", "url"),
      };
    case "im.preview.emoji":
      return emojiPreviewVisual(args, locale);
    case "im.preview.quote":
      return textPreview(storedPreviewPayloadText(asRecord(args.inner) as StoredPreviewPayload, locale) || resolveFlareMessage(locale, "preview.quote"));
    case "im.preview.link":
      return textPreview(readString(args, "t") || resolveFlareMessage(locale, "preview.link"));
    case "im.preview.forward_empty":
      return textPreview(resolveFlareMessage(locale, "preview.forward"));
    case "im.preview.forward_many": {
      const count = readNumber(args, 0, "n");
      return textPreview(count > 0 ? resolveFlareMessage(locale, "preview.forwardCount", { count }) : resolveFlareMessage(locale, "preview.forward"));
    }
    case "im.preview.thread":
      return textPreview(readString(args, "t") || resolveFlareMessage(locale, "preview.thread"));
    case "im.preview.mini_program":
      return textPreview(readString(args, "t") || resolveFlareMessage(locale, "preview.miniProgram"));
    case "im.preview.image_group":
      return textPreview(resolveFlareMessage(locale, "preview.imageGroup"));
    case "im.preview.system":
      return textPreview(
        readString(args, "fb", "t", "body", "title")
          || resolveSystemEventText(args, locale)
          || resolveFlareMessage(locale, "preview.system"),
      );
    case "im.preview.notification":
      return textPreview(
        readString(args, "fb", "body", "title")
          || resolveSystemEventText(args, locale)
          || resolveFlareMessage(locale, "preview.notification"),
      );
    case "im.preview.vote":
      return textPreview(resolveFlareMessage(locale, "preview.vote"));
    case "im.preview.task":
      return textPreview(readString(args, "t") || resolveFlareMessage(locale, "preview.task"));
    case "im.preview.schedule":
      return textPreview(resolveFlareMessage(locale, "preview.schedule"));
    case "im.preview.announcement":
      return textPreview(readString(args, "t") || resolveFlareMessage(locale, "preview.announcement"));
    case "im.preview.custom":
      return textPreview(readString(args, "d") || resolveFlareMessage(locale, "preview.custom"));
    case "im.preview.placeholder":
      return textPreview(readString(args, "t") || resolveFlareMessage(locale, "preview.placeholder"));
    case "im.preview.unknown":
      return textPreview(resolveFlareMessage(locale, "preview.unknown"));
    default:
      return null;
  }
}

function textPreview(text: string): MessagePreviewVisual | null {
  const t = markdownToPlainText(text).trim();
  return t ? { kind: "text", text: t } : null;
}

/**
 * Localize a social system/notification event whose stored preview token has no `fb` string, by
 * mapping its event key (`ek`, e.g. `group.member_kicked`) to `systemEvent.<ek>` in the i18n catalog.
 * Returns "" when the event is unknown so callers fall back to the generic system/notification label
 * instead of leaking the raw internal key.
 */
function resolveSystemEventText(args: Record<string, unknown>, locale?: string): string {
  const ek = readString(args, "ek").trim();
  if (!ek) return "";
  const key = `systemEvent.${ek}`;
  const resolved = resolveFlareMessage(locale, key);
  return resolved === key ? "" : resolved;
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
  if (!visual) return resolveFlareMessage(locale, "preview.emoji");
  return visual.kind === "emoji" ? visual.label : visual.text;
}

function emojiPreviewVisual(
  args: Record<string, unknown>,
  locale?: string,
): Extract<MessagePreviewVisual, { kind: "text" | "emoji" }> {
  const key = readString(args, "e", "emoji", "key");
  if (!key) return { kind: "text", text: resolveFlareMessage(locale, "preview.emoji") };
  return { kind: "emoji", key, label: emojiPackLabel(key, locale) };
}
