import type { Component } from "vue";
import { flareIcons, type FlareIconName } from "../../shared/icons";
import type { ConversationActionIcon, FlareConversationAction } from "../../shared/contracts/conversation-actions";

/** One semantic icon per conversation action, shared by the row menu and ConversationActionSheet. */
export const conversationActionIconNames: Record<ConversationActionIcon, FlareIconName> = {
  pin: "pin",
  unpin: "unpin",
  mute: "mute",
  unmute: "notification",
  markRead: "read",
  markUnread: "mark-unread",
  archive: "archive",
  unarchive: "unarchive",
  hide: "eye-off",
  clearHistory: "clear-history",
  delete: "delete",
};

export const conversationActionGlyphs = Object.fromEntries(
  Object.entries(conversationActionIconNames).map(([action, name]) => [action, flareIcons[name]]),
) as Record<ConversationActionIcon, Component>;

/** The i18n key of an action label (`conversationActionSheet.*`). */
export function conversationActionLabelKey(action: FlareConversationAction): string {
  return `conversationActionSheet.${action}`;
}
