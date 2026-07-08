import { asRecord } from "./contentData";
import { buildUiTaggedMessageContent, messageContentTypeForUi } from "./messageContent";

export type MessageContentLike = {
  contentType?: string;
  data?: Record<string, unknown>;
};

export type ContentElem = Record<string, unknown> & {
  contentType: string;
};

export function normalizeToContentElem(content?: MessageContentLike | null): ContentElem | null {
  if (!content?.contentType) return null;
  try {
    const ui = buildUiTaggedMessageContent({
      contentType: content.contentType,
      data: content.data ?? {},
    });
    return ui as ContentElem;
  } catch {
    return {
      contentType: messageContentTypeForUi(content.contentType),
      ...content.data,
    } as ContentElem;
  }
}

export function pickNestedPayload(content: ContentElem, key: string): Record<string, unknown> {
  const nested = content[key];
  if (nested && typeof nested === "object" && !Array.isArray(nested)) {
    return asRecord(nested);
  }
  return {};
}

export function messageExtraAsStrings(extra?: Record<string, unknown>): Record<string, string> {
  const out: Record<string, string> = {};
  if (!extra) return out;
  for (const [key, value] of Object.entries(extra)) {
    if (value == null) continue;
    out[key] = typeof value === "string" ? value : String(value);
  }
  return out;
}

export function textBodyFromContent(content: ContentElem): string {
  if (content.contentType !== "text") return "";
  const nested = pickNestedPayload(content, "text");
  const rootArgs = asRecord(content.args ?? content.a);
  const nestedArgs = asRecord(nested.args ?? nested.a);
  for (const value of [
    content.text,
    content.body,
    content.plainText,
    content.t,
    rootArgs.text,
    rootArgs.t,
    nested.text,
    nested.body,
    nested.plainText,
    nested.t,
    nestedArgs.text,
    nestedArgs.t,
  ]) {
    const text = decodedTextValue(value);
    if (text) return text;
  }
  return "";
}

function decodedTextValue(value: unknown): string {
  if (typeof value !== "string") return "";
  const trimmed = value.trim();
  if (!trimmed) return "";
  if (!trimmed.startsWith("{")) return trimmed;
  try {
    const parsed = asRecord(JSON.parse(trimmed));
    const args = asRecord(parsed.args ?? parsed.a);
    for (const candidate of [parsed.text, parsed.t, args.text, args.t]) {
      if (typeof candidate === "string" && candidate.trim()) return candidate.trim();
    }
  } catch {
    return trimmed;
  }
  return trimmed;
}
