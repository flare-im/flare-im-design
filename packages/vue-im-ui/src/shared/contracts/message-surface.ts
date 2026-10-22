/**
 * Which surface a timeline row draws its content on, and where its time and receipt sit
 * (docs/design/message-surface-and-meta.md C1 / C2). Pure rules, tested against
 * spec/message-surface-vectors.json and spec/message-meta-placement-vectors.json by all four kits.
 */
import type { MessageStatusState } from "./message-lifecycle";

export type FlareMessageSurface = "bubble" | "bareMedia" | "card" | "centered";
export type FlareMessageMetaPlacement = "inline" | "bubbleFooter" | "below" | "none";
/** A surface a host registers for a content key the kit does not know. */
export type FlareMessageRegisteredSurface = "card" | "bareMedia";

export interface FlareMessageSurfaceInput {
  /** Spec content type (`richText`, `linkCard`, ...); the wire spellings (`rich_text`, ...) are accepted too. */
  contentType: string;
  subtype?: string;
  /** The message replies to another one. */
  hasQuote?: boolean;
  /** A video with a non-blank description or caption. */
  hasCaption?: boolean;
  /** A text that is a single emoji (pack token or emoji), without mentions or markdown. */
  loneEmoji?: boolean;
  recalled?: boolean;
  deleted?: boolean;
  /** The surface the host registered for this content's key. */
  registered?: FlareMessageRegisteredSurface;
}

/** Wire spellings of the content types the spec writes in camelCase. */
const SPEC_TYPE: Readonly<Record<string, string>> = {
  rich_text: "richText",
  image_group: "imageGroup",
  link_card: "linkCard",
  mini_program: "miniProgram",
  voice: "audio",
};

const BUBBLE = new Set(["text", "richText", "audio", "file", "imageGroup", "quote", "placeholder"]);
const BARE_MEDIA = new Set(["image", "sticker", "emoji"]);
const CARD = new Set([
  "location", "card", "linkCard", "vote", "task", "schedule", "announcement", "miniProgram", "forward", "thread", "custom",
]);
const CENTERED = new Set(["system", "notification"]);

/** The spec name of a content type: `rich_text` → `richText`. */
export function flareSpecContentType(contentType: string): string {
  return SPEC_TYPE[contentType] ?? contentType;
}

/** The surface for a content (spec/message-surface-vectors.json rules.order). */
export function flareMessageSurface(input: FlareMessageSurfaceInput): FlareMessageSurface {
  const type = flareSpecContentType(input.contentType);
  if (input.recalled || input.deleted) return "centered";
  if (CENTERED.has(type)) return "centered";
  if (input.registered) return input.registered === "bareMedia" && input.hasQuote ? "bubble" : input.registered;
  if (input.hasQuote) return CARD.has(type) ? "card" : "bubble";
  if (type === "video") return input.hasCaption ? "bubble" : "bareMedia";
  if (type === "text") return input.loneEmoji ? "bareMedia" : "bubble";
  if (BARE_MEDIA.has(type)) return "bareMedia";
  if (CARD.has(type)) return "card";
  if (BUBBLE.has(type)) return "bubble";
  return "bubble";
}

/** Where the meta sits for a surface (spec/message-meta-placement-vectors.json rules.placement). */
export function flareMessageMetaPlacement(surface: FlareMessageSurface, contentType: string): FlareMessageMetaPlacement {
  if (surface === "centered") return "none";
  if (surface === "bareMedia" || surface === "card") return "below";
  return flareSpecContentType(contentType) === "text" ? "inline" : "bubbleFooter";
}

/** The meta palette: onOutgoing only inside an outgoing bubble that has not failed (rules.tone). */
export function flareMessageMetaTone(
  placement: FlareMessageMetaPlacement,
  self: boolean,
  status: MessageStatusState | undefined,
): "default" | "onOutgoing" {
  if (!self || status === "failed") return "default";
  return placement === "inline" || placement === "bubbleFooter" ? "onOutgoing" : "default";
}

/** The retry control of a failed outgoing message: the glyph inside a bubble, a text key below a surface (rules.failed). */
export function flareMessageRetryForm(
  placement: FlareMessageMetaPlacement,
  self: boolean,
  status: MessageStatusState | undefined,
): "glyph" | "text" | null {
  if (!self || status !== "failed" || placement === "none") return null;
  return placement === "below" ? "text" : "glyph";
}
