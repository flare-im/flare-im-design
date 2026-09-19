import type { FlareConversationRowModel } from "./conversation";

/** Cross-platform precedence, also exercised by spec/conversation-state-vectors.json. */
export function conversationPreviewKind(item: Pick<FlareConversationRowModel, "failed" | "draft" | "typing" | "mentioned">) {
  if (item.failed) return "failed";
  if (item.draft?.trim()) return "draft";
  if (item.typing) return "typing";
  if (item.mentioned) return "mention";
  return "normal";
}

export function conversationUnreadCount(count = 0): number {
  return Number.isFinite(count) ? Math.max(0, Math.floor(count)) : 0;
}

/** Title weight tier. Strong only when the row needs attention: unread and not quiet (muted without a mention). Same rule as the unread count. */
export function conversationTitleEmphasis(item: Pick<FlareConversationRowModel, "unreadCount" | "muted" | "mentioned">): "strong" | "quiet" {
  if (conversationUnreadCount(item.unreadCount) === 0) return "quiet";
  return item.muted && !item.mentioned ? "quiet" : "strong";
}

export function conversationUnreadLabel(count = 0): string {
  const value = conversationUnreadCount(count);
  return value > 999 ? "999+" : String(value);
}
