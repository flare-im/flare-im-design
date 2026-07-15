import type { MessageContentLike } from "../../utils/contentElem";

/** Tone for a small inline title tag (group / bot / official markers). */
export type FlareConversationRowTagTone = "info" | "warning" | "neutral";

/** A small inline label next to a conversation title (e.g. "Group", "Bot", "Official"). */
export interface FlareConversationRowTag {
  text: string;
  tone?: FlareConversationRowTagTone;
}

/** Package-owned conversation row view state (no SDK runtime coupling). */
export interface FlareConversationRowModel {
  id: string;
  displayName?: string;
  avatarUrl?: string;
  updatedAt?: number | string;
  unreadCount?: number;
  lastMessagePreview?: string;
  previewPending?: boolean;
  draft?: string;
  lastMessage?: {
    text?: string;
    time?: number | string;
    content?: MessageContentLike | null;
  } | null;
  pinned?: boolean;
  muted?: boolean;
  archived?: boolean;
  /** Inline title tags (group / role). Empty/absent by default. */
  tags?: FlareConversationRowTag[];
}

/** A forward destination — a conversation the user can forward messages into. */
export interface FlareForwardTarget {
  id: string;
  name: string;
  avatarUrl?: string;
  /** Secondary line — member count, @handle, or "Group". */
  subtitle?: string;
}

export type FlareConversationAction =
  | "open"
  | "mark_read"
  | "mark_unread"
  | "pin"
  | "unpin"
  | "mute"
  | "unmute"
  | "archive"
  | "unarchive"
  | "clear_history"
  | "delete";

export type FlareConversationFilter =
  | "all"
  | "unread"
  | "mention"
  | "pinned"
  | "muted"
  | "archived"
  | "draft";
