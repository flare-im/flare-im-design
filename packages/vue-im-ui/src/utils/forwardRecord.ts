/**
 * A merged-forward record (chat history card) as ForwardView draws it — the shape the native kits copy
 * (spec/message-forward-vectors.json, dataTypes ForwardContent). Input is the core's forward content: the nested
 * `forward` payload, or a serde-flattened root carrying `items` / `mode` / `title`.
 */
import type { ContentElem } from "./contentElem";
import { pickNestedPayload } from "./contentElem";
import { asRecord, readArray, readNumber, readString } from "./contentData";
import { getContentDecodedPreview } from "./messagePreview";
import { currentFlareRuntimeLocale, resolveFlareMessage } from "../shared/i18n/messages";

export type FlareForwardItemRecord = Record<string, unknown>;

export interface FlareForwardRecordView {
  /** empty: no items; single: one item that is not a merged record, drawn inline; card: the record card. */
  layout: "empty" | "single" | "card";
  items: ReadonlyArray<FlareForwardItemRecord>;
  title: string;
  /** "共 N 条消息" when the record holds more than one message. */
  subtitle: string | null;
  /** The first three messages as "sender: text". */
  previews: ReadonlyArray<{ sender: string; text: string }>;
  /** "还有 N 条消息…" past the first three. */
  more: string | null;
  hint: string;
  /** The card's accessible name. */
  label: string;
  drawerTitle: string;
}

/** How many preview lines the card shows. */
export const FLARE_FORWARD_PREVIEW_LIMIT = 3;

/** The forward payload of a content: the nested `forward` object, else the content itself. */
export function flareForwardPayload(content: ContentElem | null | undefined): Record<string, unknown> {
  if (!content) return {};
  const nested = pickNestedPayload(content, "forward");
  return Object.keys(nested).length ? nested : (content as Record<string, unknown>);
}

/** A forwarded message's sender label: its name, else "unknown sender" — an account id is internal and never shown. */
export function flareForwardSender(item: FlareForwardItemRecord, locale: string = currentFlareRuntimeLocale()): string {
  return readString(item, "sourceSenderName").trim() || resolveFlareMessage(locale, "forward.unknownSender");
}

/** A forwarded message's content: its own, else its plain text as a text body. */
export function flareForwardItemContent(item: FlareForwardItemRecord): ContentElem {
  const content = asRecord(item.content);
  if (readString(content, "contentType").trim()) return content as ContentElem;
  const plain = readString(item, "plainText").trim();
  return { contentType: "text", text: { text: plain, mentions: [] } } as ContentElem;
}

/**
 * A forwarded message's initial for the drawer avatar: the first character of its sender's name, upper-cased, else
 * "?" — never the first character of "unknown sender".
 */
export function flareForwardSenderInitial(item: FlareForwardItemRecord): string {
  const first = Array.from(readString(item, "sourceSenderName").trim())[0];
  return first ? first.toUpperCase() : "?";
}

/**
 * A forwarded message's one-line summary: its plain text — the core's words for it, read as any text body's summary is
 * (Markdown to plain text, emoji-pack keys in the reader's language) — else its content's summary, else "[转发]".
 */
export function flareForwardPreviewLine(item: FlareForwardItemRecord, locale: string = currentFlareRuntimeLocale()): string {
  const words = readString(item, "plainText").trim();
  const plain = words
    ? getContentDecodedPreview({ contentType: "text", text: { text: words, mentions: [] } } as ContentElem, locale).trim()
    : "";
  if (plain) return plain;
  const content = asRecord(item.content);
  if (readString(content, "contentType").trim()) {
    const summary = getContentDecodedPreview(content as ContentElem, locale).trim();
    if (summary) return summary;
  }
  return resolveFlareMessage(locale, "preview.forward");
}

/** What the record shows (spec/message-forward-vectors.json). */
export function flareForwardRecordView(
  content: ContentElem | null | undefined,
  locale: string = currentFlareRuntimeLocale(),
): FlareForwardRecordView {
  const t = (key: string, params?: Record<string, string | number>) => resolveFlareMessage(locale, key, params);
  const payload = flareForwardPayload(content);
  const items = readArray(payload, "items").map(asRecord);
  const count = items.length;
  // ForwardMode: 1 single, 2 merged, 0 unspecified (inferred from the count).
  const merged = readNumber(payload, 0, "mode") === 2;
  const layout = count === 0 ? "empty" : count === 1 && !merged ? "single" : "card";
  const title = readString(payload, "title").trim() || t("forward.merged");
  const subtitle = count > 1 ? t("forward.totalMessages", { count }) : null;
  return {
    layout,
    items,
    title,
    subtitle,
    previews: items.slice(0, FLARE_FORWARD_PREVIEW_LIMIT).map((item) => ({
      sender: flareForwardSender(item, locale),
      text: flareForwardPreviewLine(item, locale),
    })),
    more: count > FLARE_FORWARD_PREVIEW_LIMIT ? t("forward.moreMessages", { count: count - FLARE_FORWARD_PREVIEW_LIMIT }) : null,
    hint: t("forward.viewDetail"),
    label: subtitle ? t("forward.cardLabel", { title, subtitle }) : title,
    drawerTitle: `${title}${t("forward.countSuffix", { count })}`,
  };
}
