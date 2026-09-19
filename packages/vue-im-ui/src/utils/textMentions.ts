import { asRecord } from "./contentData";
import { pickNestedPayload, type ContentElem } from "./contentElem";

/** A mention inside a text body, as UTF-16 offsets into the rendered text. */
export interface FlareTextMentionSpan {
  start: number;
  length: number;
  /** Mentions the current user. */
  self: boolean;
  /** Mentions everyone (@all). */
  all: boolean;
}

// flare-proto MentionType: 1 user · 2 all · 3 role · 4 multi.
const MENTION_ALL = 2;

/**
 * Mention spans of a text content element. The core carries offsets in Unicode characters;
 * they are converted to string indices here. A span that does not land on an "@" token is
 * dropped rather than highlighting the wrong words.
 */
export function textMentionSpans(content: ContentElem, text: string, currentUserId = ""): FlareTextMentionSpan[] {
  const nested = pickNestedPayload(content, "text");
  const raw = Array.isArray(content.mentions) ? content.mentions : Array.isArray(nested.mentions) ? nested.mentions : [];
  if (!raw.length || !text) return [];
  const chars = Array.from(text);
  const utf16Offset = (index: number) => chars.slice(0, index).join("").length;
  const spans: FlareTextMentionSpan[] = [];
  for (const entry of raw) {
    const mention = asRecord(entry);
    const start = Number(mention.start);
    const length = Number(mention.length);
    if (!Number.isInteger(start) || !Number.isInteger(length) || start < 0 || length < 2 || start + length > chars.length) continue;
    const from = utf16Offset(start);
    const to = utf16Offset(start + length);
    if (text[from] !== "@") continue;
    const ids = [mention.userId, ...(Array.isArray(mention.userIds) ? mention.userIds : [])].map((id) => String(id ?? ""));
    spans.push({
      start: from,
      length: to - from,
      all: Number(mention.type) === MENTION_ALL,
      self: Boolean(currentUserId) && ids.includes(currentUserId),
    });
  }
  spans.sort((a, b) => a.start - b.start);
  // Compare with the last span kept, not the previous one in order: a dropped span must not
  // hide the next one (A 0-3, B 1-4 dropped, C 3-6 kept).
  const kept: FlareTextMentionSpan[] = [];
  for (const span of spans) {
    const last = kept[kept.length - 1];
    if (!last || span.start >= last.start + last.length) kept.push(span);
  }
  return kept;
}

export interface FlareTextSegment {
  text: string;
  mention?: FlareTextMentionSpan;
}

/** Splits text into plain runs and mention runs. */
export function segmentTextByMentions(text: string, spans: readonly FlareTextMentionSpan[]): FlareTextSegment[] {
  const segments: FlareTextSegment[] = [];
  let cursor = 0;
  for (const span of spans) {
    if (span.start > cursor) segments.push({ text: text.slice(cursor, span.start) });
    segments.push({ text: text.slice(span.start, span.start + span.length), mention: span });
    cursor = span.start + span.length;
  }
  if (cursor < text.length) segments.push({ text: text.slice(cursor) });
  return segments;
}
