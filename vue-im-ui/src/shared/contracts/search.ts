// Global-search result contracts (Contacts / Groups / Messages).

export type FlareSearchResultKind = "contact" | "group" | "message";

export interface FlareSearchResultItem {
  id: string;
  kind: FlareSearchResultKind;
  /** Primary line — contact / group name, or the message sender. */
  title: string;
  /** Secondary line — signature, member count, or the matched snippet. */
  subtitle?: string;
  avatarUrl?: string;
  /** Right-aligned meta (e.g. a message timestamp). */
  meta?: string;
}

export interface FlareSearchResultGroup {
  kind: FlareSearchResultKind;
  /** Localized section header ("联系人" / "群聊" / "聊天记录"). */
  label: string;
  items: FlareSearchResultItem[];
  /** Total matches when the list is truncated — renders a "查看全部 N" row. */
  total?: number;
}
