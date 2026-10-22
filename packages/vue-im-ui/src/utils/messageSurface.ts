import { messageContentTypeForUi } from "./messageContent";
import type { MessageLike } from "../shared/contracts/messageRow";
import { resolveLoneEmojiPackInText } from "../components/composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { isMarkdown } from "./markdown";
import {
  normalizeToContentElem,
  pickNestedPayload,
  textBodyFromContent,
  type ContentElem,
} from "./contentElem";
import { readString } from "./contentData";
import { messageRendererKeys } from "./messageRendererKeys";
import {
  flareMessageSurface,
  type FlareMessageRegisteredSurface,
  type FlareMessageSurface,
  type FlareMessageSurfaceInput,
} from "../shared/contracts/message-surface";
import { resolveFlareMessageRenderer, type FlareMessageRendererRegistry } from "../shared/message-renderers";

function hasQuote(message: MessageLike): boolean {
  return Boolean(message.replyTo?.trim() || message.quotePreview?.trim());
}

function textPayloadHasMentions(content: ContentElem): boolean {
  const nested = content.text;
  if (nested == null || typeof nested === "string") return false;
  const mentions = (nested as { mentions?: unknown }).mentions;
  return Array.isArray(mentions) && mentions.length > 0;
}

function mediaDescription(content: ContentElem, nestedKey: string): string {
  const nested = pickNestedPayload(content, nestedKey);
  const payload = Object.keys(nested).length ? nested : content;
  return readString(payload, "description", "caption");
}

function isLoneEmojiText(content: ContentElem): boolean {
  if (textPayloadHasMentions(content)) return false;
  const raw = textBodyFromContent(content);
  if (!raw || isMarkdown(raw)) return false;
  return resolveLoneEmojiPackInText(raw) != null;
}

/** The surface facts of a message row (spec/message-surface-vectors.json inputs). */
export function messageSurfaceInput(
  message: MessageLike,
  registered?: FlareMessageRegisteredSurface,
): FlareMessageSurfaceInput {
  const content = normalizeToContentElem(message.content);
  const contentType = messageContentTypeForUi(content?.contentType ?? message.content?.contentType ?? "text");
  return {
    contentType,
    subtype: typeof content?.type === "string" ? content.type : undefined,
    hasQuote: hasQuote(message),
    hasCaption: content && contentType === "video" ? mediaDescription(content, "video").length > 0 : false,
    loneEmoji: content && contentType === "text" ? isLoneEmojiText(content) : false,
    recalled: message.isRecalled,
    deleted: message.lifecycle?.mutation === "deleted",
    registered,
  };
}

/** The surface the host registered for this message's content key, most specific key first. */
export function registeredMessageSurface(
  message: MessageLike,
  registry: FlareMessageRendererRegistry,
): FlareMessageRegisteredSurface | undefined {
  const keys = messageRendererKeys(normalizeToContentElem(message.content));
  return resolveFlareMessageRenderer(registry, keys)?.surface;
}

/** The surface a timeline row draws its content on (C1), from the message and the host's renderer registry. */
export function messageSurfaceOf(message: MessageLike, registry: FlareMessageRendererRegistry = {}): FlareMessageSurface {
  return flareMessageSurface(messageSurfaceInput(message, registeredMessageSurface(message, registry)));
}
