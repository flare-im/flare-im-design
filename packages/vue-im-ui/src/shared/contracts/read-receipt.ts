/**
 * The group read list (spec ReadReceiptSheet, spec/read-receipt-vectors.json): two columns that page on their own,
 * a whole-list state, and tab numbers taken from the summary the host passes — never from the rows loaded so far.
 */

/** The whole list: ready, being read, failed (retry), or not available for this message (no retry). */
export type FlareReadReceiptState = "ready" | "loading" | "error" | "unavailable";

/** A column of the read list. */
export type FlareReadReceiptColumn = "read" | "unread";

export interface FlareReadReceiptInput {
  state?: FlareReadReceiptState;
  /** Rows loaded so far in each column. */
  readers: number;
  unread: number;
  /** The summary counts (receipt.readSummary); absent: the tab shows no number. */
  readCount?: number | null;
  unreadCount?: number | null;
  readHasMore?: boolean;
  unreadHasMore?: boolean;
  loadingMore?: FlareReadReceiptColumn | null;
  loadMoreFailed?: FlareReadReceiptColumn | null;
  /** The column on screen. */
  tab: FlareReadReceiptColumn;
}

export interface FlareReadReceiptPresentation {
  /** The two tabs in order with the number each shows; null when no tabs are drawn. */
  tabs: ReadonlyArray<{ value: FlareReadReceiptColumn; count: number | null }> | null;
  body: "spinner" | "error" | "unavailable" | "list" | "empty";
  /** The column whose empty notice shows (body empty). */
  empty?: FlareReadReceiptColumn;
  rows: number;
  /** The last row of the list: nothing, a spinner, the load-more key, or the load-more-failed key. */
  tail: "none" | "busy" | "loadMore" | "retry";
}

const summaryCount = (value: number | null | undefined): number | null =>
  typeof value === "number" && Number.isFinite(value) && value >= 0 ? Math.floor(value) : null;

/** What the sheet draws for an input (spec/read-receipt-vectors.json). */
export function flareReadReceiptPresentation(input: FlareReadReceiptInput): FlareReadReceiptPresentation {
  const state = input.state ?? "ready";
  const tabs = [
    { value: "read" as const, count: summaryCount(input.readCount) },
    { value: "unread" as const, count: summaryCount(input.unreadCount) },
  ];
  if (state === "error" || state === "unavailable") return { tabs: null, body: state, rows: 0, tail: "none" };
  if (state === "loading") return { tabs, body: "spinner", rows: 0, tail: "none" };
  const column = input.tab;
  const rows = Math.max(0, column === "read" ? input.readers : input.unread);
  const hasMore = Boolean(column === "read" ? input.readHasMore : input.unreadHasMore);
  const tail = input.loadingMore === column
    ? "busy"
    : input.loadMoreFailed === column
      ? "retry"
      : hasMore ? "loadMore" : "none";
  if (rows === 0 && tail === "none") return { tabs, body: "empty", empty: column, rows: 0, tail };
  return { tabs, body: "list", rows, tail };
}
