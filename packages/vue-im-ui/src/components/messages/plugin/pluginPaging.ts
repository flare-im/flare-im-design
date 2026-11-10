import { computed, ref, watch, type ComputedRef } from "vue";
import { flarePluginNextCursor, type FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";

/**
 * Load more for a resolved plugin view (spec rules.detail, rules.pagePaging): the view's nextCursor offers the next
 * page; one cursor is asked for once, and asking again is allowed when the host is done (loadingMore true → false),
 * settles, reports a failure or, on a page, finishes a refresh (which may bring the same cursor back). Shared by
 * PluginDetailSheet and PluginPage.
 */
export function usePluginPaging(source: {
  view: () => FlarePluginViewModel | undefined;
  loadingMore: () => boolean;
  settleToken: () => number;
  actionError: () => string | undefined;
  /** Read/pagination failures are distinct from financial action errors. */
  pageError?: () => string | undefined;
  /** Explicit read-side completion, even when repeated failures have identical text. */
  pagingToken?: () => number;
  /** A page's refresh: its end forgets the asked cursor. */
  refreshing?: () => boolean;
  request: (cursor: string) => void;
}): { nextCursor: ComputedRef<string | undefined>; pageBusy: ComputedRef<boolean>; loadMore: () => void } {
  const nextCursor = computed(() => flarePluginNextCursor(source.view()));
  const asked = ref<string | null>(null);
  const pageBusy = computed(() => source.loadingMore() || Boolean(source.refreshing?.()) || (asked.value !== null && asked.value === nextCursor.value));
  function loadMore(): void {
    const cursor = nextCursor.value;
    if (!cursor || pageBusy.value) return;
    asked.value = cursor;
    source.request(cursor);
  }
  watch(source.loadingMore, (now, before) => { if (before && !now) asked.value = null; });
  watch(source.settleToken, (now, before) => { if (now !== before) asked.value = null; });
  watch(source.actionError, (now, before) => { if (now && now !== before) asked.value = null; });
  if (source.pageError) watch(source.pageError, (now, before) => { if (now && now !== before) asked.value = null; });
  if (source.pagingToken) watch(source.pagingToken, (now, before) => { if (now !== before) asked.value = null; });
  if (source.refreshing) watch(source.refreshing, (now, before) => { if (before && !now) asked.value = null; });
  return { nextCursor, pageBusy, loadMore };
}
