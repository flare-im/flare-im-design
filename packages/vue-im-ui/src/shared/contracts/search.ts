// Global-search result contracts (Contacts / Groups / Messages).

export type FlareSearchResultKind = "contact" | "group" | "message";

/** Where opening a result leads. A message result names its conversation and the message. */
export interface FlareSearchResultTarget {
  conversationId: string;
  /** The message to show, as `resolveMessageId` gives it. */
  messageId?: string;
}

export interface FlareSearchResultItem {
  /** The result's own id (contact user, group, or message); unique within its kind. */
  id: string;
  kind: FlareSearchResultKind;
  /** Primary line — contact / group name, or the message sender. */
  title: string;
  /** Secondary line — signature, member count, or the matched snippet. */
  subtitle?: string;
  avatarUrl?: string;
  /** Right-aligned meta (e.g. a message timestamp). */
  meta?: string;
  target?: FlareSearchResultTarget;
}

export interface FlareSearchResultGroup {
  kind: FlareSearchResultKind;
  /** Localized section header ("联系人" / "群聊" / "聊天记录"). */
  label: string;
  items: FlareSearchResultItem[];
  /** Total matches when the list is truncated — renders a "查看全部 N" row. */
  total?: number;
  /**
   * The list is truncated and the host does not know by how much (a search API that takes a limit and
   * returns no count: ask for one more than is shown). Renders a "查看更多" row that reports `viewAll`.
   * `total` wins when both are given; a count is never made up to get the row.
   */
  hasMore?: boolean;
}
