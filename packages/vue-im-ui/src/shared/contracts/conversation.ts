import type { MessageContentLike } from "../../utils/contentElem";

/**
 * What a conversation is, in one vocabulary for every component and kit (FR-056): the three the
 * native kits always had (`single`, `group`, `ai`), plus the two the header could express on its own
 * (`channel`, `system`). Nothing in the kit reads an SDK code; a host maps its own words to these.
 */
export type FlareConversationKind = "single" | "group" | "channel" | "ai" | "system";

/** Tone for a small inline title tag (group / bot / official markers). */
export type FlareConversationRowTagTone = "info" | "warning" | "neutral";

/** A small inline label next to a conversation title (e.g. "Group", "Bot", "Official"). */
export interface FlareConversationRowTag {
  text: string;
  tone?: FlareConversationRowTagTone;
}

/** Package-owned conversation row view state with no host runtime coupling. */
export interface FlareConversationRowModel {
  id: string;
  displayName?: string;
  avatarUrl?: string;
  updatedAt?: number | string;
  /** Host-formatted, locale/timezone-aware time; preferred over updatedAt. */
  timestampLabel?: string;
  unreadCount?: number;
  lastMessagePreview?: string;
  previewPending?: boolean;
  draft?: string;
  mentioned?: boolean;
  typing?: boolean;
  failed?: boolean;
  lastMessage?: {
    text?: string;
    time?: number | string;
    content?: MessageContentLike | null;
  } | null;
  pinned?: boolean;
  muted?: boolean;
  archived?: boolean;
  /** Legacy metadata retained for adapters; the compact row does not render tag chips. */
  tags?: FlareConversationRowTag[];
}

/** A visual section inside a conversation list. The kit owns section layout. */
export interface FlareConversationListSection {
  id: string;
  label?: string;
  items: FlareConversationRowModel[];
}

/** A forward destination — a conversation the user can forward messages into. */
export interface FlareForwardTarget {
  id: string;
  name: string;
  avatarUrl?: string;
  /** Secondary line — member count, @handle, or "Group". */
  subtitle?: string;
}

export type FlareConversationFilter =
  | "all"
  | "unread"
  | "mention"
  | "pinned"
  | "muted"
  | "archived"
  | "draft";

/**
 * Structural view of a conversation for ConversationDetails — the subset of the
 * conversation data the pane reads. Hosts pass any object with these fields;
 * the kit has no transport or persistence type dependency.
 */
export interface FlareConversationDetailsModel {
  conversationId: string;
  /** Routing id: peer user id for direct chats, business channel id for groups. */
  channelId?: string;
  displayName?: string;
  conversationKind?: FlareConversationKind;
  avatarUrl?: string;
  membersCount?: number;
  unreadCount?: number;
  isPinned?: boolean;
  isMuted?: boolean;
  isArchived?: boolean;
}
