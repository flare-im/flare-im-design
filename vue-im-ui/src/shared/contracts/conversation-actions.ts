/**
 * ConversationActionSheet contract — pure logic shared by the four platforms.
 * The host supplies a conversation snapshot plus the capabilities it can honour;
 * the component renders exactly the actions this function returns, in this order.
 */
export type ConversationActionId =
  | "pin"
  | "unpin"
  | "mute"
  | "unmute"
  | "markRead"
  | "archive"
  | "unarchive"
  | "hide"
  | "delete";

/** Snapshot of the conversation the sheet acts on; `id` must be stable. */
export interface ConversationActionSnapshot {
  id: string;
  title: string;
  pinned?: boolean;
  muted?: boolean;
  unreadCount?: number;
  archived?: boolean;
}

/** Capabilities the host can honour. Absent/false → the action is not rendered. */
export interface ConversationActionCapabilities {
  pin?: boolean;
  mute?: boolean;
  markRead?: boolean;
  archive?: boolean;
  delete?: boolean;
  hide?: boolean;
}

/** Semantic icon key; each platform maps it to its own glyph source. */
export type ConversationActionIcon =
  | "pin"
  | "unpin"
  | "mute"
  | "unmute"
  | "markRead"
  | "archive"
  | "unarchive"
  | "hide"
  | "delete";

export interface ConversationActionEntry {
  action: ConversationActionId;
  icon: ConversationActionIcon;
  /** Destructive actions render in the trailing danger group. */
  danger: boolean;
}

/**
 * Ordered, displayable actions for `conversation` under `capabilities`.
 * pin/unpin, mute/unmute and archive/unarchive are mutually exclusive by state;
 * markRead only when there is something unread; delete always last (danger).
 */
export function conversationActions(
  conversation: ConversationActionSnapshot,
  capabilities: ConversationActionCapabilities | null | undefined,
): ConversationActionEntry[] {
  const caps = capabilities ?? {};
  const out: ConversationActionEntry[] = [];
  if (caps.pin) {
    const action = conversation.pinned ? "unpin" : "pin";
    out.push({ action, icon: action, danger: false });
  }
  if (caps.mute) {
    const action = conversation.muted ? "unmute" : "mute";
    out.push({ action, icon: action, danger: false });
  }
  if (caps.markRead && (conversation.unreadCount ?? 0) > 0) {
    out.push({ action: "markRead", icon: "markRead", danger: false });
  }
  if (caps.archive) {
    const action = conversation.archived ? "unarchive" : "archive";
    out.push({ action, icon: action, danger: false });
  }
  if (caps.hide) {
    out.push({ action: "hide", icon: "hide", danger: false });
  }
  if (caps.delete) {
    out.push({ action: "delete", icon: "delete", danger: true });
  }
  return out;
}

/** Payload of the `action` event. */
export interface ConversationActionPayload {
  id: string;
  action: ConversationActionId;
}
