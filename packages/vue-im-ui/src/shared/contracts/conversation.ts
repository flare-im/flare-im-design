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

// ── 会话列表筛选 ────────────────────────────────────────────────────────────────
/**
 * 一条长会话列表上「只看需要我处理的」那组开关。四端同一张表、同一条判定：
 * 筛选的口径要是跨端契约，否则同一个「未读」在两个端上给出两份不同的列表。
 *
 * 只用行模型本身有的字段（`unreadCount` / `mentioned`），不引入新的行字段 ——
 * 「群聊」这类筛选要先给行模型加 `kind`，那是四端一起改的事，这里先不开。
 */
export type FlareConversationFilterId = "all" | "unread" | "mentioned";

export const FLARE_CONVERSATION_FILTER_IDS: readonly FlareConversationFilterId[] = [
  "all",
  "unread",
  "mentioned",
];

/**
 * 这一行是否落在这个筛选里。
 *
 * 「未读」**包含**免打扰的会话：角标问的是「有什么在叫我」（免打扰的不叫），
 * 筛选问的是「哪些我还没读」—— 是两个问题，把免打扰从筛选里去掉会让人找不到
 * 自己明明没读过的那条。
 */
export function flareConversationMatchesFilter(
  row: Pick<FlareConversationRowModel, "unreadCount" | "mentioned">,
  filter: FlareConversationFilterId,
): boolean {
  if (filter === "unread") return (row.unreadCount ?? 0) > 0;
  if (filter === "mentioned") return Boolean(row.mentioned);
  return true;
}

/** 按筛选取子集；`all` 原样返回，不复制数组。 */
export function flareFilterConversations<T extends Pick<FlareConversationRowModel, "unreadCount" | "mentioned">>(
  rows: readonly T[],
  filter: FlareConversationFilterId,
): readonly T[] {
  if (filter === "all") return rows;
  return rows.filter((row) => flareConversationMatchesFilter(row, filter));
}
