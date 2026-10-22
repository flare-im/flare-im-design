import { computed, ref, watch, type ComputedRef } from "vue";
import { flarePluginNextCursor, type FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";

/**
 * Load more for a resolved plugin view (spec rules.detail): the view's nextCursor offers the next page; one cursor is
 * asked for once, and asking again is allowed when the host is done (loadingMore true → false), settles, or reports a
 * failure. Shared by PluginDetailSheet and PluginPage.
 */
export function usePluginPaging(source: {
  view: () => FlarePluginViewModel | undefined;
  loadingMore: () => boolean;
  settleToken: () => number;
  actionError: () => string | undefined;
  request: (cursor: string) => void;
}): { nextCursor: ComputedRef<string | undefined>; pageBusy: ComputedRef<boolean>; loadMore: () => void } {
  const nextCursor = computed(() => flarePluginNextCursor(source.view()));
  const asked = ref<string | null>(null);
  const pageBusy = computed(() => source.loadingMore() || (asked.value !== null && asked.value === nextCursor.value));
  function loadMore(): void {
    const cursor = nextCursor.value;
    if (!cursor || pageBusy.value) return;
    asked.value = cursor;
    source.request(cursor);
  }
  watch(source.loadingMore, (now, before) => { if (before && !now) asked.value = null; });
  watch(source.settleToken, (now, before) => { if (now !== before) asked.value = null; });
  watch(source.actionError, (now, before) => { if (now && now !== before) asked.value = null; });
  return { nextCursor, pageBusy, loadMore };
}
