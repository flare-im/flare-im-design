<script setup lang="ts">
import { computed, getCurrentInstance, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import FlareSearchBar from './FlareSearchBar.vue';
import FlareFilterTabs, { type FlareFilterTabOption } from './FlareFilterTabs.vue';
import FlareActionMenu from './FlareActionMenu.vue';
import FlareGlyph from './FlareGlyph.vue';
import FlareSearchResults from './FlareSearchResults.vue';
import FlareStatusBanner from './FlareStatusBanner.vue';
import { sameSearchCriteria, sameSearchTimeRange, validSearchTimeRange, type FlareSearchRangeOption, type FlareSearchCriteria, type FlareSearchSnapshot, type FlareSearchTimeRange } from '../../shared/contracts/search-panel';
import type { FlareSearchResultItem, FlareSearchResultGroup } from '../../shared/contracts';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

/**
 * Search with filters: a search bar, ONE compact row of result types (plus a trailing time-range
 * capsule that opens a menu — anchored on desktop, a bottom sheet on a phone), and the
 * results. The host runs the search and reports it back through `snapshot`. Typing searches after a
 * short pause (never while an IME is composing); Enter, clearing, a type or a time range searches at
 * once. With nothing typed and the first type and no time range chosen the panel rests idle.
 *
 * `layout="page"` is the panel as a whole page (a phone's search screen, a search dialog): the field and
 * the type row do not scroll — only the results under their hairline do, and a new query's results
 * start at the top — and the panel owns the page gutter and the safe areas, with result rows running
 * edge to edge. Give it a height: a non-scrolling screen does; a FlareBottomSheet only caps its own, so
 * inside one wrap the panel in a box with a height, or a centred dialog re-centres — and the field jumps —
 * with every change in the number of results. A host that listens to `cancel` gets the search bar's own
 * way out beside the field (取消). The `idle` slot replaces the idle line and is handed `search(term)`,
 * which searches for a term at once and puts the caret back in the field, and `focusField()` for a slot
 * action that removes what was focused (clearing recent searches); put `v-if` on the `<template #idle>`
 * itself, because a slot that renders nothing still replaces the idle line.
 */
const props = withDefaults(defineProps<{
  snapshot: FlareSearchSnapshot;
  filters: Record<string, string>;
  searchText?: string;
  idleText?: string;
  timeRanges?: FlareSearchRangeOption[];
  timeRangeText?: string;
  /** Put the caret in the search field when the panel opens. */
  autofocus?: boolean;
  /** `inline` (default) sits inside a padded surface; `page` pins its head and owns the gutters. */
  layout?: "inline" | "page";
  /**
   * A type or a time range alone is not a search: the panel rests idle until something is typed. For a
   * search across kinds (联系人 / 群聊 / 聊天记录), where "every contact" is the contact list's job. Off
   * by default: inside a conversation "no words + 图片" lists every image, which is a search.
   */
  requireQuery?: boolean;
}>(), { timeRanges: () => [], autofocus: false, layout: "inline", requireQuery: false });
const { t } = useFlareI18n();
const strings = computed(() => ({
  searchText: props.searchText ?? t("searchPanel.search"),
  idleText: props.idleText ?? t("searchPanel.idle"),
  timeRangeText: props.timeRangeText ?? t("searchPanel.timeRange"),
  typeText: t("searchPanel.type"),
  searching: t("searchPanel.searching"),
}));
const emit = defineEmits<{ search: [criteria: FlareSearchCriteria]; open: [item: FlareSearchResultItem]; viewAll: [kind: FlareSearchResultGroup['kind']]; cancel: [] }>();
// Leaving search already has an owner: the bar draws its cancel key for a host that listens. The panel
// passes the listener through only when its own host listens, so a panel inside a page with a back
// button does not grow a second way out.
const instance = getCurrentInstance();
// Cancelling also drops the search this panel was about to send: a `search` must not arrive after the
// host was told the user left.
const barListeners = computed(() => (instance?.vnode.props?.onCancel ? { cancel: () => { cancelPending(); emit('cancel'); } } : {}));

const SEARCH_DELAY_MS = 300;

const filterOptions = computed<FlareFilterTabOption[]>(() => Object.entries(props.filters).map(([value, label]) => ({ value, label })));
const defaultFilter = computed(() => filterOptions.value[0]?.value ?? '');
const rangeOptions = computed(() => props.timeRanges.filter((option) => validSearchTimeRange(option)));
const rangeTabs = computed<FlareFilterTabOption[]>(() => rangeOptions.value.map((option) => ({ value: option.id, label: option.label })));
/**
 * 时间范围收进一颗尾随胶囊,不再自己占一整排。
 *
 * 它是**筛选的筛选** —— 比「类型」再低一级,却和类型一样铺了满满一排,两排加起来在手机上
 * 吃掉近百像素,结果要往下翻才看得到。收进菜单后:桌面锚定弹层、手机底部面板,
 * 这是 FlareActionMenu 本来就有的两种形态,不用另造。
 */
const rangeMenuOpen = ref(false);
const rangeMenuItems = computed(() => rangeOptions.value.map((option) => ({ id: option.id, label: option.label })));
/** 胶囊上写当前选中的那个范围;没选(或选了第一个「不限时间」)就写这一类的名字。 */
const rangeChipLabel = computed(() => {
  const active = rangeOptions.value.find((option) => option.id === activeRange.value);
  return !active || active.id === rangeOptions.value[0]?.id ? strings.value.timeRangeText : active.label;
});
const rangeNarrowed = computed(() => Boolean(activeRange.value) && activeRange.value !== rangeOptions.value[0]?.id);

const draft = ref(props.snapshot.criteria.query);
const filter = ref(props.snapshot.criteria.filterId);
const range = ref<FlareSearchTimeRange>({ fromTime: props.snapshot.criteria.fromTime, toTime: props.snapshot.criteria.toTime });
const submitted = ref<FlareSearchCriteria>({ ...props.snapshot.criteria });
const activeRange = computed(() => rangeOptions.value.find((option) => sameSearchTimeRange(range.value, option))?.id ?? '');

function isIdle(criteria: FlareSearchCriteria): boolean {
  if (criteria.query.trim()) return false;
  if (props.requireQuery) return true;
  return (!criteria.filterId || criteria.filterId === defaultFilter.value)
    && criteria.fromTime === undefined && criteria.toTime === undefined;
}
const idle = computed(() => isIdle(submitted.value));
const current = computed(() => sameSearchCriteria(submitted.value, props.snapshot.criteria));
const waiting = computed(() => !idle.value && (!current.value || props.snapshot.state === 'loading'));

// The last results stay on screen while the next query runs, so typing does not blank the list.
const shown = ref<{ groups: FlareSearchResultGroup[]; query: string } | null>(null);
const body = ref<HTMLElement | null>(null);
let shownFor: FlareSearchCriteria | null = null;
watch(() => props.snapshot, (snapshot) => {
  if (snapshot.state === 'success') {
    shown.value = { groups: snapshot.groups, query: snapshot.criteria.query };
    // Another query's results start at the top (the page layout scrolls its own body).
    if (!shownFor || !sameSearchCriteria(shownFor, snapshot.criteria)) void nextTick(() => { if (body.value) body.value.scrollTop = 0; });
    shownFor = { ...snapshot.criteria };
  }
  // A host that resets its search to idle (a closed sheet, a cancel) resets the panel with it — words
  // that were typed but never submitted and a type that was only chosen (`requireQuery`) included.
  const untouched = draft.value === snapshot.criteria.query && filter.value === snapshot.criteria.filterId
    && sameSearchTimeRange(range.value, snapshot.criteria);
  if (snapshot.state === 'idle' && isIdle(snapshot.criteria) && (!isIdle(submitted.value) || !untouched)) {
    cancelPending();
    draft.value = snapshot.criteria.query;
    filter.value = snapshot.criteria.filterId;
    range.value = {};
    submitted.value = { ...snapshot.criteria };
    shown.value = null;
  }
}, { immediate: true });

let timer: ReturnType<typeof setTimeout> | undefined;
const composing = ref(false);
function cancelPending(): void {
  if (timer !== undefined) clearTimeout(timer);
  timer = undefined;
}
onBeforeUnmount(cancelPending);

function submit(): void {
  cancelPending();
  const criteria: FlareSearchCriteria = { query: draft.value.trim(), filterId: filter.value, ...range.value };
  if (sameSearchCriteria(criteria, submitted.value) && !isIdle(criteria) && props.snapshot.state !== 'failure') return;
  submitted.value = criteria;
  if (isIdle(criteria)) {
    shown.value = null;
    return;
  }
  emit('search', { ...criteria });
}
function scheduleSubmit(): void {
  cancelPending();
  if (composing.value) return;
  // Nothing new to look for: the words are the ones already submitted (a recent search was picked, which
  // searched at once). Without this the pause would run `submit` again and silently retry a failure.
  if (draft.value.trim() === submitted.value.query && filter.value === submitted.value.filterId
    && sameSearchTimeRange(range.value, submitted.value)) return;
  timer = setTimeout(submit, SEARCH_DELAY_MS);
}
watch(draft, scheduleSubmit);
function onCompositionEnd(): void {
  composing.value = false;
  scheduleSubmit();
}
function chooseFilter(id: string): void {
  filter.value = id;
  submit();
}
function chooseRange(id: string): void {
  const option = rangeOptions.value.find((candidate) => candidate.id === id);
  if (!option) return;
  range.value = { fromTime: option.fromTime, toTime: option.toTime };
  submit();
}
function retry(): void {
  emit('search', { ...submitted.value });
}
const bar = ref<{ focus: () => void } | null>(null);
/** The caret back in the field: what a slot action calls when it removes the thing that had focus. */
function focusField(): void { bar.value?.focus(); }
/**
 * Search for `term` now, as if it had been typed and Return pressed (a recent search was picked). The
 * field takes focus before the idle slot is removed, so focus never falls to the document — where a
 * page's Escape handler would no longer hear the key.
 */
function searchNow(term: string): void {
  draft.value = term;
  submit();
  focusField();
}
/**
 * "查看更多 联系人" and the 联系人 type are the same move when a result kind is also a type id. The panel
 * owns the chosen type, so it makes the move itself; the host still hears `viewAll`.
 */
function onViewAll(kind: FlareSearchResultGroup['kind']): void {
  if (Object.prototype.hasOwnProperty.call(props.filters, kind) && filter.value !== kind) chooseFilter(kind);
  emit('viewAll', kind);
}
</script>
<template>
  <section class="flare-search-panel" :class="`flare-search-panel--${layout}`" @compositionstart="composing = true" @compositionend="onCompositionEnd">
    <div class="flare-search-panel__head">
      <FlareSearchBar
        ref="bar"
        v-model="draft"
        :placeholder="strings.searchText"
        :loading="waiting"
        :autofocus="autofocus"
        v-on="barListeners"
        @submit="submit"
        @clear="submit"
      />
      <!-- 一排:类型胶囊 + 尾随的时间范围。类型横向滚动、不换行;时间范围点开才展开。 -->
      <div v-if="filterOptions.length > 1 || rangeTabs.length" class="flare-search-panel__filters">
        <FlareFilterTabs
          v-if="filterOptions.length > 1"
          class="flare-search-panel__types"
          size="sm"
          :model-value="filter"
          :options="filterOptions"
          :aria-label="strings.typeText"
          @change="chooseFilter"
        />
        <FlareActionMenu
          v-if="rangeTabs.length"
          v-model:open="rangeMenuOpen"
          :items="rangeMenuItems"
          :label="strings.timeRangeText"
          @select="chooseRange"
        >
          <button
            type="button"
            class="flare-search-panel__range"
            :class="{ 'is-narrowed': rangeNarrowed }"
            :aria-label="strings.timeRangeText"
            :aria-expanded="rangeMenuOpen"
          >
            <span>{{ rangeChipLabel }}</span>
            <FlareGlyph icon="chevron-down" :size="14" />
          </button>
        </FlareActionMenu>
      </div>
    </div>
    <div ref="body" class="flare-search-panel__body">
      <template v-if="idle">
        <slot name="idle" :search="searchNow" :focus-field="focusField">
          <p class="flare-search-panel__status" role="status">{{ strings.idleText }}</p>
        </slot>
      </template>
      <FlareStatusBanner v-else-if="current && snapshot.state === 'failure'" class="flare-search-panel__banner" :text="snapshot.error || strings.idleText" tone="danger" :action-text="t('common.retry')" @action="retry" />
      <template v-else-if="shown">
        <FlareStatusBanner v-if="current && snapshot.state === 'success' && snapshot.warning" class="flare-search-panel__banner" :text="snapshot.warning" tone="warning" :action-text="t('common.retry')" @action="retry" />
        <div class="flare-search-panel__results" :aria-busy="waiting">
          <FlareSearchResults :groups="shown.groups" :query="shown.query" @open="emit('open', $event)" @view-all="onViewAll" />
        </div>
      </template>
      <p v-else class="flare-search-panel__status" role="status">{{ strings.searching }}</p>
    </div>
  </section>
</template>
<style scoped>
.flare-search-panel { min-width: 0; display: grid; align-content: start; gap: var(--flare-size-spacing-md); color: var(--flare-color-text-primary); }
/* Inline: the head and the body are not boxes of their own, so the field, the type row and the results
   stay the grid's children and keep one gap between them. */
.flare-search-panel__head,
.flare-search-panel__body { display: contents; }
/* Page: the panel is the screen — two rows, and only the second scrolls. The head needs no ground of
   its own (nothing passes under it) and sits over a hairline that divides the field from the results;
   the panel owns the page gutter and the insets, and the rows below take the same gutter through
   `--flare-search-gutter`, running edge to edge. */
.flare-search-panel--page {
  --flare-search-gutter: var(--flare-size-spacing-lg);
  grid-template-rows: auto minmax(0, 1fr);
  gap: 0;
  height: 100%;
  min-height: 0;
}
.flare-search-panel--page .flare-search-panel__head {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  padding: max(var(--flare-size-spacing-sm), env(safe-area-inset-top)) var(--flare-search-gutter) var(--flare-size-spacing-sm);
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-search-panel--page .flare-search-panel__body {
  display: block;
  min-height: 0;
  overflow-y: auto;
  overscroll-behavior: contain;
  padding-block: var(--flare-size-spacing-sm) max(var(--flare-size-spacing-sm), env(safe-area-inset-bottom));
}
.flare-search-panel--page .flare-search-panel__status { padding-inline: var(--flare-search-gutter); }
.flare-search-panel--page .flare-search-panel__banner { margin: 0 var(--flare-search-gutter) var(--flare-size-spacing-sm); }
/* 类型占满余下宽度并自己横滚;时间范围钉在行尾,不跟着滚走。 */
.flare-search-panel__filters { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-search-panel__types { flex: 1 1 auto; min-width: 0; }
.flare-search-panel__range {
  position: relative;
  display: inline-flex;
  flex: none;
  align-items: center;
  gap: 4px;
  min-height: 30px;
  padding: 0 var(--flare-size-spacing-sm);
  border: 1px solid transparent;
  border-radius: var(--flare-size-radius-full, 999px);
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm);
  font-weight: 500;
  white-space: nowrap;
  cursor: pointer;
}
/* 缩窄过范围时这颗胶囊要看得出「已生效」——否则收进菜单等于把状态藏了。 */
.flare-search-panel__range.is-narrowed {
  color: var(--flare-color-primary-text);
  border-color: color-mix(in srgb, var(--flare-color-primary) 26%, transparent);
  background: color-mix(in srgb, var(--flare-color-primary) 12%, transparent);
  font-weight: 600;
}
.flare-search-panel__range::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 100%;
  height: max(100%, var(--flare-size-layout-touch-target));
}
.flare-search-panel__range:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-search-panel__status { margin: 0; padding: var(--flare-size-spacing-lg) 0; color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-md); text-align: center; }
.flare-search-panel__results[aria-busy="true"] { opacity: 0.6; transition: opacity var(--flare-transition-fast); }
@media (prefers-reduced-motion: reduce) { .flare-search-panel__results[aria-busy="true"] { transition: none; } }
</style>
