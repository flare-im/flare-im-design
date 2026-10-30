import { computed, shallowRef, toValue, watch, type ComputedRef, type MaybeRefOrGetter, type ShallowRef } from "vue";
import type { FlareContact } from "../shared/contracts";
import type { FlareReadReceiptColumn, FlareReadReceiptState } from "../shared/contracts/read-receipt";

/**
 * The group read list's paging, without UI (spec/read-receipt-list-vectors.json): what a host keeps for
 * FlareReadReceiptSheet. The host gives one loader that reads a page of one column; the kit owns the rest — both first
 * pages on opening, a column's next page on `loadMore`, the whole-list state, the per-column busy and failed marks.
 * The kit calls no SDK: the loader maps the SDK's answer (names the user ids, turns "not offered" into null).
 */

/** A column as far as it is read: its people in order, and the next page's cursor while there is one. */
export interface FlareReadReceiptMembers {
  people: FlareContact[];
  nextCursor?: string;
}

/** The list: its state, both columns, and the column reading (or last failing to read) its next page. */
export interface FlareReadReceiptPages {
  state: FlareReadReceiptState;
  read: FlareReadReceiptMembers;
  unread: FlareReadReceiptMembers;
  loadingMore: FlareReadReceiptColumn | null;
  loadMoreFailed: FlareReadReceiptColumn | null;
}

/**
 * One page of `column` after `cursor` (the first page without one). Resolves null when the message's list is not
 * offered (the SDK's NOT_FOUND, `available: false`); throws on any other failure.
 */
export type FlareReadReceiptPageLoader = (column: FlareReadReceiptColumn, cursor?: string) => Promise<FlareReadReceiptMembers | null>;

/** FlareReadReceiptSheet's list props for the open list (the tab numbers stay the host's summary). */
export interface FlareReadReceiptSheetBinding {
  readers: FlareContact[];
  unread: FlareContact[];
  state: FlareReadReceiptState;
  readHasMore: boolean;
  unreadHasMore: boolean;
  loadingMore: FlareReadReceiptColumn | null;
  loadMoreFailed: FlareReadReceiptColumn | null;
}

export interface FlareReadReceiptList {
  /** The open list; null while `key` is empty. */
  pages: Readonly<ShallowRef<FlareReadReceiptPages | null>>;
  /** `v-bind` it on FlareReadReceiptSheet; null while closed. */
  sheet: ComputedRef<FlareReadReceiptSheetBinding | null>;
  /** The next page of `column` (the sheet's `loadMore`). Nothing happens unless the list is ready, the column has a next
   * page and is not reading it already; the other column pages on its own meanwhile. */
  loadMore(column: FlareReadReceiptColumn): Promise<void>;
  /** Read the list again from both first pages (the sheet's `retry`). */
  retry(): Promise<void>;
}

const EMPTY: FlareReadReceiptMembers = Object.freeze({ people: [] }) as FlareReadReceiptMembers;

const members = (page: FlareReadReceiptMembers): FlareReadReceiptMembers =>
  ({ people: page.people, ...(page.nextCursor ? { nextCursor: page.nextCursor } : {}) });

function settleLoading(pages: FlareReadReceiptPages, column: FlareReadReceiptColumn): FlareReadReceiptColumn | null {
  return pages.loadingMore === column ? null : pages.loadingMore;
}

/** `column`'s next page arrived: its people after the column's (someone listed already is kept once), its cursor. */
function appended(pages: FlareReadReceiptPages, column: FlareReadReceiptColumn, page: FlareReadReceiptMembers | null): FlareReadReceiptPages {
  const shown = pages[column];
  if (!page) return { ...pages, [column]: { people: shown.people }, loadingMore: settleLoading(pages, column) };
  const listed = new Set(shown.people.map((person) => person.id));
  const people = [...shown.people];
  for (const person of page.people) {
    if (listed.has(person.id)) continue;
    listed.add(person.id);
    people.push(person);
  }
  return { ...pages, [column]: { people, ...(page.nextCursor ? { nextCursor: page.nextCursor } : {}) }, loadingMore: settleLoading(pages, column) };
}

/**
 * The read list of the message `key` names (the kit's id for it, or any id the host opens the sheet with; empty: no
 * sheet). A new key reads both first pages again and drops whatever the previous one still had in flight.
 */
export function useFlareReadReceiptList(key: MaybeRefOrGetter<string | null | undefined>, page: FlareReadReceiptPageLoader): FlareReadReceiptList {
  const pages = shallowRef<FlareReadReceiptPages | null>(null);
  let generation = 0;
  /** Columns whose next page is being read: the sheet shows one busy column, but neither asks twice. */
  const reading = new Set<FlareReadReceiptColumn>();

  async function open(): Promise<void> {
    const mine = ++generation;
    reading.clear();
    pages.value = { state: "loading", read: EMPTY, unread: EMPTY, loadingMore: null, loadMoreFailed: null };
    let next: FlareReadReceiptPages;
    try {
      const [read, unread] = await Promise.all([page("read"), page("unread")]);
      next = read && unread
        ? { state: "ready", read: members(read), unread: members(unread), loadingMore: null, loadMoreFailed: null }
        : { state: "unavailable", read: EMPTY, unread: EMPTY, loadingMore: null, loadMoreFailed: null };
    } catch {
      next = { state: "error", read: EMPTY, unread: EMPTY, loadingMore: null, loadMoreFailed: null };
    }
    if (mine === generation) pages.value = next;
  }

  async function loadMore(column: FlareReadReceiptColumn): Promise<void> {
    const current = pages.value;
    const cursor = current?.state === "ready" ? current[column].nextCursor : undefined;
    if (!current || !cursor || reading.has(column)) return;
    const mine = generation;
    reading.add(column);
    pages.value = { ...current, loadingMore: column, loadMoreFailed: current.loadMoreFailed === column ? null : current.loadMoreFailed };
    let settle: (latest: FlareReadReceiptPages) => FlareReadReceiptPages;
    try {
      const next = await page(column, cursor);
      settle = (latest) => appended(latest, column, next);
    } catch {
      settle = (latest) => ({ ...latest, loadingMore: settleLoading(latest, column), loadMoreFailed: column });
    }
    if (mine !== generation) return;
    reading.delete(column);
    if (pages.value) pages.value = settle(pages.value);
  }

  watch(() => toValue(key) || null, (opened) => {
    if (opened) {
      void open();
      return;
    }
    generation++;
    reading.clear();
    pages.value = null;
  }, { immediate: true });

  const sheet = computed<FlareReadReceiptSheetBinding | null>(() => {
    const current = pages.value;
    if (!current) return null;
    return {
      readers: current.read.people,
      unread: current.unread.people,
      state: current.state,
      readHasMore: Boolean(current.read.nextCursor),
      unreadHasMore: Boolean(current.unread.nextCursor),
      loadingMore: current.loadingMore,
      loadMoreFailed: current.loadMoreFailed,
    };
  });

  return {
    pages,
    sheet,
    loadMore,
    retry: () => (pages.value ? open() : Promise.resolve()),
  };
}
