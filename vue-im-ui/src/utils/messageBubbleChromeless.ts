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

function displayContent(message: MessageLike): ContentElem | null {
  return normalizeToContentElem(message.content);
}

function hasQuote(message: MessageLike): boolean {
  return Boolean(message.replyTo?.trim() || message.quotePreview?.trim());
}

function textPayloadHasMentions(content: ContentElem): boolean {
  if (content.contentType !== "text") return false;
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

const CHROMELESS_CARD_TYPES = new Set([
  "location",
  "card",
  "link_card",
  "forward",
  "thread",
  "mini_program",
  "vote",
  "task",
  "schedule",
  "announcement",
  "custom",
]);

/** 媒体消息由内容决定外观：纯单图/单视频裸露；有描述或多图由气泡承载上下文。 */
export function isChromelessMediaBubble(message: MessageLike): boolean {
  if (message.isRecalled || hasQuote(message)) return false;
  const content = displayContent(message);
  if (!content) return false;
  const type = messageContentTypeForUi(content.contentType);
  if (type === "emoji" || type === "sticker") return true;
  if (type === "image") return true;
  if (type === "video") return mediaDescription(content, "video").length === 0;
  if (type === "image_group") return false;
  if (type !== "text") return false;
  if (textPayloadHasMentions(content)) return false;
  const raw = textBodyFromContent(content);
  if (!raw || isMarkdown(raw)) return false;
  return resolveLoneEmojiPackInText(raw) != null;
}

/** 自带边框与背景的富消息卡片，外层气泡只负责对齐、状态与菜单锚点。 */
export function isChromelessCardBubble(message: MessageLike): boolean {
  if (message.isRecalled || hasQuote(message)) return false;
  const content = displayContent(message);
  if (!content) return false;
  return CHROMELESS_CARD_TYPES.has(messageContentTypeForUi(content.contentType));
}
