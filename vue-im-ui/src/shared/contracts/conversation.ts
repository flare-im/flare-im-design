import type { MessageContentLike } from "../../utils/contentElem";

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
