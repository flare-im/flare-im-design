import type { ContentElem } from "./contentElem";

/** Wire content types whose view key differs from the wire name. */
export const CONTENT_TYPE_VIEW_KEYS: Readonly<Record<string, string>> = {
  image_group: "imageGroup",
  link_card: "linkCard",
  mini_program: "miniProgram",
  rich_text: "richText",
};

/** The key the built-in views and the renderer registry know a content by (`image_group` → `imageGroup`). */
export function contentViewKey(content: ContentElem | null | undefined): string {
  const type = content?.contentType;
  if (!type) return "";
  return CONTENT_TYPE_VIEW_KEYS[type] ?? type;
}

/**
 * The registry keys a content answers to, most specific first: `contentType:subtype`, the wire
 * type, then the view key. The content view and the bubble resolve a renderer through the same
 * list, so a renderer registered `bare` loses its bubble exactly where it is drawn.
 */
export function messageRendererKeys(content: ContentElem | null | undefined): string[] {
  if (!content) return [];
  const wireType = String(content.contentType ?? "");
  const subtype = typeof content.type === "string" ? content.type : "";
  return [`${wireType}:${subtype}`, wireType, contentViewKey(content)];
}
