/**
 * The receipt the core SDK projects for a message (MessageReceiptView {status, readSummary?}) and the row's
 * accessible name (docs/design/message-surface-and-meta.md C3 / §6). Pure rules, tested against
 * spec/message-receipt-vectors.json by all four kits.
 */
import type { FlareConversationKind } from "./conversation";
import type { MessageStatusState } from "./message-lifecycle";

/** Group read summary of the viewer's own message; empty for conversations above the large-group threshold. */
export interface FlareMessageReadSummary {
  readCount: number;
  unreadCount: number;
  total: number;
}

export type FlareMessageReceiptGlyph = "clock" | "spinner" | "check" | "doubleCheck" | "alert";

export interface FlareMessageReceiptPresentation {
  /** The status glyph, or null when there is none (incoming) or the read summary replaces it. */
  glyph: FlareMessageReceiptGlyph | null;
  /** The read summary line: unread count, or all read. */
  summary: { allRead: boolean; count: number | null } | null;
}

const GLYPHS: Readonly<Record<MessageStatusState, FlareMessageReceiptGlyph>> = {
  pending: "clock",
  sending: "spinner",
  sent: "check",
  read: "doubleCheck",
  failed: "alert",
};

export function flareMessageReceiptPresentation(input: {
  conversationKind?: FlareConversationKind;
  self: boolean;
  status: MessageStatusState;
  readSummary?: FlareMessageReadSummary | null;
}): FlareMessageReceiptPresentation {
  if (!input.self) return { glyph: null, summary: null };
  const summary = input.readSummary;
  if (input.conversationKind === "group" && summary && (input.status === "sent" || input.status === "read")) {
    const unread = Math.max(0, Math.floor(summary.unreadCount));
    return { glyph: null, summary: unread > 0 ? { allRead: false, count: unread } : { allRead: true, count: null } };
  }
  return { glyph: GLYPHS[input.status] ?? "check", summary: null };
}

/**
 * One reading unit per row: sender, content summary, time, then the status text or the read summary; empty parts
 * skipped, joined with the locale's list separator ("，" in Chinese, ", " elsewhere).
 */
export function flareMessageAccessibilityLabel(parts: ReadonlyArray<string | null | undefined>, locale: string): string {
  const separator = /^zh\b/i.test(locale) ? "，" : ", ";
  return parts.map((part) => (part ?? "").trim()).filter(Boolean).join(separator);
}
